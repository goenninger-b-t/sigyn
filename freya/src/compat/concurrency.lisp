;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — compat: threads, locks, condition variables, and atomic counters.
;;; Thin portable wrappers over bordeaux-threads, with an SBCL fast path for
;;; atomics. The display-server model keeps shared mutable state tiny (§8); these
;;; are the primitives that guard it.

(in-package #:net.goenninger.freya.compat)

(optimize-safe)

;;; --- Threads -------------------------------------------------------------

(declaim (ftype (function (function &key (:name (or null string))) t) make-thread)
         (ftype (function () t) current-thread all-threads)
         (ftype (function (t) t) threadp thread-alive-p join-thread thread-name))

(defun make-thread (function &key name)
  "Spawn a thread running FUNCTION (a thunk)."
  (bt:make-thread function :name (or name "freya-thread")))

(defun current-thread () (bt:current-thread))
(defun threadp (x) (bt:threadp x))
(defun thread-alive-p (thread) (bt:thread-alive-p thread))
(defun join-thread (thread) (bt:join-thread thread))
(defun thread-name (thread) (bt:thread-name thread))
(defun all-threads () (bt:all-threads))

;;; --- Locks ---------------------------------------------------------------

(declaim (ftype (function (&optional (or null string)) t) make-lock make-recursive-lock)
         (ftype (function (t) t) acquire-lock release-lock))

(defun make-lock (&optional name) (bt:make-lock (or name "freya-lock")))
(defun make-recursive-lock (&optional name)
  (bt:make-recursive-lock (or name "freya-recursive-lock")))
(defun acquire-lock (lock) (bt:acquire-lock lock))
(defun release-lock (lock) (bt:release-lock lock))

(defmacro with-lock-held ((lock) &body body)
  "Evaluate BODY with LOCK held."
  `(bt:with-lock-held (,lock) ,@body))

(defmacro with-recursive-lock-held ((lock) &body body)
  "Evaluate BODY with the recursive LOCK held (re-entrant on this thread)."
  `(bt:with-recursive-lock-held (,lock) ,@body))

;;; --- Condition variables -------------------------------------------------

(declaim (ftype (function (&optional (or null string)) t) make-condition-variable)
         (ftype (function (t t &key (:timeout (or null real))) t) condition-wait)
         (ftype (function (t) t) condition-notify))

(defun make-condition-variable (&optional name)
  (bt:make-condition-variable :name (or name "freya-condvar")))

(defun condition-wait (condition-variable lock &key timeout)
  "Atomically release LOCK and wait on CONDITION-VARIABLE; reacquire on wake."
  (if timeout
      (bt:condition-wait condition-variable lock :timeout timeout)
      (bt:condition-wait condition-variable lock)))

(defun condition-notify (condition-variable)
  (bt:condition-notify condition-variable))

;;; --- Atomic counters -----------------------------------------------------
;;; The portable, lock-guarded implementation is the default and is what the
;;; AllegroCL target runs (correct on every bordeaux-threads platform). SBCL gets
;;; a lock-free fast path. A verifiable AllegroCL SMP fast path (excl atomics) is
;;; a possible later optimization; the lock-based version is the correctness base.

#+sbcl
(defstruct (atomic-counter (:constructor %make-atomic-counter))
  (value 0 :type sb-ext:word))

#-sbcl ; AllegroCL and every other target
(defstruct (atomic-counter (:constructor %make-atomic-counter))
  (value 0 :type (integer 0))
  (lock (bt:make-lock "atomic-counter")))

;; ATOMIC-COUNTER-VALUE is the struct's auto-generated reader (a word read is
;; atomic); it is exported as the public accessor.
(declaim (ftype (function (&optional unsigned-byte) atomic-counter) make-atomic-counter)
         (ftype (function (atomic-counter &optional unsigned-byte) unsigned-byte)
                atomic-incf atomic-decf atomic-counter-reset))

(defun make-atomic-counter (&optional (value 0))
  (%make-atomic-counter :value value))

(defun atomic-incf (counter &optional (delta 1))
  "Atomically add DELTA to COUNTER; return the new value."
  #+sbcl (the unsigned-byte (+ delta (sb-ext:atomic-incf (atomic-counter-value counter) delta)))
  #-sbcl (with-lock-held ((atomic-counter-lock counter)) ; AllegroCL et al.
           (incf (atomic-counter-value counter) delta)))

(defun atomic-decf (counter &optional (delta 1))
  "Atomically subtract DELTA from COUNTER; return the new value."
  #+sbcl (the unsigned-byte (- (sb-ext:atomic-decf (atomic-counter-value counter) delta) delta))
  #-sbcl (with-lock-held ((atomic-counter-lock counter)) ; AllegroCL et al.
           (decf (atomic-counter-value counter) delta)))

(defun atomic-counter-reset (counter &optional (value 0))
  "Set COUNTER to VALUE; return it."
  #+sbcl (setf (atomic-counter-value counter) value)
  #-sbcl (with-lock-held ((atomic-counter-lock counter))
           (setf (atomic-counter-value counter) value)))
