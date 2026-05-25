;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — compat: per-Lisp shims (threads, timers, FFI quirks, main-thread,
;;; weak tables/finalizers, float traps). The ONLY place with #+sbcl/#+ccl/…
;;; conditionals in the upper layers.
;;; SKELETON (ROADMAP Phase 0): defines the package only; no functionality yet.

(in-package #:cl-user)

(defpackage #:net.goenninger.freya.compat
  (:use #:cl)
  (:documentation "Per-Lisp portability shims (ADR-0001: broad portability)."))
