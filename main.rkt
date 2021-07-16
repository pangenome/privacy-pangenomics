#lang racket

(require ffi/unsafe)
(require describe)
(require setup/dirs)
(require memo)

; (require libuuid)


; (define skata (ffi-lib "/usr/local/lib/libhandlegraph.so" #:global? #t))

(define-cstruct _CStringArray ([data _pointer]
                               [size _int]))

(define-cstruct _CPair ([first _uint64]
                        [second _uint64]))

(define-cstruct _GBWTSequenceSourcePair ([gbwt-ref _pointer]
                                         [sequence-source-ref _pointer]))


(define (locate-library-path str)
  (let ([paths (map string->path
                  (map (λ (x)
                         (if (string-suffix? x "/")
                           (format "~a~a" x str)
                           (format "~a/~a" x str)))
                       (string-split (getenv "LD_LIBRARY_PATH") ":")))])
    (ormap (λ (x) (if (file-exists? x) x #f) ) paths)))

(define libgbwtwrapper (ffi-lib (locate-library-path  "libgbwtwrapper.so")))

(define libgfawrapper (ffi-lib (locate-library-path  "libgfa_wrapper.so")))


(define gbwt-functions
  (make-hash
   (list
     `("sizeof_bi_search_state" . ,(_fun ->  _int))
     `("sizeof_search_state" . ,(_fun ->  _int))
     `("DGBWT_new" . ,(_fun ->  _pointer))
     `("DGBWT_to_GBWT" . ,(_fun _pointer ->  _pointer))
     `("DGBWT_delete" .  ,(_fun _pointer ->  _void))
     `("DGBWT_insert" . ,(_fun _pointer _pointer ->  _pointer))
     `("GBWT_delete" .  ,(_fun _pointer ->  _void))
     `("GBWT_first_node" . ,(_fun _pointer -> _uint64))
     `("GBWT_find" . ,(_fun _pointer _pointer _uint64 -> _void))
     `("GBWT_extend" . ,(_fun _pointer _pointer _pointer _uint64 ->  _void))
     `("GBWT_get_search_state_node" . ,(_fun _pointer -> _uint64))
     `("GBWT_get_search_state_range" . ,(_fun _pointer -> _CPair))
     `("GBWT_get_forward_state" . ,(_fun _pointer _pointer -> _void))
     `("GBWT_get_backward_state" . ,(_fun  _pointer _pointer -> _void))
     `("GBWT_get_search_state_size" . ,(_fun _pointer -> _uint64))
     `("GBWT_get_bidirectional_state_size" . ,(_fun _pointer -> _uint64))
     `("GBWT_is_search_state_empty"  . ,(_fun _pointer -> _bool))
     `("GBWT_flip_state"  . ,(_fun _pointer -> _bool))
     `("GBWT_total_path_length"  . ,(_fun _pointer -> _uint64))
     `("GBWT_number_of_paths"  . ,(_fun _pointer -> _uint64))
     `("GBWT_alphabet_size"  . ,(_fun _pointer -> _uint64))
     `("GBWT_number_of_samples"  . ,(_fun _pointer -> _uint64))
     `("GBWT_effective_alphabet_size"  . ,(_fun _pointer -> _uint64))
     `("GBWT_contains_search_state" . ,(_fun _pointer _pointer ->  _bool))
     `("GBWT_has_edge" . ,(_fun _pointer _uint64 _uint64 ->  _bool))
     `("GBWT_to_Comp" . ,(_fun _pointer _uint64 ->  _uint64))
     `("GBWT_to_Node" . ,(_fun _pointer _uint64 ->  _uint64))
     `("GBWT_node_size" . ,(_fun _pointer _uint64 ->  _uint64))
     `("GBWT_locate" . ,(_fun _pointer _uint64 _uint64 ->  _uint64))
     `("GBWT_contains_node"  .  ,(_fun _pointer  _uint64 ->  _bool))
     `("GBWT_contains_edge"   .  ,(_fun _pointer _uint64 ->  _bool))
     `("GBWT_contains_search_state"   .  ,(_fun _pointer _pointer ->  _bool))
     ; `("GBWT_edges" . ,(_fun _pointer _uint64 ->  _CPair))
     `("GBWT_LF_next_node_from_offset" . ,(_fun _pointer _uint64  _uint64 ->  _CPair))
     `("GBWT_contains_edge" . ,(_fun _pointer _CPair ->  _bool))
     `("GBWT_LF_next_node_from_edge" . ,(_fun _pointer _CPair ->  _CPair))
     `("GBWT_LF_next_offset_from_node" . ,(_fun _pointer _CPair _uint64 ->  _CPair))
     `("GBWT_LF_range_of_successors_from_node" . ,(_fun _pointer _uint64 _CPair  _uint64 ->  _CPair))
     `("GBWT_edges" . ,(_fun _pointer _uint64 ->  _CPair))
     `("GBWTGRAPH_gfa_to_gbwt". ,(_fun _string -> _GBWTSequenceSourcePair))
     `("sizeof_search_state". ,(_fun -> _int))
     `("sizeof_bi_search_state". ,(_fun -> _int)))))


(define (debug _t)
  (let ([deb  (get-ffi-obj "debug" libgbwtwrapper (_fun -> _pointer))])
    (ptr-ref  (deb) _t)))

(define read-GFA (get-ffi-obj "consume_gfs_file" libgfawrapper (_fun _pointer ->  _CStringArray)))

(define (get-GFAS)
 (let ([fs  (directory-list  (current-directory))])
  (map (λ(x) (string->bytes/utf-8 (path->string x)))
   (filter (λ (x)
             (let ([the-file (path-get-extension (path->string x))])
               (if (not the-file)
                   #f
                   (bytes=? #".gfa" the-file)))) fs))))

(define/memoize (create-foreign-function k)
  (with-handlers
    ([exn:fail:contract?   (λ (exn) (displayln (exn-message exn)))]
     [exn:fail?  (λ (exn)
                    (let([box_ (set-box! (box)  (hash-remove (unbox (create-foreign-function)) k))])
                      (set-box! (create-foreign-function ) box_)
                      (displayln (exn-message exn))))])
    (letrec ([k*  (regexp-replace* #rx"-" k "_")]
             [v (hash-ref gbwt-functions k*)])
      (get-ffi-obj k* libgbwtwrapper  v))))


(define (call-gbwt-method  . xs)
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
    (λ (x) (call-gbwt-method "DGBWT_insert" gbwt_ x)) gs)
  (stream-length gs))


(define  (get-line . xs)
  (match xs
   [(list head) (get-line head 1)]
   [(list f s) #:when (< s (CStringArray-size f))
               string->immutable-string  (ptr-ref  (CStringArray-data f) _string  s)]))

(define GFAs (get-GFAS))

; (define sample-GFA (read-GFA (car GFAs)))


(define sample-gbwt (GBWTSequenceSourcePair-gbwt-ref (call-gbwt-method "GBWTGRAPH-gfa-to-gbwt"   (list-ref GFAs 3))))

(call-gbwt-method  "GBWT-first-node" sample-gbwt)

(call-gbwt-method  "GBWT-alphabet-size"  sample-gbwt)

(call-gbwt-method "GBWT-number-of-paths" sample-gbwt)

(call-gbwt-method "sizeof_search_state")

(define search-state (malloc 'atomic (call-gbwt-method "sizeof_search_state")))


; `("GBWT_find" . ,(_fun _pointer _pointer _uint64 -> _pointer)))
(define pipa (call-gbwt-method "GBWT_find" sample-gbwt search-state 2))

(describe pipa)
;(define sample-gbwt (GBWTSequenceSourcePair-gbwt-ref (call-gbwt-method "GBWTGRAPH-gfa-to-gbwt"    (car   GFAs))))

; (define search_s (call-gbwt-method "GBWT-find" sample-gbwt  2))
;
;
; (call-gbwt-method "GBWT_is_search_state_empty" search_s)
;
; (call-gbwt-method "GBWT_get_search_state_size" search_s)
;
; (call-gbwt-method  "GBWT_get_search_state_node"  search_s)
;

; (call-bgwt-method "debug")
;
(call-gbwt-method  "GBWT_get_search_state_node" search-state)
;
(call-gbwt-method  "GBWT_get_search_state_size" search-state)
;
(call-gbwt-method  "GBWT_is_search_state_empty"  search-state)

; (build-list 100 (λ (_) (call-gbwt-method  "GBWT-first-node" sample-gbwt)))
;
; (build-list 100 (λ (_) (call-gbwt-method "GBWT-number-of-paths" sample-gbwt)))

; vector_type extract(size_type sequence) const
; (call-gbwt-method "GBWT-node-size" sample-gbwt 1)


; (debug _bool)

;(call-gbwt-method "GBWT-contains" sample-gbwt)
;
; (define extended-state (call-gbwt-method "GBWT-extend" sample-gbwt search-state  search-state 5))
;(call-gbwt-method "GBWT-get-search-state-size" extended-state)

; (call-gbwt-find 2)
; (define pipa (call-gbwt-method "debug"))
; (describe pipa)
; (displayln pipa)
; (call-gbwt-method "GBWT_is_search_state_empty" search-s)




;("GBWT_first_node" . ,(_fun _pointer -> _uint64))
; (describe  (GBWTSequenceSourcePair-gbwt-ref sample-gbwt))
; (define pipa  (call-gbwt-method "GBWTGRAPH_gfa_to_gbwt"  ))

; (get-line sample-GFA 15)

; (> (CStringArray-size sample-GFA  ) 3)

;(describe sample-GFA)
;(CStringArray-size sample-GFA)
;(describe (string->immutable-string  (ptr-ref  (CStringArray-data sample-GFA) _string  15)))


