;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — ffi.wgpu: CFFI bindings to wgpu-native (WebGPU C ABI, webgpu.h +
;;; wgpu.h). The `.raw` package holds generated bindings; the main package holds
;;; the ergonomic wrapper (keyword enums, struct builders, with-* RAII, errors).
;;; SKELETON (ROADMAP Phase 0): defines the packages only; no functionality yet.

(in-package #:cl-user)

(defpackage #:net.goenninger.freya.ffi.wgpu.raw
  (:use #:cl)
  (:documentation "Generated raw wgpu-native bindings (from pinned headers via c2ffi)."))

(defpackage #:net.goenninger.freya.ffi.wgpu
  (:use #:cl)
  (:documentation "Ergonomic wgpu-native wrapper over the raw bindings.")
  (:export #:+pinned-version+ #:load-libwgpu))
