;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — telemetry: built-in Prometheus instrumentation (ADR-0010). Owns the
;;; metric registry, the canonical engine metric set, and the low-overhead macros
;;; (with-timer / observe / counter-incf / gauge-set). The macros expand to
;;; nothing unless :freya-telemetry is on *features*, so a release build can carry
;;; zero instrumentation cost; when enabled, counters are fixnum atomics and
;;; histograms are preallocated (lock-free, allocation-free on the hot path).
;;; Exposers (HTTP scrape / pushgateway / file) are pluggable. See PLAN §17.4.
;;; SKELETON (ROADMAP Phase 0): defines the package only; no functionality yet.

(in-package #:cl-user)

(defpackage #:net.goenninger.freya.telemetry
  (:use #:cl)
  (:documentation "Built-in Prometheus telemetry: registry, metrics, zero-cost macros, exposers (ADR-0010)."))
