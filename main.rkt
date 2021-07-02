#lang racket

(require ffi/unsafe)
(require describe)
(require setup/dirs)
(require memo)

; (require libuuid)



(define-cstruct _CStringArray ([data _pointer]
                               [size _int]))



(define-cstruct _CPair ([first _uint64]
                        [second _uint64]))



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
     `("DGBWT_new" . ,(_fun ->  _pointer))
     `("DGBWT_to_GBWT" . ,(_fun _pointer ->  _pointer))
     `("DGBWT_delete" .  ,(_fun _pointer ->  _void))
     `("DGBWT_insert" . ,(_fun _pointer _pointer ->  _void))
     `("GBWT_first_node" . ,(_fun _pointer -> _uint64))
     `("GBWT_find" . ,(_fun _pointer  _uint64 -> _pointer))
     `("GBWT_extend" . ,(_fun _pointer _pointer _uint64 ->  _pointer))
     `("GBWT_get_search_state_node" . ,(_fun _pointer -> _uint64))
     `("GBWT_get_search_state_range" . ,(_fun _pointer -> _CPair))
     `("GBWT_get_forward_state" . ,(_fun _pointer -> _pointer))
     `("GBWT_get_backward_state" . ,(_fun _pointer -> _pointer))
     `("GBWT_get_search_state_size" . ,(_fun _pointer -> _uint64))
     `("GBWT_get_bidirectional_state_size" . ,(_fun _pointer -> _uint64))
     `("GBWT_is_search_state_empty"  . ,(_fun _pointer -> _bool))
     `("GBWT_flip_state"  . ,(_fun _pointer -> _bool))
     `("GBWT_total_path_length"  . ,(_fun _pointer -> _uint64))
     `("GBWT_number_of_paths"  . ,(_fun _pointer -> _uint64))
     `("GBWT_alphabet_size"  . ,(_fun _pointer -> _uint64))
     `("GBWT_number_of_samples"  . ,(_fun _pointer -> _uint64))
     `("GBWT_effective_alpahbet_size"  . ,(_fun _pointer -> _uint64))
     `("GBWT_contains_search_state" . ,(_fun _pointer _pointer ->  _bool))
     `("GBWT_has_edge" . ,(_fun _pointer _uint64 _uint64 ->  _bool))
     `("GBWT_to_Comp" . ,(_fun _pointer _uint64 ->  _uint64))
     `("GBWT_to_Node" . ,(_fun _pointer _uint64 ->  _uint64))
     `("GBWT_node_size" . ,(_fun _pointer _uint64 ->  _uint64))
     `("GBWT_locateGBWT" . ,(_fun _pointer _uint64 _uint64 ->  _uint64))
     `("GBWT_contains_node"  .  ,(_fun _pointer  _uint64 ->  _bool))
     `("GBWT_contains_edge"   .  ,(_fun _pointer _uint64 ->  _bool))
     `("GBWT_contains_search_state"   .  ,(_fun _pointer _pointer ->  _bool)))))


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


(define (call-method  . xs)
     (match xs
       ['() (raise "You need to provide the method name in kebab or snake case")]
       [(list head)  (create-foreign-function head)]
       [(cons head tail)  (apply (create-foreign-function head) tail)]))



(define (make-genome-stream the-struct)
 (let ([data (CStringArray-data the-struct)]
       [the-stream (in-range 0 (CStringArray-size the-struct))])
   (stream-map (λ (x) (ptr-ref data _pointer x)) the-stream)))

(define (insert-to-sample-gbwt gbwt_ gs)
  (stream-for-each
    (λ (x) (call-method "DGBWT_insert" gbwt_ x)) gs)
  (stream-length gs))

(define GFAs (get-GFAS))
(define sample-GFA (read-GFA (car GFAs)))
(describe sample-GFA)
(CStringArray-size sample-GFA)
(ptr-ref  (CStringArray-data sample-GFA) _string  15)


