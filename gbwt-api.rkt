#lang racket

(require ffi/unsafe)
(require setup/dirs)
(require memo)


(provide call-method)

(provide GBWTSequenceSourcePair-gbwt-ref)

(provide get-gbwt)

(define-cstruct _CStringArray ([data _pointer]
                               [size _int]))

(define-cstruct _CPair ([first _uint64]
                        [second _uint64]))

(define-cstruct _GBWTSequenceSourcePair ([gbwt-ref _pointer]
                                         [sequence-source-ref _pointer]))



(define get-gbwt  GBWTSequenceSourcePair-gbwt-ref)

(define (locate-library-path str)
  (let ([paths (map string->path
                  (map (λ (x)
                         (if (string-suffix? x "/")
                           (format "~a~a" x str)
                           (format "~a/~a" x str)))
                       (string-split (getenv "LD_LIBRARY_PATH") ":")))])
    (ormap (λ (x) (if (file-exists? x) x #f) ) paths)))

(define libgbwtwrapper (ffi-lib (locate-library-path  "libgbwtwrapper.so")))

; (define libgfawrapper (ffi-lib (locate-library-path  "libgfa_wrapper.so")))


(define gbwt-functions-ref
  (make-hash
   (list
     `("SEARCHSTATE" .  (make-hash (list `("BARE" . (make-hash (list)))))))))


(define gbwt-functions
  (make-hash
   (list

     `("DGBWT_delete" .  ,(_fun _pointer ->  _void))
     `("DGBWT_new" . ,(_fun ->  _pointer))
     `("DGBWT_to_GBWT" . ,(_fun _pointer ->  _pointer))
     `("DGBWT_delete" .  ,(_fun _pointer ->  _void))
     `("DGBWT_insert" . ,(_fun _pointer _pointer ->  _pointer))
     `("GBWT_SEARCHSTATE_extend" . ,(_fun _pointer _pointer _pointer _uint64 ->  _void))

     `("SEARCHSTATE_sizeof" . ,(_fun ->  _int))
     `("SEARCHSTATE_node" . ,(_fun _pointer -> _uint64))
     `("SEARCHSTATE_range" . ,(_fun _pointer -> _CPair))
     `("BI_SEARCHSTATE_sizeof" . ,(_fun ->  _int))

     `("GBWT_delete" .  ,(_fun _pointer ->  _void))
     `("GBWT_first_node" . ,(_fun _pointer -> _uint64))
     `("GBWT_find" . ,(_fun _pointer _pointer _uint64 -> _void))
     `("GBWT_extend" . ,(_fun _pointer _pointer _pointer _uint64 ->  _void))
     `("BI_SEARCHSTATE_backward" . ,(_fun _pointer _pointer -> _void))
     `("BI_SEARCHSTATE_forward" . ,(_fun  _pointer _pointer -> _void))
     `("SEARCHSTATE_size" . ,(_fun _pointer -> _uint64))

     `("BI_SEARCHSTATE_state_size" . ,(_fun _pointer -> _uint64))
     `("SEARCHSTATE_empty"  . ,(_fun _pointer -> _bool))
     `("SEARCHSTATE_flip"  . ,(_fun _pointer -> _bool))
     `("GBWT_size"  . ,(_fun _pointer -> _uint64))
     `("GBWT_sequences"  . ,(_fun _pointer -> _uint64))
     `("GBWT_sigma"  . ,(_fun _pointer -> _uint64))
     `("GBWT_samples"  . ,(_fun _pointer -> _uint64))
     `("GBWT_effective"  . ,(_fun _pointer -> _uint64))
     `("GBWT_SEARCHSTATE_contains" . ,(_fun _pointer _pointer ->  _bool))


     `("GBWT_edge" . ,(_fun _pointer _uint64 _uint64 ->  _bool))
     `("GBWT_to_comp" . ,(_fun _pointer _uint64 ->  _uint64))
     `("GBWT_to_node" . ,(_fun _pointer _uint64 ->  _uint64))

     `("GBWT_node_size" . ,(_fun _pointer _uint64 ->  _uint64))
     `("GBWT_locate" . ,(_fun _pointer _uint64 _uint64 ->  _uint64))
     `("GBWT_contains "  .  ,(_fun _pointer  _uint64 ->  _bool))
     `("GBWT_contains_edge" . ,(_fun _pointer _CPair ->  _bool))
     `("GBWT_SEARCHSTATE_contains_"   .  ,(_fun _pointer _pointer ->  _bool))
     `("GBWT_sequences " . ,(_fun _pointer -> _uint64))
     `("GBWT_LF_next_node_from_offset" . ,(_fun _pointer _uint64  _uint64 ->  _CPair))
     `("GBWT_LF_next_node_from_edge" . ,(_fun _pointer _CPair ->  _CPair))
     `("GBWT_LF_next_offset_from_node" . ,(_fun _pointer _uint64  _uint64  _uint64 ->  _uint64))
     `("GBWT_LF_range_of_successors_from_node" . ,(_fun _pointer _uint64 _CPair  _uint64 ->  _CPair))
     `("GBWT_edges" . ,(_fun _pointer _uint64 ->  _CPair))
     `("GBWTGRAPH_gfa_to_gbwt". ,(_fun _string -> _GBWTSequenceSourcePair)))))





(define (debug _t)
  (let ([deb  (get-ffi-obj "debug" libgbwtwrapper (_fun -> _pointer))])
    (ptr-ref  (deb) _t)))

; (define read-GFA (get-ffi-obj "consume_gfs_file" libgfawrapper (_fun _pointer ->  _CStringArray)))


(define/memoize (create-foreign-function m)
 (let ([k (if (symbol? m)(symbol->string m) m)])
  (with-handlers
    ([exn:fail:contract?   (λ (exn) (displayln (exn-message exn)))]
     [exn:fail?  (λ (exn)
                    (let([box_ (set-box! (box)  (hash-remove (unbox (create-foreign-function)) k))])
                      (set-box! (create-foreign-function ) box_)
                      (displayln (exn-message exn))))])
    (letrec ([k*  (regexp-replace* #rx"-" k "_")]
             [v (hash-ref gbwt-functions k*)])
      (get-ffi-obj k* libgbwtwrapper  v)))))


(define (call-method  . xs)
     (match xs
       [(cons head tail)  (apply (create-foreign-function head) tail)]
       [(list head)  (create-foreign-function head)]
       ['() (raise "You need to provide the method name in kebab or snake case")]))


(define (make-genome-stream the-struct)
 (let ([data (CStringArray-data the-struct)]
       [the-stream (in-range 0 (CStringArray-size the-struct))])
   (stream-map (λ (x) (ptr-ref data _pointer x)) the-stream)))

(define (insert-to-sample-gbwt gbwt_ gs)
  (stream-for-each
    (λ (x) (call-method "DGBWT_insert" gbwt_ x)) gs)
  (stream-length gs))

(define  (get-line . xs)
  (match xs
   [(list head) (get-line head 1)]
   [(list f s) #:when (< s (CStringArray-size f))
               string->immutable-string  (ptr-ref  (CStringArray-data f) _string  s)]))

