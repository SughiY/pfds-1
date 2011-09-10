#!r6rs
;;; deques.sls --- Purely functional deques

;; Copyright (C) 2011 Ian Price <ianprice90@googlemail.com>

;; Author: Ian Price <ianprice90@googlemail.com>

;; This program is free software, you can redistribute it and/or
;; modify it under the terms of the new-style BSD license.

;; You should have received a copy of the BSD license along with this
;; program. If not, see <http://www.debian.org/misc/bsd.license>.

;; Documentation:
;;
;; make-deque : () -> deque
;; returns a deque containing to items
;;
;; deque? : any -> boolean
;; tests if an object is a deque
;;
;; deque-length : deque -> non-negative integer
;; returns the number of items in the deque
;;
;; deque-empty? : deque -> boolean
;; returns true if there are no items in the deque, false otherwise
;;
;; insert-front : deque any -> deque
;; returns a new deque with the inserted item at the front
;;
;; insert-rear : deque any -> deque
;; returns a new deque with the inserted item at the rear
;;
;; remove-front : deque -> any queue
;; returns two values, the item at the front of the deque, and a new
;; deque containing all the other items
;; raises a &deque-empty condition if the deque is empty
;;
;; remove-rear : deque -> any queue
;; returns two values, the item at the rear of the deque, and a new
;; deque containing all the other items
;; raises a &deque-empty condition if the deque is empty
;;
;; deque-empty-condition? : object -> boolean
;; tests if an object is a &deque-empty condition
;;
(library (pfds deques)
(export make-deque
        deque?
        deque-length
        deque-empty?
        insert-front
        insert-rear
        remove-front
        remove-rear
        deque-empty-condition?
        )
(import (except (rnrs) cons*)
        (pfds private lazy-lists))

(define c 2)

(define (rot1 n l r)
  (if (>= n c)
      (cons* (head l)
             (rot1 (- n c) (tail l) (drop c r)))
      (rot2 l (drop n r) '())))

(define (rot2 l r a)
  (if (empty? l)
      (append* (rev r) a)
      (cons* (head l)
             (rot2 (tail l)
                   (drop c r)
                   (append* (rev (take c r)) a)))))

(define-record-type (deque %make-deque deque?)
  (fields
   (immutable length)
   (immutable lenL)
   (immutable lenR)
   (immutable l)
   (immutable r)
   (immutable l^)
   (immutable r^)))

(define (make-deque)
  (%make-deque 0 0 0 '() '() '() '()))

(define (deque-empty? deque)
  (zero? (deque-length deque)))

(define (insert-front deque item)
  (let ((len (deque-length deque))
        (l (deque-l deque))
        (r (deque-r deque))
        (lenL (deque-lenL deque))
        (lenR (deque-lenR deque))
        (l^ (deque-l^ deque))
        (r^ (deque-r^ deque)))
    (makedq (+ 1 len) (+ 1 lenL) lenR (cons* item l) r (tail l^) (tail r^))))

(define (insert-rear deque item)
  (let ((len (deque-length deque))
        (l (deque-l deque))
        (r (deque-r deque))
        (lenL (deque-lenL deque))
        (lenR (deque-lenR deque))
        (l^ (deque-l^ deque))
        (r^ (deque-r^ deque)))
    (makedq (+ 1 len) lenL (+ 1 lenR) l (cons* item r) (tail l^) (tail r^))))

(define (remove-front deque)
  (when (deque-empty? deque)
    (raise (condition
            (make-deque-empty-condition)
            (make-who-condition 'remove-front)
            (make-message-condition "There are no elements to remove")
            (make-irritants-condition (list deque)))))
  (let ((len (deque-length deque))
        (lenL (deque-lenL deque))
        (lenR (deque-lenR deque))
        (l (deque-l deque))
        (r (deque-r deque))
        (l^ (deque-l^ deque))
        (r^ (deque-r^ deque)))
    (if (empty? l)
        (values (head r) (make-deque))
        (values (head l)
                (makedq (- len 1)
                        (- lenL 1)
                        lenR
                        (tail l)
                        r
                        (tail (tail l^))
                        (tail (tail r^)))))))

(define (remove-rear deque)
  (when (deque-empty? deque)
    (raise (condition
            (make-deque-empty-condition)
            (make-who-condition 'remove-rear)
            (make-message-condition "There are no elements to remove")
            (make-irritants-condition (list deque)))))
  (let ((len (deque-length deque))
        (lenL (deque-lenL deque))
        (lenR (deque-lenR deque))
        (l (deque-l deque))
        (r (deque-r deque))
        (l^ (deque-l^ deque))
        (r^ (deque-r^ deque)))
    (if (empty? r)
        (values (head l) (make-deque))
        (values (head r)
                (makedq (- len 1)
                        lenL
                        (- lenR 1)
                        l
                        (tail r)
                        (tail (tail l^))
                        (tail (tail r^)))))))



(define (makedq len lenL lenR l r l^ r^)
  (cond ((> lenL (+ 1 (* c lenR)))
         (let* ((n  (floor (/ (+ lenL lenR) 2)))
                (l* (take n l))
                (r* (rot1 n r l)))
           (%make-deque len (- lenL n) (+ lenR n) l* r* l* r*)))
        ((> lenR (+ 1 (* c lenL)))
         (let* ((n  (floor (/ (+ lenL lenR) 2)))
                (l* (rot1 n l r))
                (r* (take n r)))
           (%make-deque len (+ lenL n) (- lenR n) l* r* l* r*)))
        (else
         (%make-deque len lenL lenR l r l^ r^))))

(define-condition-type &deque-empty
  &assertion
  make-deque-empty-condition
  deque-empty-condition?)

)
