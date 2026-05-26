;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;;
;;;  Freya — a clean-room CLIM 2 with a GPU-only WebGPU backend.
;;;
;;;  One primary system (net.goenninger.freya) plus secondary systems
;;;  (net.goenninger.freya/<module>) describing the module map in docs/PLAN.md.
;;;
;;;  STATUS: skeleton. Modules currently define packages only; functionality is
;;;  added per docs/ROADMAP.md. External Lisp dependencies are declared but need
;;;  not be installed to read this file.
;;;
;;;  ENGINEERING STANDARDS (PLAN §17): all functions/variables carry type
;;;  declarations; the :freya-hot module set is inlined + block-compiled; two
;;;  optimize profiles are selected by build feature — *checked* (safety 3, for
;;;  tests/CI) and *release* (speed 3 / safety 0 in hot modules, zero runtime
;;;  type-check cost, ADR-0009). The shared optimize policy + declaration helpers
;;;  live in .../compat. Built-in Prometheus telemetry (.../telemetry, ADR-0010)
;;;  compiles to nothing unless :freya-telemetry is on *features*.

(cl:in-package #:cl-user)

;;; --------------------------------------------------------------------------
;;; Foundation: per-Lisp shims, no GPU/CLIM knowledge.

(asdf:defsystem #:net.goenninger.freya/compat
  :description "Per-Lisp shims (threads/timers/FFI/main-thread/weak-tables) + the shared optimize policy and type-declaration helpers (PLAN §17)."
  :author "Gönninger B&T <support@goenninger.net>"
  :license "MIT"
  :depends-on (#:alexandria #:bordeaux-threads #:trivial-features
               #:trivial-garbage #:closer-mop)
  :pathname "src/compat/"
  :serial t
  :components ((:file "package")
               (:file "policy")
               (:file "types")
               (:file "concurrency")
               (:file "memory")
               (:file "scheduling")))

;;; --------------------------------------------------------------------------
;;; Telemetry: built-in Prometheus instrumentation (ADR-0010). Zero-cost unless
;;; :freya-telemetry is on *features*. Depended on broadly so it is "built in".

(asdf:defsystem #:net.goenninger.freya/telemetry
  :description "Built-in Prometheus metrics: registry, canonical metric set, zero-cost macros, pluggable exposers."
  :license "MIT"
  ;; prometheus is pulled in ONLY when :freya-telemetry is enabled, so a default
  ;; (telemetry-off) build carries no instrumentation dependency at all.
  :depends-on (#:net.goenninger.freya/compat
               (:feature :freya-telemetry #:prometheus)
               (:feature :freya-telemetry #:prometheus.formats.text))
  :pathname "src/telemetry/"
  :serial t
  :components ((:file "package")
               (:file "telemetry")))

;;; --------------------------------------------------------------------------
;;; FFI layer (CFFI). Generated raw bindings + ergonomic wrappers.

(asdf:defsystem #:net.goenninger.freya/ffi-wgpu
  :description "CFFI bindings to wgpu-native (WebGPU C ABI)."
  :depends-on (#:net.goenninger.freya/compat #:cffi)
  :pathname "src/ffi/wgpu/"
  :serial t
  :components ((:file "package")
               (:file "library")
               (:file "bindings")))

(asdf:defsystem #:net.goenninger.freya/ffi-sdl3
  :description "CFFI bindings to SDL3 (windowing/input/clipboard/IME/HiDPI)."
  :depends-on (#:net.goenninger.freya/compat #:cffi)
  :pathname "src/ffi/sdl3/"
  :serial t
  :components ((:file "package")
               (:file "library")
               (:file "bindings")))

(asdf:defsystem #:net.goenninger.freya/ffi-text
  :description "Optional CFFI bindings: FreeType/HarfBuzz/image decode (ADR-0003)."
  :depends-on (#:net.goenninger.freya/compat #:cffi)
  :pathname "src/ffi/text/"
  :serial t
  :components ((:file "package")
               (:file "library")))

;;; --------------------------------------------------------------------------
;;; GPU rendering: the Scene API + Tier-1/Tier-2 renderers + glyph atlas.

(asdf:defsystem #:net.goenninger.freya/render
  :description "Scene API and the GPU 2D vector+text renderer (Tier-1 + from-scratch Tier-2)."
  :depends-on (#:net.goenninger.freya/compat
               #:net.goenninger.freya/telemetry
               #:net.goenninger.freya/ffi-wgpu
               #:net.goenninger.freya/ffi-text ; FreeType/HarfBuzz default glyph engine (ADR-0003)
               #:alexandria #:static-vectors)
  :pathname "src/render/"
  :serial t
  :components ((:file "package")))

;;; --------------------------------------------------------------------------
;;; Platform: the display-server loop, windows, surfaces, event pump.

(asdf:defsystem #:net.goenninger.freya/platform
  :description "Display-server loop, windows, WGPU surface creation, event pump, DPI."
  :depends-on (#:net.goenninger.freya/compat
               #:net.goenninger.freya/telemetry
               #:net.goenninger.freya/ffi-sdl3
               #:net.goenninger.freya/ffi-wgpu
               #:net.goenninger.freya/render)
  :pathname "src/platform/"
  :serial t
  :components ((:file "package")))

;;; --------------------------------------------------------------------------
;;; CLIM kernel (pure, renderer-blind).

(asdf:defsystem #:net.goenninger.freya/geometry
  :description "CLIM geometry: region algebra + affine transformations."
  :depends-on (#:net.goenninger.freya/compat #:alexandria)
  :pathname "src/clim/geometry/"
  :serial t
  :components ((:file "package")))

(asdf:defsystem #:net.goenninger.freya/graphics
  :description "CLIM designs/inks, line/text styles, the drawing protocol (renderer-blind)."
  :depends-on (#:net.goenninger.freya/geometry)
  :pathname "src/clim/graphics/"
  :serial t
  :components ((:file "package")))

;;; --------------------------------------------------------------------------
;;; Silica + the rest of the CLIM stack.

(asdf:defsystem #:net.goenninger.freya/silica
  :description "Silica: sheets, ports, grafts, mediums, mirrors, events."
  :depends-on (#:net.goenninger.freya/graphics)
  :pathname "src/clim/silica/"
  :serial t
  :components ((:file "package")))

(asdf:defsystem #:net.goenninger.freya/recording
  :description "Output recording + extended output/input streams."
  :depends-on (#:net.goenninger.freya/silica)
  :pathname "src/clim/recording/"
  :serial t
  :components ((:file "package")))

(asdf:defsystem #:net.goenninger.freya/presentations
  :description "Presentation types, presentation-method dispatch, translators, accept/present."
  :depends-on (#:net.goenninger.freya/recording #:closer-mop)
  :pathname "src/clim/presentations/"
  :serial t
  :components ((:file "package")))

(asdf:defsystem #:net.goenninger.freya/commands
  :description "Commands, command tables, command processors."
  :depends-on (#:net.goenninger.freya/presentations)
  :pathname "src/clim/commands/"
  :serial t
  :components ((:file "package")))

(asdf:defsystem #:net.goenninger.freya/frames
  :description "Application frames, panes, layout protocol, redisplay."
  :depends-on (#:net.goenninger.freya/commands
               #:net.goenninger.freya/telemetry)
  :pathname "src/clim/frames/"
  :serial t
  :components ((:file "package")))

(asdf:defsystem #:net.goenninger.freya/gadgets
  :description "GPU-drawn gadgets + look-and-feel/theming."
  :depends-on (#:net.goenninger.freya/frames)
  :pathname "src/clim/gadgets/"
  :serial t
  :components ((:file "package")))

(asdf:defsystem #:net.goenninger.freya/formatting
  :description "Formatting: tables, graphs, borders, indenting, filling."
  :depends-on (#:net.goenninger.freya/recording)
  :pathname "src/clim/formatting/"
  :serial t
  :components ((:file "package")))

;;; --------------------------------------------------------------------------
;;; Public CLIM packages (spec-mandated names).

(asdf:defsystem #:net.goenninger.freya/clim
  :description "Public CLIM API surface: clim, clim-lisp, clim-sys, clim-extensions."
  :depends-on (#:net.goenninger.freya/geometry
               #:net.goenninger.freya/graphics
               #:net.goenninger.freya/silica
               #:net.goenninger.freya/recording
               #:net.goenninger.freya/presentations
               #:net.goenninger.freya/commands
               #:net.goenninger.freya/frames
               #:net.goenninger.freya/gadgets
               #:net.goenninger.freya/formatting)
  :pathname "src/clim/public/"
  :serial t
  :components ((:file "package")))

;;; --------------------------------------------------------------------------
;;; The (only) backend: wire Silica's medium/mirror/port to render + platform.

(asdf:defsystem #:net.goenninger.freya/backend
  :description "The GPU-only CLIM backend: Silica medium/mirror/port over render + platform."
  :depends-on (#:net.goenninger.freya/clim
               #:net.goenninger.freya/render
               #:net.goenninger.freya/platform
               #:net.goenninger.freya/telemetry)
  :pathname "src/backend/"
  :serial t
  :components ((:file "package")))

;;; --------------------------------------------------------------------------
;;; Headless offscreen + remote/streaming transport (ADR-0007).

(asdf:defsystem #:net.goenninger.freya/remote
  :description "Headless offscreen sessions + remote streaming: frames out, input in."
  :depends-on (#:net.goenninger.freya/backend)
  :pathname "src/remote/"
  :serial t
  :components ((:file "package")))

;;; --------------------------------------------------------------------------
;;; Demos.

(asdf:defsystem #:net.goenninger.freya/demo
  :description "Demos and a CLIM Listener; double as integration tests."
  :depends-on (#:net.goenninger.freya/backend)
  :pathname "demo/"
  :serial t
  :components ((:file "package")))

;;; --------------------------------------------------------------------------
;;; Primary system: a working CLIM 2 on the GPU backend.

(asdf:defsystem #:net.goenninger.freya
  :description "Freya: a clean-room CLIM 2 with a GPU-only WebGPU backend."
  :author "Gönninger B&T <support@goenninger.net>"
  :maintainer "Frank Gönninger <frank.goenninger@goenninger.net>"
  :license "MIT"
  :version "0.0.1"
  :homepage "https://github.com/goenninger-b-t/freya"
  :depends-on (#:net.goenninger.freya/clim
               #:net.goenninger.freya/backend
               #:net.goenninger.freya/telemetry)
  :in-order-to ((asdf:test-op (asdf:test-op #:net.goenninger.freya/tests))))

;;; --------------------------------------------------------------------------
;;; Tests.

(asdf:defsystem #:net.goenninger.freya/tests
  :description "Unit / property / golden-image / conformance tests for Freya."
  :depends-on (#:net.goenninger.freya
               #:fiveam)
  :pathname "tests/"
  :serial t
  :components ((:file "package")
               (:file "suite"))
  :perform (asdf:test-op (op c)
             (uiop:symbol-call '#:net.goenninger.freya.tests '#:run-all)))
