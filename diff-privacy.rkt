#lang racket
; (require math/distributions)
(require math/base)
(require "gbwtgraph")

(require describe)


(define graph-1 (gfa-to-gbwtgraph  "cerevisiae.pan.fa.0b30003.2ff309f.0967224.smooth.gfa"))


(define vector_test (GRAPH-get-all-handles graph-1))


(define (first-node-handle gbwtgraph)
  (let ([first-node (GRAPH-min-node-id gbwtgraph)])
     (GRAPH-node-to-handle first-node)))

(define (initialize-searchState gbwtgraph)
   (let ([first-handle (first-node-handle gbwtgraph)])
    (GRAPH-get-state gbwtgraph first-handle)))


(define (random-node gbwt)
  (let
    ([max-node    (+ 1 (GRAPH-max-node-id gbwt))]
     [min-node    (GRAPH-min-node-id gbwt)])
    (random min-node max-node)))


(define  (random-handle gbwt)
  (let ([rnode (random-node gbwt)])
    (GRAPH-node-to-handle rnode)))


(define a-number (quotient (GRAPH-max-node-id  graph-1) 10))

(define state-1 (GRAPH-get-state graph-1 1))

(define (extend-to-all-states graph initial-state)
  (letrec
   ([max-node    (+ 1 (GRAPH-max-node-id graph))]
    [min-node    (+ 1  (SearchState-node-get initial-state))])
   (map (λ (x) (GRAPH-extend graph initial-state x)) (stream->list    (in-range min-node (+ 1  max-node))))))


(define (find-max-frequency-state ranges)
 (foldl
   (λ (c x)
      (if (> (SearchState-size x)
             (SearchState-size c)) x c))
   (car all-ranges) (cdr ranges)))

(define (find-min-frequency-state all-ranges)
 (foldl
   (λ (c x)
      (if (< (SearchState-size x)
             (SearchState-size c)) x c))
   (car all-ranges) (cdr all-ranges)))

(define all-ranges    (extend-to-all-states graph-1 (GRAPH-get-state graph-1 1)))



(define (follow-maximum-path graph steps)
  (define initial-node (GRAPH-min-node-id graph))
  (let loop ([n steps] [node-id initial-node] [collected-nodes initial-node])
     (if (equal? n 0)
       collected-nodes
       (letrec ([all-ranges     (extend-to-all-states graph (GRAPH-get-state graph node-id))]
                [max-frequency-state (find-max-frequency-state all-ranges)]
                [new-node (SearchState-node-get max-frequency-state)])
          (loop (- n 1) new-node (cons new-node collected-nodes))))))

(define (group-ranges ranges)
   (group-by (λ (x) (SearchState-size x)) ranges))

(define grouped  (group-ranges  all-ranges))

(define  (sample-list lst)
  (list-ref lst (random   (length lst))))

'(define (utility db rn) 
   (define highest-frequency  (find-max-frequency-state db))
   (define frequency (SearchState-size rn))
   (/ 1 (expt  (- highest-frequency frequency) 2)))



; (not (member 3 '( 3 't4ll  3)))
; (when   (displayln "fdsa"))
; (define (sampling graph  ε state)
;      (define extended-states  (extend-to-all-states graph state))
;      (define sorted-frequencies (sort extended-states < #:key  SearchState-size))
;      (define random-sampler (λ () (sample-list sorted-frequencies)))
;      (define  α
;        (with-handlers ([exn:fail:contract:divide-by-zero? (λ(_) (displayln "Divided by zero"))]
;                        [exn:fail? (λ (_) (displayln "error"))])
;                       (/  ε)))
;      (define exp-mechanism-distribution
;        (λ (x)
;           (with-handlers ([exn:fail? (λ(y) (displayln y))])
;             (exp (* α x)))))
;      (let loop ([random-Y (random-sampler)] [random-X (random-sampler)])
;        (if (<= (exp-mechanism-distribution (SearchState-size random-X))
;                (SearchState-size  random-Y))
;          random-X
;          (loop (sample-list sorted-frequencies)
;                (sample-list sorted-frequencies)))))
;
; (define first-state (initialize-searchState graph-1))
;
; (define (exhaust-sampling graph ε state)
;   (define max-node (GRAPH-max-node-id graph))
;   (let loop ([current-state state] [samples '() ] [counter 1])
;
;    (define  next-state (sampling graph ε current-state))
;    (if (<  (SearchState-node-get next-state) max-node)
;     (loop next-state (cons next-state samples) (+ 1 counter))
;     samples)))
;
; (define exponential-samples (void))
;
;
;
; (thread (λ () (set! exponential-samples   (exhaust-sampling    graph-1 0.1 first-state))))
;
; #'(define sampler (make-exponential-sampling  graph-1 0.1))
;
; #'(sort fi< #:key  SearchState-size)
;
; #'(define sample  (sampling graph-1 0.1 first-state))
;
; ; (map SearchState-size all-ranges)
