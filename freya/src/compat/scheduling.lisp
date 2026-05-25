;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — compat: main-thread control and timers.
;;;
;;; The display server owns the GPU and all windows on the OS main thread (§8 of
;;; PLAN); on macOS this is mandatory. RUN-DISPLAY-SERVER is the entry point that
;;; takes over the calling thread. v0 records the main thread and runs the loop on
;;; the current thread; the platform module layers the macOS-specific
;;; main-thread-launch (Cocoa) and the cross-thread request queue on top.

(in-package #:net.goenninger.freya.compat)

(optimize-safe)

;;; --- Main thread ---------------------------------------------------------

(declaim (type (or null t) *main-thread*))
(defvar *main-thread* nil
  "The thread designated as the OS main thread (owns the GPU + windows).")

(declaim (ftype (function () t) note-main-thread)
         (ftype (function (&optional t) boolean) main-thread-p)
         (ftype (function (&optional t) t) ensure-main-thread)
         (ftype (function (function) t) run-display-server))

(defun note-main-thread ()
  "Record the current thread as the main thread. Call once at startup."
  (setf *main-thread* (current-thread)))

(defun main-thread-p (&optional (thread (current-thread)))
  "True if THREAD is the designated main thread (or none is designated yet)."
  (or (null *main-thread*) (eq thread *main-thread*)))

(defun ensure-main-thread (&optional who)
  "Signal an error if not running on the main thread."
  (unless (main-thread-p)
    (error "~@[~a: ~]must run on the main thread (~s), not ~s."
           who *main-thread* (current-thread))))

(defun run-display-server (function)
  "Take over the calling thread as the display server, running FUNCTION (the
loop). v0: records the main thread and calls FUNCTION here."
  (when (null *main-thread*) (note-main-thread))
  (ensure-main-thread 'run-display-server)
  (funcall function))

;;; --- Timers --------------------------------------------------------------

;; SBCL has a built-in timer wheel; AllegroCL (the target) and others use the
;; portable helper-thread fallback below. (An AllegroCL mp:make-timer fast path is
;; a possible later optimization.)
#+sbcl
(progn
  (declaim (ftype (function (function &key (:name (or null string))) t) make-timer)
           (ftype (function (t real &key (:repeat (or null real))) t) schedule-timer)
           (ftype (function (t) t) unschedule-timer)
           (ftype (function (t) t) timer-p))
  (defun make-timer (function &key name)
    (sb-ext:make-timer function :name (or name "freya-timer")))
  (defun schedule-timer (timer seconds &key repeat)
    (if repeat
        (sb-ext:schedule-timer timer seconds :repeat-interval repeat)
        (sb-ext:schedule-timer timer seconds)))
  (defun unschedule-timer (timer) (sb-ext:unschedule-timer timer))
  (defun timer-p (object) (typep object 'sb-ext:timer)))

#-sbcl ; AllegroCL and every other target
(progn
  ;; Portable fallback: one helper thread per scheduled timer.
  (defstruct (timer (:constructor %make-timer))
    (function (error "timer needs a function") :type function)
    (name "freya-timer" :type string)
    (thread nil)
    (cancelled nil :type boolean))
  (defun make-timer (function &key name)
    (%make-timer :function function :name (or name "freya-timer")))
  (defun schedule-timer (timer seconds &key repeat)
    (setf (timer-cancelled timer) nil)
    (setf (timer-thread timer)
          (make-thread
           (lambda ()
             (loop
               (sleep seconds)
               (when (timer-cancelled timer) (return))
               (funcall (timer-function timer))
               (unless repeat (return))
               (setf seconds repeat)))
           :name (timer-name timer)))
    timer)
  (defun unschedule-timer (timer) (setf (timer-cancelled timer) t)))
