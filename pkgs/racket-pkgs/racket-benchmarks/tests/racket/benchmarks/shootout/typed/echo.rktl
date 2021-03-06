(require racket/tcp)

(define PORT (+ 8888 (if OPTIMIZED? 1 0)))
(define DATA "Hello there sailor\n")
(: n Integer)
(define n 10)

(: server ( -> Void))
(define (server)
  (thread client)
  (let-values ([(in out) (tcp-accept (tcp-listen PORT 5 #t))]
               [(buffer) (make-string (string-length DATA))])
    (file-stream-buffer-mode out 'none)
    (let: loop : Void ([i : (U Integer EOF) (read-string! buffer in)]
                       [bytes : Integer 0])
      (if (not (eof-object? i))
          (begin
            (display buffer out)
            (loop (read-string! buffer in)
                  (+ bytes (string-length buffer))))
          (begin
            (display "server processed ")
            (display bytes)
            (display " bytes\n"))))))

(: client ( -> (U Void 'error)))
(define (client)
  (let-values ([(in out) (tcp-connect "127.0.0.1" PORT)]
               [(buffer) (make-string (string-length DATA))])
    (file-stream-buffer-mode out 'none)
    (let: loop : (U Void 'error) ([n : Integer n])
      (if (> n 0)
          (begin
            (display DATA out)
            (let ([i (read-string! buffer in)])
              (begin
                (if (equal? DATA buffer)
                    (loop (- n 1))
                    'error))))
          (close-output-port out)))))

(: main ((Vectorof String) -> Void))
(define (main args)
  (set! n
        (if (= (vector-length args) 0)
            1
            (assert (string->number (vector-ref args 0)) exact-positive-integer?)))
  (server))

(main (current-command-line-arguments))
