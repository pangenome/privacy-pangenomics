#lang racket

(require math/base)
(require racket/random)
(require "gbwtgraph")
(require describe)



(define (random-node gbwt)
  (let
    ([max-node    (+ 1 (GRAPH-max-node-id gbwt))]
     [min-node    (GRAPH-min-node-id gbwt)])
    (random min-node max-node)))



; (define (find-max-frequency-state all-states)
;  (foldl
;    (λ (c x)
;       (if (> (SearchState-size x) (SearchState-size c)) x c))
;    (first all-ranges) (rest all-states)))
