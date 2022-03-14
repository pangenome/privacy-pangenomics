#lang racket
(require math/base)
(require racket/format)
(require pmap)
(require racket/random)
(require "gbwtgraph")
(require describe)


; (require axe/threading)

(define (extend-states graph states nodes)
 (map  (λ (x y) (GRAPH-extend y)) states nodes))


(define (make-utility ε Δu)
  (λ (freq)
    (exp (/ (* ε (log (+ 1 (* freq  freq)))) (* 2  Δu)))))
(define
 (positive? x)
 (> x 0))

(define gfa-path "splitted")

(define (stream-gfas p)
  (stream-map (λ (x) (gfa-to-gbwtgraph (path->string (path->complete-path x)))) (directory-list  #:build? #t  p)))

(define (node->search-state graph  x)
  (GRAPH-get-state graph (GRAPH-node-to-handle x)))

(define sample1 (gfa-to-gbwtgraph   "splitted/chro20node_list30.gfa"))

(define sample2 (gfa-to-gbwtgraph  "splitted/chro20node_list83.gfa"))

(define yeast-genome  (gfa-to-gbwtgraph "cerevisiae.pan.fa.0b30003.2ff309f.0967224.smooth.gfa"))

(define gfa-stream (stream-gfas gfa-path))

(define (first-node-handle gbwtgraph)
  (let ([first-node (GRAPH-min-node-id gbwtgraph)])
     (GRAPH-node-to-handle first-node)))


(define (initialize-searchState gbwtgraph)
   (let ([first-handle (first-node-handle gbwtgraph)])
    (GRAPH-get-state gbwtgraph first-handle)))

(define the-graph (stream-ref gfa-stream 0))

(define (node-range graph)
     (range (GRAPH-min-node-id graph) (GRAPH-max-node-id graph)))

(define (find-max-frequency all-ranges)
 (foldl
   (λ (c x)
      (if (> (SearchState-size x) (SearchState-size c)) x c))
   (first all-ranges) (rest all-ranges)))




#(define (sample-graph graph depth #:epsilon [ε  0.1])
    (define  node-list (match lst ['() (node-range graph)] [_ lst]))
    (define max-frequency (graph-max-frequency graph #:node-list node-list))
    (define Δu   (log (/ max-frequency (+ 1 max-frequency))))
    (define utility-function (make-utility  ε Δu))
    (define initial-states (map  (λ (x) (GRAPH-get-state graph (GRAPH-node-to-handle x))) node-list))
    (let loop ([counter 0]
               [states initial-states])
           (displayln  (~a "loop number: " counter))
           (if (not  (<  counter depth))
               (loop (+  counter 1)   (pmapf  (λ (x y) (GRAPH-extend graph x y)) states node-list))
               states)))








; (define (sample-graph graph depth #:epsilon [ε  0.1] #:node-list [lst null])
;    (define  node-list (match lst ['() (node-range graph)] [_ lst]))
;    (define max-frequency (graph-max-frequency graph #:node-list node-list))
;    (displayln 'here2)
;    (define Δu   (log (/ max-frequency (+ 1 max-frequency))))
;    (define utility-function (make-utility  ε Δu))
;    (define initial-states (map  (λ (x) (GRAPH-get-state graph (GRAPH-node-to-handle x))) node-list))
;    (let loop ([counter 0]
;               [states initial-states])
;           (displayln  (~a "loop number: " counter))
;           (if (not  (<  counter depth))
;               (loop (+  counter 1)   (pmapf  (λ (x y) (GRAPH-extend graph x y)) states node-list))
;               states)))





; #_(define state (GRAPH-get-state graph (GRAPH-node-to-handle node)))
; (describe sample-distribution )

(define states_ '())



'(define rnd-node (random-ref  (node-range yeast-genome)))
; (displayln rnd-node)
(define rnd-node │70369)
(define random-initial-state (node->search-state yeast-genome rnd-node))

;  (describe random-initial-state))
'(SearchState-size random-initial-state)
(define pipa (λ (x) x))


(define extended-states  (GRAPH-extend-to-valid-states yeast-genome random-initial-state))

(length extended-states)
(define pipa  (car extended-states))
'(SearchState-size pipa)

'(SearchState-size (convert-void   (car extended-states)))
'(map (λ (x ) (   SearchState-size (convert-void x)))

      extended-states)
'(SearchState-size (convert-void (car extended-states)))
 ;


'(define edges (GRAPH-collect-succesive-nodes yeast-genome rnd-node))

'(describe edges)
(define return null)

(describe return)


(define (do-loop-sample)
 (time
  (let loop ([node  random-initial-state]
             [all (list random-initial-state)]
             [counter 25])
   (with-handlers
     ([exn:fail? (λ (exp)
                    (displayln "terminated early")
                    (set! return all)
                    all)])
    (let ([x (car  (sample-single-state yeast-genome node))])
     (if (= 1 counter)
       all
      (loop x (cons x all) (- counter 1))))))))



(define (graph-max-frequency graph #:node-list [node-list '()])
    (if (not (empty? node-list))
     (SearchState-size (find-max-frequency (pmapf  (λ (x) (GRAPH-get-state graph (GRAPH-node-to-handle x))) node-list)))
     (SearchState-size (find-max-frequency (pmapf  (λ (x) (GRAPH-get-state graph (GRAPH-node-to-handle x))) (node-range graph))))))


(define (sample-single-state graph #:epsilon [ε  0.1] state)
  (define  state-list (map (λ (x)  convert-void x) (GRAPH-extend-to-valid-states yeast-genome state)))
  (define max-frequency (SearchState-size  (find-max-frequency state-list)))
  (define Δu  (log (/ max-frequency (+ 1 max-frequency))))
  (define utility (make-utility  ε Δu))
  (define calculated-utilities (map (λ (x) (utility  (SearchState-size x))) state-list))
  (sample-distribution calculated-utilities extended-to-all-states 1))




;vector<SearchState> extend_to_valid_states (SearchState state){}

;(define pipa (do-loop-sample))

;(describe pipa)
; (describe  (car the-sample))
;
; (define test-a
;   (thunk
;     (thread
;       (thunk
;         (time
;           (displayln "starting samplng")
;           (set! the-sample))))))
;
;
;

; '(sample-distribution (list  .1 .2 .3 .3 .3 .8) (list 1 212 22 3 3 44) 1)
; (define random-states  (build-list 5 (λ (_) (node->search-state sample2  (random-ref  (node-range sample2))))))
;
; (define sampled  (car (sample-distribution (list  .1 .2 .3 .3  .8) random-states 1)))
;
; (SearchState-size sampled)
;
; (describe (cons 3  3))

; (describe  (car  (sample-distribution '( 1 2 3 4 8) '( 1 2000 333 "?" fdsf) 3)))

; (define the-sample (sample-single-state yeast-genome random-initial-state))


; '(define (sample-single-state graph #:epsilon [ε  0.1] state)
;    (define  node-list (node-range graph))
;    (define extended-to-all-states (pmapf  (λ (y) (GRAPH-extend graph state y)) node-list))
;    (define max-frequency (SearchState-size  (find-max-frequency extended-to-all-states)))
;    (define Δu   (log (/ max-frequency (+ 1 max-frequency))))
;    (define utility (make-utility  ε Δu))
;    (define calculated-utilities (pmapf (λ (x) (utility  (SearchState-size x))) extended-to-all-states))
;    (displayln "level 6")
;    (sample-distribution calculated-utilities extended-to-all-states 1))
