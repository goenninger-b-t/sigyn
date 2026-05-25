;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — platform: the display-server loop (owns SDL + all windows + the WGPU
;;; device on the main thread), window/surface lifecycle, the event pump, and
;;; DPI handling. Clients (CLIM frames) talk to it over lock-free queues.
;;; SKELETON (ROADMAP Phases 0/4): defines the package only; no functionality yet.

(in-package #:cl-user)

(defpackage #:net.goenninger.freya.platform
  (:use #:cl)
  (:documentation "Display-server loop, windows, WGPU surface creation, event pump, DPI."))
