#lang racket

(require "gbwt-api.rkt")
(require ffi/unsafe)

(require threading)

(require describe)

(define (get-GFAS)
 (let ([fs  (directory-list  (current-directory))])
  (map (λ(x) (string->bytes/utf-8 (path->string x)))
   (filter (λ (x)
             (let ([the-file (path-get-extension (path->string x))])
               (if (not the-file)
                   #f
                   (bytes=? #".gfa" the-file)))) fs))))

(define GFAs (get-GFAS))




(define search-state (malloc 'atomic (call-method 'SEARCHSTATE-sizeof)))

(define search-state-1 (malloc 'atomic (call-method 'SEARCHSTATE-sizeof)))

(define (first-node  gbwt)
  (call-method 'GBWT-first-node  gbwt))




(define (next-node  gbwt node offset)
  (call-method 'GBWT-LF-next-node-from-offset gbwt node offset))



(define (next-offset gbwt from offset to)
  (call-method 'GBWT-LF-next-offset-from-node gbwt from offset to))


(define (find-next gbwt from offset to)
  (call-method 'GBWT-LF-next-offset-from-node gbwt from offset to))

;tests



(define (gfa->gbwt str)
  (with-handlers
    ([(λ (ex) (eq? 'io-error ex )) (λ (_) (displayln "Input output error"))])
    (define opened-gbwt (~>> str (call-method 'GBWTGRAPH-gfa-to-gbwt  ) get-gbwt))
    (unless opened-gbwt (raise  'io-error))
    opened-gbwt))




(define gfa-file (  list-ref GFAs 4))
(display  (format "reading gfa file from disk : ~a\n" gfa-file))
(define gbwt-object (gfa->gbwt gfa-file))

(display   "GBWT object successfuly parsed from file ")


(display  (format  "Trying to access first node \n Node:  ~a\n" (first-node gbwt-object)))



; (display (call-method 'SEARCHSTATE-node  search-state))


(display  (format  "Performing search for node ~a" 3))

(call-method 'GBWT-find gbwt-object search-state 3)

(display (format "Accessing node from search state: \n Node: ~a" (call-method 'SEARCHSTATE-node  search-state)))

(display (format "extend state to node ~a" 4))

(define extended (call-method 'GBWT-SEARCHSTATE-extend gbwt-object search-state-1  search-state 4))

(display (format "Accessing node from extended search state \n Node: ~a" (call-method 'SEARCHSTATE-node  search-state-1)))


(display (call-method 'GBWT-locate gbwt-object 3 0))






;
;
;
;
; (define (next-node  gbwt node offset)
;   (call-method 'GBWT-LF-next-node-from-offset gbwt node offset))
;
;
;
; (define (next-offset gbwt from offset to)
;   (call-method 'GBWT-LF-next-offset-from-node gbwt from offset to))
;
;
; (define (find-next gbwt from offset to)
;   (call-method 'GBWT-LF-next-offset-from-node gbwt from offset to))
;
; ;tests
;
;
;
; (define (gfa->gbwt str)
;   (with-handlers
;     ([(λ (ex) (eq? 'io-error ex )) (λ (_) (displayln "Input output error"))])
;     (define opened-gbwt (~>> str (call-method 'GBWTGRAPH-gfa-to-gbwt  ) get-gbwt))
;     (unless opened-gbwt (raise  'io-error))
;     opened-gbwt))
;
;
;
;
; (define gfa-file (  list-ref GFAs 4))
; (display  (format "reading gfa file from disk : ~a\n" gfa-file))
; (define gbwt-object (gfa->gbwt gfa-file))
;
; (display   "GBWT object successfuly parsed from file ")
;
;
; (display  (format  "Trying to access first node: ~a" (first-node gbwt-object)))
; (display "First node accessed! ")
;
; (display (call-method 'SEARCHSTATE-node  search-state))
;
;
; (display  (format  "Trying to search for nodes ~a" (call-method 'GBWT-find gbwt-object search-state 2)))
; (display "Done")
;
; (display (format "Accessing node from search state ~a" (call-method 'SEARCHSTATE-node  search-state-1)))
;
; (display  (format  "extending search state" (call-method 'GBWT-find gbwt-object search-state 2)))
;
; (define extended (call-method 'GBWT-SEARCHSTATE-extend gbwt-object search-state-1  search-state 3))
;
; (display "Done")
;
; (display "Locating node 3 from the extended state")
;
;
;
;
; (display (call-method 'GBWT-locate gbwt-object 3 4))
;
;
;
;
;
