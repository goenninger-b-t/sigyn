;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — telemetry: built-in Prometheus instrumentation (ADR-0010, PLAN §17.4).
;;; The macros expand to nothing unless :freya-telemetry is on *features*, so a
;;; release build can carry zero instrumentation cost; when enabled, counters and
;;; histograms come from the prometheus client and the hot path stays allocation-
;;; free. Exposers (HTTP scrape / pushgateway / file) are pluggable on top of
;;; METRICS-TEXT.

(in-package #:cl-user)

(defpackage #:net.goenninger.freya.telemetry
  (:use #:cl)
  (:documentation "Built-in Prometheus telemetry: metrics, zero-cost macros, exposers (ADR-0010).")
  (:export ;; definition + instrumentation macros
           #:define-counter #:define-gauge #:define-histogram
           #:counter-incf #:gauge-set #:observe #:with-timer
           ;; introspection / exposition
           #:telemetry-enabled-p #:metrics-text
           ;; canonical metric set
           #:*frame-build-seconds* #:*present-latency-seconds*
           #:*frames-total* #:*frames-dropped-total*))
