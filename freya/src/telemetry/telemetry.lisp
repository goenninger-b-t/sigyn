;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — telemetry implementation. Two readings of this file: with the
;;; :freya-telemetry feature it wraps the prometheus client; without it, the same
;;; surface compiles to no-ops (WITH-TIMER still runs its body — only the
;;; measurement disappears).

(in-package #:net.goenninger.freya.telemetry)

(net.goenninger.freya.compat:optimize-safe)

;;; ===========================================================================
;;; Enabled: real Prometheus metrics.
;;; ===========================================================================
#+freya-telemetry
(progn
  ;; DEFPARAMETER (not DEFVAR) so reloading this file yields a fresh registry and
  ;; re-registers the canonical metrics cleanly instead of erroring.
  (defparameter *registry* (prometheus:make-registry)
    "The registry holding all Freya metrics.")

  (eval-when (:load-toplevel :execute)
    (setf prometheus:*default-registry* *registry*))

  (defparameter +default-latency-buckets+
    '(0.0005d0 0.001d0 0.002d0 0.004d0 0.008d0 0.012d0 0.016d0 0.020d0
      0.033d0 0.05d0 0.1d0 0.25d0 0.5d0 1.0d0)
    "Default histogram buckets (seconds), tuned for sub-frame timings.")

  (defmacro define-counter (var &key name help)
    `(defparameter ,var
       (let ((prometheus:*default-registry* *registry*))
         (prometheus:make-counter :name ,name :help ,(or help name)))))

  (defmacro define-gauge (var &key name help)
    `(defparameter ,var
       (let ((prometheus:*default-registry* *registry*))
         (prometheus:make-gauge :name ,name :help ,(or help name)))))

  (defmacro define-histogram (var &key name help buckets)
    `(defparameter ,var
       (let ((prometheus:*default-registry* *registry*))
         (prometheus:make-histogram :name ,name :help ,(or help name)
                                    :buckets ,(or buckets '+default-latency-buckets+)))))

  (defmacro counter-incf (metric &optional (delta 1))
    `(prometheus:counter.inc ,metric :value ,delta))

  (defmacro gauge-set (metric value)
    `(prometheus:gauge.set ,metric ,value))

  (defmacro observe (metric value)
    `(prometheus:histogram.observe ,metric ,value))

  (defmacro with-timer ((metric) &body body)
    "Run BODY, observing its wall-clock duration (seconds) into histogram METRIC."
    (let ((start (gensym "START")))
      `(let ((,start (get-internal-real-time)))
         (multiple-value-prog1 (progn ,@body)
           (prometheus:histogram.observe
            ,metric
            (/ (float (- (get-internal-real-time) ,start) 1d0)
               internal-time-units-per-second))))))

  (declaim (ftype (function () (eql t)) telemetry-enabled-p)
           (ftype (function () (or null string)) metrics-text))
  (defun telemetry-enabled-p () t)
  (defun metrics-text ()
    "The current metrics in Prometheus text-exposition format."
    (prometheus.formats.text:marshal *registry*)))

;;; ===========================================================================
;;; Disabled: zero-cost no-ops. (Default build.)
;;; ===========================================================================
#-freya-telemetry
(progn
  (defmacro define-counter (var &key name help)
    (declare (ignore name help))
    `(progn (defvar ,var nil) ',var))

  (defmacro define-gauge (var &key name help)
    (declare (ignore name help))
    `(progn (defvar ,var nil) ',var))

  (defmacro define-histogram (var &key name help buckets)
    (declare (ignore name help buckets))
    `(progn (defvar ,var nil) ',var))

  (defmacro counter-incf (metric &optional (delta 1))
    (declare (ignore metric delta))
    nil)

  (defmacro gauge-set (metric value)
    (declare (ignore metric value))
    nil)

  (defmacro observe (metric value)
    (declare (ignore metric value))
    nil)

  (defmacro with-timer ((metric) &body body)
    (declare (ignore metric))
    `(progn ,@body))

  (declaim (ftype (function () null) telemetry-enabled-p metrics-text))
  (defun telemetry-enabled-p () nil)
  (defun metrics-text () nil))

;;; ===========================================================================
;;; Canonical metric set (examples; expanded as subsystems land). These work in
;;; both readings — disabled, each DEFINE-* yields a NIL placeholder var.
;;; ===========================================================================
(define-histogram *frame-build-seconds*
  :name "freya_frame_build_seconds"
  :help "Wall-clock time to build one frame's scene.")

(define-histogram *present-latency-seconds*
  :name "freya_present_latency_seconds"
  :help "Time from frame submission to surface present.")

(define-counter *frames-total*
  :name "freya_frames_total"
  :help "Total frames presented.")

(define-counter *frames-dropped-total*
  :name "freya_frames_dropped_total"
  :help "Total frames dropped (missed deadline).")
