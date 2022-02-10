#lang axe
(require axe/threading)
(require math/base)
(require "gbwtgraph")
(require describe)


(define (first-node-handle gbwtgraph)
  (let ([first-node (GRAPH-min-node-id gbwtgraph)])
     (GRAPH-node-to-handle first-node)))


(define (initialize-searchState gbwtgraph)
   (let ([first-handle (first-node-handle gbwtgraph)])
    (GRAPH-get-state gbwtgraph first-handle)))


(define gfa-path "splitted")



(define (stream-gfas p)
 (let ([lst    (map #λ(~> % path->complete-path path->string) (directory-list  #:build? #t  p))])
   (map (λ (x) (gfa-to-gbwtgraph x)) lst)))

(first (stream-gfas gfa-path))


(define (populate-utilities bgwt)
   (let ([initial-node  1])))


; (define utility x h
;   (for ))
;   ;
  ; (/ (log (+ 1 (hash-ref r 'frequency)))
  ;    (+ 1 (expt  (- ()
  ;                   frequency) 2))))
  ;


'(define utility-function x r
   (let ([frequency (SearchState-size (fst  r))])))
; (define (utility-function x r)
;   (let ([haplotype-frequency (SearchState-size (fst  r))]
;         [frequency (snd r)])
;    (/ (log (+ 1 haplotype-frequency))
;       (+ 1  (expt  (- haplotype-frequency frequency) 2)))))



