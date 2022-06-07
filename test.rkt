#lang racket
(require math/base)
(require racket/format)
(require pmap)
(require racket/random)
(require "gbwtgraph")
(require describe)
(require racket/system)

(require date)


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



(define states_ '())

(define rnd-node  70369)

(define random-initial-state (node->search-state yeast-genome rnd-node))


(define (rnd-state genome)
  (node->search-state genome (random-ref  (node-range genome))))

(define return null)

(describe return)

(define (sample-initial-node graph #:epsilon [ε  0.1])
  (define  state-list  (map (λ (x)  (node->search-state graph x)) (node-range graph)))
  (define max-frequency (SearchState-size  (find-max-frequency state-list)))
  (define Δu  (log (/ max-frequency (+ 1 max-frequency))))
  (define utility (make-utility  ε Δu))
  (define calculated-utilities (map (λ (x) (utility  (SearchState-size x))) state-list))
  (convert-void (car (sample-distribution calculated-utilities state-list 1))))


(define initial-state (sample-initial-node yeast-genome))


(define (sample-single-state graph #:epsilon [ε  0.1] state)
  (define  state-list (map (λ (x)  (convert-void x)) (GRAPH-extend-to-valid-states graph state)))
  (define max-frequency (SearchState-size  (find-max-frequency state-list)))
  (define Δu  (log (/ max-frequency (+ 1 max-frequency))))
  (define utility (make-utility  ε Δu))
  (define calculated-utilities (map (λ (x) (utility  (SearchState-size x))) state-list))
  (convert-void (car   (sample-distribution calculated-utilities state-list 1))))


(define (do-loop-sample graph initial-state #:depth [ depth 100])
 (time
  (let loop ([state initial-state]
             [all (list initial-state)]
             [counter depth])
   (displayln "sampling")
   (with-handlers
     ([exn:fail? (λ (exp)
                    (displayln "terminated early")
                    (set! return all)
                    all)])
    (let ([x (car  (sample-single-state graph state))])
     (if (= 1 counter)
       all
      (loop x (cons x all) (- counter 1))))))))

; (string->path "path")

(define (save-node-list state-list output-file)
 (with-output-to-file (string->path   output-file)
    (lambda ()
      (for ([state (in-list state-list)])
        (let ([node (SearchState-node state)])
         (printf node))))))


;(define pouts (do-loop-sample yeast-genome random-initial-state))
;(define pipa (do-loop-sample yeast-genome (sample-initial-node yeast-genome)))

(define produce-output
  (λ (graph)
    (letrec ([initial-state (sample-initial-node graph)]
             [state-list (pmapf  (λ (_)  (do-loop-sample graph (sample-initial-node graph))) (range 1 10))])
      (define-values (sp out in err)
        (subprocess #f #f #f "/usr/bin/date" "+%m-%B-%Y-%T"))
      (define the-file    (~a "node_list_" (string-trim (port->string out)) ".txt"))
      #'(save-node-list state-list  the-file))))

(define nodes  (void))

(thread
  (thunk (set!  nodes (produce-output yeast-genome))))



'(SearchState-node ( pointer-to-searchstate  (car  (car pip))))

