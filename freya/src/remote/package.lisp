;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — remote: headless offscreen sessions (display server targeting an
;;; offscreen texture, no window) plus a remote/streaming transport — frame
;;; encode/diff out (reusing the damage model) and input events in (translated
;;; into the CLIM event queue exactly like local SDL events). See ADR-0007.
;;; SKELETON (ROADMAP Phase R, parallel from Phase 4): defines the package only.

(in-package #:cl-user)

(defpackage #:net.goenninger.freya.remote
  (:use #:cl)
  (:documentation "Headless offscreen + remote/streaming transport (ADR-0007)."))
