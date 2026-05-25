;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — render: the Scene API (the seam decoupling CLIM from the GPU) and the
;;; 2D vector+text renderer. `scene` is the renderer-agnostic immediate-mode API;
;;; `render` holds the Tier-1 (tessellate+MSAA) and Tier-2 (compute-coverage)
;;; consumers, glyph atlas, paints, clip masks, pixmaps, and the layer cache.
;;; SKELETON (ROADMAP Phase 1): defines the packages only; no functionality yet.

(in-package #:cl-user)

(defpackage #:net.goenninger.freya.scene
  (:use #:cl)
  (:documentation "The renderer-agnostic 2D Scene API (no GPU types in signatures)."))

(defpackage #:net.goenninger.freya.render
  (:use #:cl)
  (:documentation "GPU 2D renderer(s) consuming the Scene API: Tier-1/Tier-2, atlas, paints."))
