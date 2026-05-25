;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — compat: the shared optimization policy (PLAN §17.2/§17.3, ADR-0009).
;;;
;;; Two build profiles, selected by the :freya-release feature:
;;;   * checked (feature absent): (speed 1) (safety 3) (debug 2) — full runtime
;;;     and compile-time type checks; tests run here.
;;;   * release (feature present): hot modules drop to (speed 3) (safety 0); other
;;;     modules to (speed 2) (safety 1). The compiler trusts the declarations that
;;;     were verified at compile time + under the checked test run → no runtime
;;;     type-check penalty.
;;;
;;; Each source file installs its policy by putting one of the macros below at the
;;; top, right after IN-PACKAGE. Hot files use OPTIMIZE-HOT; everything else uses
;;; OPTIMIZE-SAFE.

(in-package #:net.goenninger.freya.compat)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun %release-p ()
    (and (member :freya-release *features* :test #'eq) t)))

(defmacro optimize-hot ()
  "Top-level: install the hot-path optimization policy for the current file."
  `(declaim (optimize ,@(if (%release-p)
                            '((speed 3) (safety 0) (debug 0) (space 0))
                            '((speed 1) (safety 3) (debug 2)))
                      (compilation-speed 0))))

(defmacro optimize-safe ()
  "Top-level: install the default (non-hot) optimization policy for the file."
  `(declaim (optimize ,@(if (%release-p)
                            '((speed 2) (safety 1) (debug 1))
                            '((speed 1) (safety 3) (debug 2)))
                      (compilation-speed 0))))

(declaim (ftype (function () boolean) releasep)
         (inline releasep))
(defun releasep ()
  "True in a release build (the :freya-release feature is present)."
  #+freya-release t
  #-freya-release nil)
