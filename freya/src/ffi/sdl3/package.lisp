;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — ffi.sdl3: CFFI bindings to SDL3, used ONLY for windowing, input,
;;; IME, clipboard, cursors, HiDPI, and timers — never for rendering.
;;; SKELETON (ROADMAP Phase 0): defines the packages only; no functionality yet.

(in-package #:cl-user)

(defpackage #:net.goenninger.freya.ffi.sdl3.raw
  (:use #:cl)
  (:documentation "Generated raw SDL3 bindings."))

(defpackage #:net.goenninger.freya.ffi.sdl3
  (:use #:cl)
  (:documentation "Ergonomic SDL3 wrapper (+ native-window-handle plumbing for WGPU surfaces).")
  (:export #:+pinned-version+ #:load-libsdl3
           #:sdl-get-version #:load-generated-bindings))
