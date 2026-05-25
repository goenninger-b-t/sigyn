;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — tests: unit, property-based, golden-image, and conformance tests.
;;; SKELETON: a trivial smoke suite exists so `asdf:test-system` is wired end to
;;; end; real suites are added per ROADMAP phase.

(in-package #:cl-user)

(defpackage #:net.goenninger.freya.tests
  (:use #:cl)
  (:export #:run-all)
  (:documentation "Freya test entry point."))
