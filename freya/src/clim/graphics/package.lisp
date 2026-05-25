;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — clim/graphics: the CLIM design/ink model (colors, opacity, patterns,
;;; stencils, tiles, gradients, flipping inks), line/text styles, and the
;;; abstract drawing protocol. Renderer-blind; designs lower to Scene paints
;;; later, in the medium.
;;; SKELETON (ROADMAP Phase 3): defines the package only; no functionality yet.

(in-package #:cl-user)

(defpackage #:net.goenninger.freya.graphics
  (:use #:cl)
  (:documentation "CLIM designs/inks, line/text styles, drawing protocol. Exports into CLIM."))
