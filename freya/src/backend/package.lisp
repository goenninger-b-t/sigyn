;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — backend: THE (only) CLIM backend. Implements Silica's port/graft/
;;; medium/mirror protocols on top of net.goenninger.freya.render (Scene API +
;;; GPU renderer) and net.goenninger.freya.platform (display server). This is the
;;; hinge where the CLIM medium becomes Scene-API calls.
;;; SKELETON (ROADMAP Phase 4): defines the package only; no functionality yet.

(in-package #:cl-user)

(defpackage #:net.goenninger.freya.backend
  (:use #:cl)
  (:documentation "The GPU-only CLIM backend: Silica medium/mirror/port over render + platform."))
