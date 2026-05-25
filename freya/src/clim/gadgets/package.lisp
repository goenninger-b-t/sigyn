;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — clim/gadgets: the full standard gadget set, drawn entirely on the GPU
;;; (no native widgets), plus the look-and-feel/theming layer (light/dark,
;;; DPI-aware) realized by the default frame manager.
;;; SKELETON (ROADMAP Phase 8): defines the package only; no functionality yet.

(in-package #:cl-user)

(defpackage #:net.goenninger.freya.gadgets
  (:use #:cl)
  (:documentation "GPU-drawn gadgets + theming/look-and-feel. Exports into CLIM."))
