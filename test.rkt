#lang racket

(require "gbwt-api.rkt")
(require ffi/unsafe)

(require threading)

(require describe)

(define (get-GFAS)
 (let ([fs  (directory-list  (current-directory))])
  (map (λ(x) (string->bytes/utf-8 (path->string x)))
   (filter (λ (x)
             (let ([the-file (path-get-extension (path->string x))])
               (if (not the-file)
                   #f
                   (bytes=? #".gfa" the-file)))) fs))))

(define GFAs (get-GFAS))




(define search-state (malloc 'atomic (call-method 'SEARCHSTATE-sizeof)))

(define search-state-1 (malloc 'atomic (call-method 'SEARCHSTATE-sizeof)))

(define sequenceA (malloc 'atomic 16))

(define (first-node  gbwt)
  (call-method 'GBWT-first-node  gbwt))




(define (next-node  gbwt node offset)
  (call-method 'GBWT-LF-next-node-from-offset gbwt node offset))



(define (next-offset gbwt from offset to)
  (call-method 'GBWT-LF-next-offset-from-node gbwt from offset to))


(define (find-next gbwt from offset to)
  (call-method 'GBWT-LF-next-offset-from-node gbwt from offset to))

;tests



(define (gfa->gbwt str)
  (with-handlers
    ([(λ (ex) (eq? 'io-error ex )) (λ (_) (displayln "Input output error"))])
    (define opened-gbwt (~>> str (call-method 'GBWTGRAPH-gfa-to-gbwt) get-gbwt))
    (unless opened-gbwt (raise  'io-error))
    opened-gbwt))


      ; `("GBWT_start" . ,(_fun _pointer _uint64 _CPair -> _void))
      ; `("GBWT_tryLocate" . ,(_fun _pointer _uint64 _uint64  -> _uint64))
      ; `("GBWT_edges" . ,(_fun _pointer _uint64 ->  _CPair))))
      ;

(define (get-sequences gbwt)
  (call-method 'GBWT-sequences gbwt))



; extern "C" void GBWT_start(void* GBWT, size_type sequence, CPair return_value);

(define (sequence-position gbwt s)
  (define tmp-s (malloc 'atomic 16))
  (call-method 'GBWT-start gbwt s tmp-s)
  (get-cpair* tmp-s))


(define gfa-file (list-ref GFAs 1))

; (define one (call-method 'gfa-to-gbwtgraph  gfa-file))


(define (gfa->gbwtgraph str)
  (with-handlers
    ([(λ (ex) (eq? 'io-error ex )) (λ (_) (displayln "Input output error"))])
    (define opened-gbwt (~>> str (call-method 'gfa-to-gbwtgraph) get-gbwt))
    (unless opened-gbwt (raise  'io-error))
    opened-gbwt))


(define sample-graph (call-method 'gfa-to-gbwtgraph gfa-file))


(define (get-first-handle graph) (call-method 'node-to-handle (call-method  'GBWTGRAPH-min-node-id graph)))



(define (handles->nodeList the-pointer)
  (let loop  ([node-list '()])
    (define  allocated-node (malloc 'atomic 8))
    (define has-node? (call-method 'graph-last-node the-pointer allocated-node))
    (if has-node?
      (loop (cons  (ptr-ref  allocated-node _uint64 ) node-list))
      node-list)))



(define  (graph-nodes  graph)
  (define first-handle (get-first-handle graph))
  (define all-handles (call-method 'collect-handles graph  first-handle #f))
  (handles->nodeList all-handles))


(define nodes  (graph-nodes sample-graph))
(displayln nodes)

(define node_array (_array _uint64 (length nodes)))

(define (nodeList->_array lst)
  (define the-count (length lst))
  (define node_array_type (_array _uint64  the-count))
  (define node_array  (ptr-ref (malloc 'atomic node_array_type) node_array_type))
  (for ([i (range the-count)])
    (array-set! node_array i (list-ref lst i)))
  node_array)



;  1+,4+,5+,6+,7+,9+)

(define path (list 4 5))

(define (search-path graph lst)
  (define path-array  (array-ptr  (nodeList->_array lst)))
  (define search-state (malloc 'atomic (call-method 'SEARCHSTATE-sizeof)))
  (call-method  'GBWTGRAPH-find-path-from-nodes  graph path-array (length lst) search-state)
  search-state)


(array-ptr (nodeList->_array (list 4 6)))

(define  alpha-search (search-path sample-graph (list 4 )))

; (describe alpha-search)

(call-method "SEARCHSTATE_size" alpha-search)

(get-cpair  (call-method "SEARCHSTATE_range" alpha-search))

; (array-ref node-array 2)

; (define  (print-nodes graph)
;   (define first-handle (get-first-handle graph))
;   (call-method 'print-nodes graph  first-handle #f))
;

; (define ska (print-nodes sample-graph))


; (define pipa (graph-nodes sample-graph))
