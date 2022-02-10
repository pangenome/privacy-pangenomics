#lang axe

(require math/distributions)
(require "gbwtgraph")
(require describe)

; (describe gfa-to-gbwtgraph)

(define graph-1 (gfa-to-gbwtgraph  "cerevisiae.pan.fa.0b30003.2ff309f.0967224.smooth.gfa"))

(define graph-2 (gfa-to-gbwtgraph "example_gfa1.gfa"))

(define graph-3 (gfa-to-gbwtgraph "example.gfa"))

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



(define (find-max-frequency-state all-ranges)
 (foldl
   (λ (c x)
      (if (> (cdr  (SearchState-get-range x))
             (cdr  (SearchState-get-range c))) x c))
   (car all-ranges) (cdr all-ranges)))


(define all-ranges    (extend-to-all-states graph-1 (GRAPH-get-state graph-1 1)))

; (define max-frequency-range  (find-max-frequency-state all-ranges))
;
; (SearchState-get-range max-frequency-range)
; (SearchState-node-get  max-frequency-range)
; (define all-ranges-next  (stream->list   (extend-to-all-states graph-1 (GRAPH-get-state graph-1 559238))))
;
; (define max-frequency-range-next (find-max-frequency-state (stream->list  all-ranges-next)))
;
;
; (SearchState-get-range max-frequency-range-next)
; (SearchState-node-get  max-frequency-range-next)
;
;
; (define all-ranges-next-next  (stream->list   (extend-to-all-states graph-1 (GRAPH-get-state graph-1 (SearchState-node-get  max-frequency-range-next)))))
;
; (define max-frequency-range-next-next (find-max-frequency-state (stream->list  all-ranges-next-next)))
;
; (SearchState-node-get max-frequency-range-next-next)
;
; (SearchState-get-range max-frequency-range-next-next)
;


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
   (group-by (λ (x) (cdr  (SearchState-get-range x))) ranges))

(define group1 (group-ranges all-ranges))

(define group-of-interest (third group1))

(define state-2 (car group-of-interest))

(define node1 (SearchState-node-get   (car group-of-interest)))

(describe node1)

(define states ( extend-to-all-states graph-1 (car group-of-interest)))

(define group2 (group-ranges state-2))

(define state3 (car (car group2)))
(define next-node  (SearchState-node-get   state3))

(define states1 (extend-to-all-states graph-1 state3))


(define group3 (group-ranges states1))


#'(map  (λ(x) (SearchState-node-get x))   re-group)

; (map car (map  (λ(x)(map SearchState-get-range x))   group1))


; (define test-1 (follow-maximum-path graph-1 6))

;(SearchState-get-range max-frequency-range)
; (describe max-frequency-range)
; (define partitioned  (group-by (λ (x) (cdr  (SearchState-get-range x))) all-ranges))
; (define step1 (stream->list    (extend-to-all-states graph-1 (list-ref (list-ref partitioned 1) 1))))
; (define group2  (group-by (λ (x) (cdr  (SearchState-get-range x))) step1))
;

; (SearchState-get-range (car   (car (cdr group2))))
; (map SearchState-node-get  (car group2))
; (SearchState-get-range (car  step1))
; (d(stream->list  step1))
;(map SearchState-get-range  step1)
; (describe stream-ref)


; (define extensions  (map (λ (x) (GRAPH-extend graph-1 x)) (list-ref partitioned 1)))
 ; extend-to-all-states (list-ref partitioned 1))

; (define step-2 (map (λ (x) (extend-to-all-states graph-1 x)) partitioned))

; (stream->list  (list-ref step-2 1))

; (thread
;   (λ ()
;      (set! partitioned  (group-by (λ (x) (cdr  (SearchState-get-range x))) all-ranges))))


; (find-max-frequency-state )


; (define    (get-states-and-frequencies graph-1))


; (define (partition-by-frequency ranges)
;   (let loop ([acc (list)] [rst ranges] [n 1])
;     (if (empty? ranges)
;       acc
;      (let-values
;              ([(p r) (partition (λ (x) (= n (cdr  (SearchState-get-range x)))) ranges)])
;              (loop (append p acc) r (+ 1 n))))))
;

; (thread
;   (λ()
;    (set! partitioned (partition-by-frequency  (stream->list  all-ranges)))))
;


; (length partitioned)
; (empty? '())
;
; (append '(32) '(554))
; (define max-state (stream->list  (find-max-node-state all-ranges)))

;(stream-ref all-ranges 2)

; (describe stream-map)
; (stream-ref  (in-range 2 44) 41)
; (SearchState-get-range state-1)

; (define state-1  (SearchState-get-range initial-state))
