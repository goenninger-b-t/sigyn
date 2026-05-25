;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — clim/recording: output recording (the retained, spatially-indexed,
;;; replayable record tree — also the bridge to GPU repaint) plus extended output
;;; and extended input streams (cursor, wrapping, read-gesture, input editor).
;;; SKELETON (ROADMAP Phase 5): defines the package only; no functionality yet.

(in-package #:cl-user)

(defpackage #:net.goenninger.freya.recording
  (:use #:cl)
  (:documentation "Output records + extended I/O streams. Exports into CLIM."))
