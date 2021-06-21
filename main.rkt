#lang racket

(require ffi/unsafe)
(require describe)
(require setup/dirs)
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

(define newDynamicGWBT (get-ffi-obj "newDynamicGBWT" libgbwtwrapper (_fun ->  _pointer)))

(define deleteGBWT (get-ffi-obj "deleteDynamicGBWT" libgbwtwrapper (_fun _pointer ->  _void)))

(define DynamicGBWT->GBWT (get-ffi-obj "DynamicGBWT_to_GBWT" libgbwtwrapper (_fun _pointer ->  _pointer)))

(define insert-sequence (get-ffi-obj "insertSequence" libgbwtwrapper (_fun _pointer _pointer ->  _void)))

(define consume-gfs-file (get-ffi-obj "consume_gfs_file" libgfawrapper (_fun _pointer ->  _CStringArray)))

; (define insert-sequence (get-ffi-obj "insertSequence" libgbwtwrapper (_fun _pointer _pointer ->  _void)))

(define first-node (get-ffi-obj "firstGBWTNode"  libgbwtwrapper  (_fun _pointer -> _uint64)))


(define get-search-state-node   (get-ffi-obj "get_search_state_node"  libgbwtwrapper  (_fun _pointer -> _CPair)))


(define get-search-state-range (get-ffi-obj "get_search_state_range"  libgbwtwrapper  (_fun _pointer -> _CPair)))


(define get-forward-state (get-ffi-obj "get_forward_state"  libgbwtwrapper  (_fun _pointer -> _pointer)))


(define get-backward-state (get-ffi-obj "get_backward_state"  libgbwtwrapper  (_fun _pointer -> _pointer)))

(define get-search-state-size (get-ffi-obj "get_search_state_size"  libgbwtwrapper  (_fun _pointer -> _uint64)))

(define get-bidirectional-state-size (get-ffi-obj "get_bidirectional_state_size" libgbwtwrapper (_fun _pointer -> _uint64)))

(define  is-state-empty (get-ffi-obj "is_search_state_empty"  libgbwtwrapper  (_fun _pointer -> _bool)))

(define  flip-state (get-ffi-obj "flip_state"  libgbwtwrapper  (_fun _pointer -> _bool)))

(define total-path-length  (get-ffi-obj "total_path_length"  libgbwtwrapper  (_fun _pointer -> _uint64)))

(define number-of-paths (get-ffi-obj "number_of_paths"  libgbwtwrapper  (_fun _pointer -> _uint64)))

(define alphabet-size (get-ffi-obj "alphabet_size"  libgbwtwrapper  (_fun _pointer -> _uint64)))

(define number-of-samples (get-ffi-obj "number_of_samples"  libgbwtwrapper  (_fun _pointer -> _uint64)))

(define effective-alphabet-size (get-ffi-obj "effective_alpahbet_size"  libgbwtwrapper  (_fun _pointer -> _uint64)))

; (define prefixGBWT  (get-ffi-obj "prefixGBWT" libgbwtwrapper (_fun _pointer _uint64 ->  _pointer)))

(define extendGBWT (get-ffi-obj "extendGBWT" libgbwtwrapper (_fun _pointer _pointer _uint64 ->  _pointer)))

(define locateGBWT (get-ffi-obj "locateGBWT" libgbwtwrapper (_fun _pointer _uint64 _uint64 ->  _uint64)))

; (define DynamicGBWT->GBWT (get-ffi-obj "DynamicGBWT_to_GBWT" libgbwtwrapper (_fun _pointer ->  _pointer)))

        


(define (get-all-gfa-files)
 (let ([fs  (directory-list  (current-directory))])
  (map (λ(x) (string->bytes/utf-8 (path->string x)))
   (filter (λ (x)
             (let ([the-file (path-get-extension (path->string x))])
               (if (not the-file)
                   #f
                   (bytes=? #".gfa" the-file)))) fs))))


(define graph-files (get-all-gfa-files))
; (string->bytes/utf-8 "sequence")

(define sample-gfa (consume-gfs-file (car graph-files)))
; (describe sample-gfa)
; (CStringArray-data sample-gfa)


; (in-inclusive-range start end [step]) → stream?

(define (make-genome-stream the-struct)
  (let ([data (CStringArray-data the-struct)]
        [the-stream (in-range 0 (CStringArray-size the-struct))])
    (stream-map (λ (x) (ptr-ref data _pointer x)) the-stream)))


(define genome-stream (make-genome-stream sample-gfa))


(define the-gbwt (newDynamicGWBT))

; (describe DynamicGBWT->GBWT)
; (describe the-gbwt) 
; (define skata  (DynamicGBWT->GBWT the-gbwt))

(define (insert-to-sample-gbwt)
 (stream-for-each
   (λ (x)
      (insert-sequence the-gbwt x))
   genome-stream))

(insert-to-sample-gbwt)
(define GBWT  (DynamicGBWT->GBWT the-gbwt))

; (describe GBWT)
;;index statistics



