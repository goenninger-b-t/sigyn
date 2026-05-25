;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — top-level test suite (skeleton).

(in-package #:net.goenninger.freya.tests)

(fiveam:def-suite freya
  :description "All Freya tests (placeholder root suite).")

(fiveam:in-suite freya)

(fiveam:test packages-present
  "The module packages defined by the skeleton exist."
  (dolist (name '("NET.GOENNINGER.FREYA.COMPAT"
                  "NET.GOENNINGER.FREYA.TELEMETRY"
                  "NET.GOENNINGER.FREYA.SCENE"
                  "NET.GOENNINGER.FREYA.RENDER"
                  "NET.GOENNINGER.FREYA.GEOMETRY"
                  "NET.GOENNINGER.FREYA.SILICA"
                  "NET.GOENNINGER.FREYA.BACKEND"
                  "CLIM"))
    (fiveam:is (find-package name)
               "Expected package ~A to exist." name)))

(defun run-all ()
  "Run the full Freya test suite. Returns T on success, NIL otherwise."
  (fiveam:run! 'freya))
