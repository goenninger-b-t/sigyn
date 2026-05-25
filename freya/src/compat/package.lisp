;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — compat: per-Lisp shims (threads, timers, FFI quirks, main-thread,
;;; weak tables/finalizers) and the shared optimize policy + type-declaration
;;; vocabulary (PLAN §17). The ONLY place with #+sbcl/#+ccl/… conditionals in the
;;; portable layers.

(in-package #:cl-user)

(defpackage #:net.goenninger.freya.compat
  (:use #:cl)
  (:documentation "Per-Lisp portability shims + optimize policy + domain types.
The only module with impl-specific (#+sbcl/#+allegro/…) code; AllegroCL is the
target and takes a portable path for every shim (ADR-0001/0009/0011).")
  ;; §17 build policy
  (:export #:optimize-hot #:optimize-safe #:releasep)
  ;; §17.1 domain type vocabulary
  (:export #:octet #:u8 #:u16 #:u32 #:u64 #:i8 #:i16 #:i32 #:i64
           #:f32 #:f64 #:index #:nonneg-fixnum
           #:coordinate #:dimension #:unit-real #:device-pixel #:rgba8)
  ;; concurrency
  (:export #:make-thread #:current-thread #:threadp #:thread-alive-p
           #:join-thread #:thread-name #:all-threads
           #:make-lock #:with-lock-held #:acquire-lock #:release-lock
           #:make-recursive-lock #:with-recursive-lock-held
           #:make-condition-variable #:condition-wait #:condition-notify
           #:atomic-counter #:make-atomic-counter #:atomic-counter-p
           #:atomic-incf #:atomic-decf #:atomic-counter-value #:atomic-counter-reset)
  ;; memory
  (:export #:make-weak-hash-table #:make-weak-pointer #:weak-pointer-value
           #:weak-pointer-p #:finalize #:cancel-finalization)
  ;; scheduling & main-thread
  (:export #:*main-thread* #:note-main-thread #:main-thread-p #:ensure-main-thread
           #:run-display-server
           #:timer #:make-timer #:timer-p #:schedule-timer #:unschedule-timer))
