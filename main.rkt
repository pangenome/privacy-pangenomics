#lang racket

(require ffi/unsafe)
(require describe)
(require setup/dirs)
; (require libuuid)


(define SEQ (string->bytes/utf-8 "sequence"))


(define (locate-library-path str)
  (let ([paths (map string->path
                  (map (λ (x)
                         (if (string-suffix? x "/")
                           (format "~a~a" x str)
                           (format "~a/~a" x str)))
                       (string-split (getenv "LD_LIBRARY_PATH") ":")))])
    (ormap (λ (x) (if (file-exists? x) x #f) ) paths)))






(define libgbwtwrapper (ffi-lib (locate-library-path  "libgbwtwrapper.so"))) ;#:global? #t))

(define libgfawrapper (ffi-lib (locate-library-path  "libgfa_wrapper.so")))



(define newDynamicGWBT (get-ffi-obj "newDynamicGBWT" libgbwtwrapper (_fun ->  _pointer)))


(define deleteGBWT (get-ffi-obj "deleteDynamicGBWT" libgbwtwrapper (_fun _pointer ->  _void)))

(define consume_gfs_file (get-ffi-obj "deleteDynamicGBWT" libgfawrapper (_fun _pointer ->  _void)))
;
; extern "C" void* newDynamicGBWT(void);
;
; extern "C" void* DynamicGBWT_to_GBWT(void* dynGBWT);
;
;
;
; extern "C" void deleteGBWT(void* GBWT);
; extern "C" void  deleteDynamicGBWT(void* dynGBWT);
;
; (define _pn_proactor_t (_cpointer 'pn_proactor_t))
;
; (define _pn_event_batch_t (_cpointer '_pn_event_batch_t))
;
; (define _pn_event_t (_cpointer '_pn_event_t))
;
;
