#lang racket

(require describe)
(require "gbwtgraph")
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

; (define new-state  (GRAPH-extend graph-1  state-1 (+ a-number 1)))
; (SearchState-get-range state-1)
(SearchState-get-range state-1)

; (define (extend-to-all-states graph)
;   (letrec
;    ([max-node    (+ 1 (GRAPH-max-node-id graph))]
;     [min-node    (GRAPH-min-node-id graph)]
;     [initial-state (GRAPH-get-state graph min-node)])
;    (stream-map (λ (x) (GRAPH-extend graph initial-state x))  (in-range min-node (+ 1  max-node)))))
;
(define (extend-to-all-states graph initial-state)
  (letrec
   ([max-node    (+ 1 (GRAPH-max-node-id graph))]
    [min-node    (GRAPH-min-node-id graph)])
   (stream-map (λ (x) (GRAPH-extend graph initial-state x))  (in-range min-node (+ 1  max-node)))))


(define all-ranges (stream->list (extend-to-all-states graph-1 (GRAPH-get-state graph-1 1))))


(define partitioned  (group-by (λ (x) (cdr  (SearchState-get-range x))) all-ranges))

; (for ([ i (in-range (length   partitioned))])
;   (displayln (length (list-ref partitioned i))))
;
; (length (list-ref partitioned 1))

(define step1 (stream->list    (extend-to-all-states graph-1 (list-ref (list-ref partitioned 1) 1))))

; (length step1)

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

(define (find-max-frequency-state all-ranges)
 (stream-fold
   (λ (c x)
      (if (> (cdr  (SearchState-get-range x))
             (cdr  (SearchState-get-range c))) x c))
   (car  all-ranges) (cdr all-ranges)))


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
