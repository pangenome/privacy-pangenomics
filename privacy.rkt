
#lang racket

(require describe)
(require "gbwtgraph")



(define gbwt (gfa-to-gbwt "cerevisiae.pan.fa.0b30003.2ff309f.0967224.smooth.gfa"))
