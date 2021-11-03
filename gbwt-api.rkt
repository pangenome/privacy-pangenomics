#lang racket


(define cpair-size 16)

(require ffi/unsafe)
(require setup/dirs)
(require memo)

; (require ffi/cvector)

(provide call-method)
(provide get-gbwt)

(provide get-cpair)

(provide get-cpair*)

(provide get-handle*)

(provide get-handle)

(provide get-view)

(define-cstruct _CStringArray
  ([data _pointer] [size _int]))

(define-cstruct _View
  ([data _bytes]
   [length _uint64]))

(define  (get-view view)
  (values
    (View-data view)
    (View-length view)))

(define-cstruct _CPair
  ([first _uint64]
   [second _uint64]))
;  (ptr-ref (malloc 'atomic node_array_type) node_array_type))

(define  _handle_t_data_type (_array _bytes (compiler-sizeof '(long long int))))

(define-cstruct _handle_t
  ([data  _handle_t_data_type]))

(define (get-handle x)
   (handle_t-data x))

(define (get-cpair cpair)
   (values
     (CPair-first cpair)
     (CPair-second cpair)))

(define (get-cpair* ptr)
     (get-cpair (ptr-ref ptr _CPair)))


(define-cstruct _GBWTSequenceSourcePair
  ([gbwt-ref _pointer]
   [sequence-source-ref _pointer]))


(define (get-handle* the-ptr)
  (ptr-ref the-ptr _handle_t))


(define get-gbwt  GBWTSequenceSourcePair-gbwt-ref)

(display (getenv "LD_LIBRARY_PATH"))

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
      `("gfa_to_gbwtgraph". ,(_fun _string -> _pointer))
      `("collect_handle_edges". ,(_fun _pointer _handle_t _bool -> _pointer))
      `("collect_handles". ,(_fun _pointer _handle_t _bool -> _pointer))

      `("print_nodes". ,(_fun _pointer _handle_t _bool -> _string))
      `("graph_size". ,(_fun _pointer -> _int))
      `("GBWTGRAPH_max_node_id".  ,(_fun _pointer -> _uint64))
      `("GBWTGRAPH_min_node_id". ,(_fun _pointer -> _uint64));
      `("get_state". ,(_fun _handle_t _pointer -> _void))

      `("size_of_handle_t". ,(_fun -> _int))
      `("node_to_handle" . ,(_fun _uint64 -> _handle_t))
      `("handle_to_node". ,(_fun _handle_t -> _uint64))

      `("graph_pop_front". ,(_fun _pointer _pointer -> _bool))
      `("graph_pop_last". ,(_fun _pointer _pointer -> _bool))

      `("graph_last_node". ,(_fun _pointer _pointer -> _bool))
      `("graph_first_node". ,(_fun _pointer _pointer -> _bool))

      `("GBWTGRAPH_find_path_from_nodes". ,(_fun _pointer _pointer _int _pointer -> _void))

      `("GBWTGRAPH_sequence_view_from_node". ,(_fun _pointer _uint64  -> _View))


      `("DGBWT_delete". ,(_fun _pointer _pointer _int _pointer -> _void))


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
      `("GBWT_SEARCHSTATE_contains" . ,(_fun _pointer _pointer ->  _bool))
      `("GBWT_size"  . ,(_fun _pointer -> _uint64))
      `("GBWT_sequences"  . ,(_fun _pointer -> _uint64))
      `("GBWT_sigma"  . ,(_fun _pointer -> _uint64))
      `("GBWT_samples"  . ,(_fun _pointer -> _uint64))
      `("GBWT_effective"  . ,(_fun _pointer -> _uint64))

      `("GBWT_edge" . ,(_fun _pointer _uint64 _uint64 ->  _bool))
      `("GBWT_to_comp" . ,(_fun _pointer _uint64 ->  _uint64))
      `("GBWT_to_node" . ,(_fun _pointer _uint64 ->  _uint64))

      `("GBWT_node_size" . ,(_fun _pointer _uint64 ->  _uint64))
      `("GBWT_locate" . ,(_fun _pointer _uint64 _uint64 ->  _uint64))
      `("GBWT_contains "  .  ,(_fun _pointer  _uint64 ->  _bool))
      `("GBWT_contains_edge" . ,(_fun _pointer _CPair ->  _bool))
      `("GBWT_SEARCHSTATE_contains_"   .  ,(_fun _pointer _pointer ->  _bool))
      `("GBWT_sequences " . ,(_fun _pointer -> _uint64))
      `("GBWT_start" . ,(_fun _pointer _uint64 _pointer -> _void))
      `("GBWT_tryLocate" . ,(_fun _pointer _uint64 _uint64  -> _uint64))
      `("GBWT_edges" . ,(_fun _pointer _uint64 ->  _CPair))

      `("GBWT_LF_next_node_from_offset" . ,(_fun _pointer _uint64  _uint64 ->  _CPair))
      `("GBWT_LF_next_node_from_edge" . ,(_fun _pointer _CPair ->  _CPair))
      `("GBWT_LF_next_offset_from_node" . ,(_fun _pointer _uint64  _uint64  _uint64 ->  _uint64))
      `("GBWT_LF_range_of_successors_from_node" . ,(_fun _pointer _uint64 _CPair  _uint64 ->  _CPair))
      `("GBWTGRAPH_gfa_to_gbwt". ,(_fun _string -> _GBWTSequenceSourcePair)))))


(define (debug _t)
  (let ([deb  (get-ffi-obj "debug" libgbwtwrapper (_fun -> _pointer))])
    (ptr-ref  (deb) _t)))


; (get-ffi-obj "debug" libgbwtwrapper (_fun -> _pointer))

(define/memoize (create-foreign-function m)
                (let ([k (if
                           (symbol? m)
                           (symbol->string m) m)])
                  (displayln m)
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

