;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — ffi.text: optional CFFI bindings for font/text and image decoding
;;; (FreeType, HarfBuzz, stb_image or equivalents). Default vs. pure-CL posture
;;; is ADR-0003.
;;; SKELETON (ROADMAP Phase 2): defines the package only; no functionality yet.

(in-package #:cl-user)

(defpackage #:net.goenninger.freya.ffi.text
  (:use #:cl)
  (:documentation "Optional FreeType/HarfBuzz/image-decode bindings (ADR-0003).")
  (:export #:load-libfreetype #:load-libharfbuzz))
