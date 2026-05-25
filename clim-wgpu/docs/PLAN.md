# Bifröst — Design & Architecture Plan

A clean-room, high-performance **CLIM 2** in Common Lisp with a **GPU-only
WebGPU backend** (`wgpu-native`) on **SDL3**.

> Companion document: [`ROADMAP.md`](ROADMAP.md) (phases, estimates, risks,
> testing, performance targets). This document is the *what & why*; the roadmap
> is the *when & in what order*.

---

## Table of contents

1. [Vision, goals, non-goals](#1-vision-goals-non-goals)
2. [The core insight & the central bet](#2-the-core-insight--the-central-bet)
3. [Locked decisions and their consequences](#3-locked-decisions-and-their-consequences)
4. [Layered architecture overview](#4-layered-architecture-overview)
5. [The 2D GPU rendering engine (the hard part)](#5-the-2d-gpu-rendering-engine-the-hard-part)
6. [The text & font subsystem](#6-the-text--font-subsystem)
7. [FFI strategy: wgpu-native, SDL3, fonts](#7-ffi-strategy-wgpu-native-sdl3-fonts)
8. [Windowing, the display server, and the threading model](#8-windowing-the-display-server-and-the-threading-model)
9. [CLIM kernel: geometry, designs, styles](#9-clim-kernel-geometry-designs-styles)
10. [Silica: sheets, ports, grafts, mediums, mirrors, events](#10-silica-sheets-ports-grafts-mediums-mirrors-events)
11. [Output recording & extended streams](#11-output-recording--extended-streams)
12. [Presentations & commands](#12-presentations--commands)
13. [Frames, panes, layout, gadgets, look-and-feel](#13-frames-panes-layout-gadgets-look-and-feel)
14. [Module & package map](#14-module--package-map)
15. [Cross-cutting concerns](#15-cross-cutting-concerns)
16. [Open questions](#16-open-questions)

---

## 1. Vision, goals, non-goals

### Vision
A CLIM 2 you can hand an existing CLIM application and have it run — but every
pixel is rendered by a modern GPU pipeline, so the UI is crisp at any DPI,
smoothly animated, fast under huge output histories, and identical across Linux,
macOS, and Windows because *we* own the rendering rather than the OS.

### Goals
- **Conformance.** Faithful to the CLIM II specification: the public packages
  (`CLIM`, `CLIM-LISP`, `CLIM-SYS`, `CLIM-EXTENSIONS`) expose the documented
  symbols with documented behavior, so spec-conformant programs port unchanged.
- **GPU-only.** Exactly one backend. All drawing is GPU draw/compute work; no
  X11/GDI/Quartz drawing calls, no native widgets, no CPU blitter in the hot
  path. Fonts are parsed/shaped on the CPU but rasterized into GPU atlases.
- **High performance.** 60 fps for interactive UIs; sub-millisecond incremental
  redisplay for editor-style edits; smooth scrolling of very large output
  records (the classic CLIM Listener stress test); thousands of live
  presentations without lag.
- **Portability.** Runs on multiple Common Lisps and the three desktop OSes.

### Non-goals (initially)
- Not a web/WASM target (WebGPU-in-browser) — native only. (The architecture
  keeps the door open, but it is not a phase-1 concern.)
- Not a drop-in for backend-specific McCLIM extensions or other CLIMs'
  proprietary extensions; we implement the *spec* plus a small, documented
  `CLIM-EXTENSIONS` set.
- Not mobile/touch-first (desktop pointer+keyboard first; touch later).
- Not an accessibility-complete (screen reader) release in early phases — but we
  design the semantic layer (presentations) so accessibility is *reachable*.

---

## 2. The core insight & the central bet

CLIM is **already** structured for exactly this kind of port, and that structure
is what makes a GPU-only backend tractable.

1. **CLIM is layered, and most of it is backend-independent.** Region algebra,
   affine transforms, the design/ink model, output recording, presentations,
   command processing, formatting, frames, and the layout protocol have *no*
   dependency on how pixels reach the screen. A backend only has to provide:
   a **port** (display-system connection), **grafts** (screens), **mediums**
   (the drawing-protocol implementation), **mirrors** (sheets backed by real
   surfaces), and **event translation**. That is the entire GPU-specific
   surface. **Everything else is clean-room CL that runs the same regardless of
   renderer.**

2. **CLIM output recording is already a retained scene graph.** An output record
   tree is a persistent, queryable, replayable description of everything drawn —
   semantically tagged, with bounding rectangles and spatial queries. This maps
   *directly* onto how a modern GPU renderer wants its input: a retained scene
   you can diff, cull, batch, and re-emit. **We do not need to invent a display
   list — CLIM hands us one.**

**The central bet:** define a single internal **Scene API** (an immediate-mode
2D drawing interface: fills, strokes, text runs, images, clips, transforms,
layers) that sits *between* CLIM's medium and the GPU. Then:

- The CLIM **medium** becomes a thin translator: medium drawing ops → Scene ops.
- The **renderer** is a pluggable consumer of the Scene API. We ship two:
  - **Tier 1** — CPU-tessellation + batched triangles + MSAA. Simple, correct,
    portable. Brings the whole CLIM stack up against a *working* renderer fast.
  - **Tier 2** — a compute-based, tile-binned, analytic-coverage rasterizer
    (Vello/piet-gpu lineage). Resolution-independent AA, massive path counts,
    minimal CPU. The "high performance" endgame.
- Output recording's replay walks the record tree and emits Scene ops; damage
  and incremental redisplay become incremental Scene updates.

This decoupling is the spine of the whole project. Get the Scene API boundary
right and we can (a) bring CLIM up early on Tier 1, (b) swap in Tier 2 with zero
changes above the medium, and (c) keep the renderer independently testable with
golden images.

---

## 3. Locked decisions and their consequences

| Decision | Choice | Consequence we must engineer for |
|---|---|---|
| CLIM strategy | **Clean-room, spec-guided** | The CLIM II spec is normative. McCLIM is used only as a *behavioral oracle* (run the same program on McCLIM and compare) — **not** copied. This avoids LGPL entanglement but means we own every line and the spec's ambiguities. Budget for "read the spec, run the oracle, write tests, implement." |
| Lisp targets | **Broad portability** | All implementation-specific code (threads, timers, FFI quirks, weak tables, finalizers, float traps, main-thread control) lives behind a thin `bifrost.compat` layer. SBCL is the **performance reference**; CCL/ECL/LispWorks are kept green in CI but may trail on perf. We avoid SBCL-only constructs in portable layers. |
| Platforms | **Cross-platform day one** | Surface creation, DPI, IME, clipboard, and event quirks differ per OS. We isolate them behind SDL3 + a per-platform `surface-from-window` shim. CI must cover all three OSes, using software GPU (lavapipe / SwiftShader) for headless golden-image tests. |
| Runtime stack | **SDL3 + wgpu-native** | One windowing/input dependency (SDL3) and one WebGPU dependency (`wgpu-native`, pinned version). Both reached via CFFI. ABI churn in `wgpu-native` is a standing risk → bindings are generated + version-pinned + wrapped. |

**The tension to manage:** *broad portability + cross-platform day one + high
performance* is the single most ambitious combination of the four. The roadmap
mitigates this by making **SBCL-on-Linux the primary development target** for
each phase, then **fanning out** to other Lisps/OSes at phase boundaries via CI
gates rather than blocking day-to-day work.

---

## 4. Layered architecture overview

```
┌──────────────────────────────────────────────────────────────────────┐
│ Applications (clim-demo, a Listener, user apps)                        │
├──────────────────────────────────────────────────────────────────────┤
│ CLIM public API:  CLIM  CLIM-LISP  CLIM-SYS  CLIM-EXTENSIONS           │   spec-facing
├───────────────┬───────────────┬──────────────┬───────────────────────┤
│ frames/panes  │ presentations │ commands     │ formatting             │
│ gadgets/L&F   │ + translators │ + cmd-tables │ (tables/graphs/borders)│   backend-independent
├───────────────┴───────────────┴──────────────┴───────────────────────┤   (clean-room CL,
│ output recording  │ extended output streams │ extended input streams  │    renderer-agnostic,
├───────────────────┴─────────────────────────┴─────────────────────────┤   pure & unit-testable)
│ Silica: sheets · ports · grafts · MEDIUMS · mirrors · events           │
├──────────────────────────────────────────────────────────────────────┤
│ CLIM kernel: geometry (regions+transforms) · designs/inks · styles     │
╞════════════════════════════ Scene API ════════════════════════════════╡   the decoupling seam
│ Render engine:  Tier-1 (tessellate+MSAA)  │  Tier-2 (compute coverage) │
│ glyph atlas · paints · clip masks · layer cache · pixmaps(RTT)         │   GPU-specific
├───────────────────────────────┬───────────────────────────────────────┤
│ bifrost.platform: display-server loop · windows · event pump · DPI     │
├───────────────┬───────────────┴───────────────┬───────────────────────┤
│ ffi.wgpu      │ ffi.sdl3                        │ ffi.text (FT/HarfBuzz)│   CFFI
├───────────────┴────────────────────────────────┴──────────────────────┤
│ wgpu-native (.so/.dylib/.dll) · SDL3 · FreeType · HarfBuzz · stb_image │   native libs
└──────────────────────────────────────────────────────────────────────┘
            bifrost.compat (threads/timers/FFI/main-thread) spans all CL layers
```

**Reading the diagram:** everything *above* the Scene API line is renderer-blind
clean-room Common Lisp — it would run identically on any renderer that
implements the Scene API. Everything *below* is the GPU backend. The medium is
the hinge: it is the lowest CLIM-defined object and the highest thing that knows
about the Scene API.

### Dependency rules (enforced by ASDF system boundaries)
- CLIM kernel and everything above it **must not** reference `ffi.*` or
  `bifrost.platform` directly — only the Scene API and Silica protocols.
- The Scene API is a CLOS protocol (generic functions) with no GPU types in its
  signatures (it speaks points, paths, paints, transforms, glyph runs).
- `bifrost.compat` is the only place with `#+sbcl/#+ccl/...` conditionals in the
  upper layers.

---

## 5. The 2D GPU rendering engine (the hard part)

WebGPU gives us triangles, textures, samplers, compute, and command buffers. It
gives us **no** lines, curves, fills, text, or anti-aliasing. CLIM needs all of
those, anti-aliased, clipped, transformed, and painted with solids, gradients,
patterns, tiles, and stencils. So the renderer is, unavoidably, a small 2D
vector graphics engine. This is the highest-risk component and gets a two-tier
design behind one stable interface.

### 5.1 The Scene API (the interface both tiers implement)
An immediate-mode recording interface, emitted per frame (or per damaged
region) from output-record replay:

```
begin-frame / end-frame (per surface)
push-clip <region|path, rule>          pop-clip
push-transform <affine>                pop-transform
push-layer <opacity|blend|isolate>     pop-layer          ; for compositing/opacity groups
fill-path   <path> <paint> <fill-rule:nonzero|even-odd>
stroke-path <path> <paint> <stroke-style: width caps joins miter dashes>
draw-glyph-run <font-key> <positioned-glyphs> <paint>
draw-image  <texture-handle> <src-rect> <dst-transform> <sampling> <tint>
draw-mask   <coverage-texture> <paint>                    ; for stenciled designs
```

- `path` is a sequence of subpaths of line/quadratic/cubic segments + arcs
  (arcs/ellipses pre-converted to cubics by the kernel).
- `paint` ∈ {solid-color+opacity, linear-gradient, radial-gradient,
  image/tile/pattern, flipping/“xor” → see §5.6}.
- Coordinates are in **device pixels** after the kernel applies CLIM transforms
  (so AA is computed in device space). The transform stack still exists for
  primitives we choose to transform on-GPU (e.g., glyph runs, images).
- The interface is **renderer-agnostic**: it never mentions WGPU types. This is
  what lets Tier 2 replace Tier 1, and what makes a CPU/golden-image reference
  renderer possible for testing.

### 5.2 Tier 1 — tessellation + MSAA (correctness-first)
- **Fills:** flatten curves to polylines (adaptive, error in device space →
  resolution-independent flattening); tessellate interior with a scanline
  trapezoidation honoring nonzero/even-odd winding (robust for self-intersecting
  paths, unlike ear-clipping). Output triangles.
- **Strokes:** expand stroke to a fill (offsetting with round/miter/bevel joins,
  butt/round/square caps, dash application along arc length), then fill. Keeps
  one fill path in the GPU and avoids a separate stroke shader early on.
- **Anti-aliasing:** render to an offscreen **MSAA** target (4× initially, 8×
  configurable), resolve to the surface. Simple, robust, uniform quality across
  primitives and platforms; trivially correct.
- **Clipping:** axis-aligned rect clips → scissor rect (free). General region/
  path clips → stencil buffer (render clip path to stencil, test on subsequent
  draws) or a coverage **mask texture** multiplied into the paint. Nested clips
  → intersection via stencil increment or chained masks.
- **Paints:** solid via uniform; gradients via a small gradient LUT texture +
  per-fragment t; images/patterns/tiles via a bound texture + sampler with
  repeat modes; pattern designs via the mask path.
- **Batching:** group emitted primitives by (pipeline, paint, clip) and coalesce
  into few draw calls; instance repeated primitives (rects, glyph quads). A
  per-frame arena builds vertex/index/instance buffers with one upload.
- **Pixmaps / render-to-texture:** a CLIM pixmap is a WGPU texture used as a
  render target; mediums can target it, and it can be sampled as an image paint
  (this is how `with-output-to-pixmap`, double buffering, and layer caching all
  work).

Tier 1 is deliberately “good enough, obviously correct.” It exists to unblock
the entire CLIM stack and to be the golden-image reference for Tier 2.

### 5.3 Tier 2 — compute coverage rasterizer (performance endgame)
The Vello/piet-gpu approach: encode the whole scene into GPU buffers and rasterize
it with a pipeline of compute passes, computing **analytic coverage** per pixel
(no MSAA, resolution-independent AA, scales to enormous path counts):

1. **Encode** scene → flat GPU buffers (path segments, transforms, paints,
   clips) on the CPU (cheap, no tessellation).
2. **Flatten** curves → line segments on the GPU (compute).
3. **Bin** segments into screen tiles (e.g., 16×16) (compute).
4. **Coarse raster** per tile: build per-tile command lists, resolve clips.
5. **Fine raster** per tile: accumulate signed-area coverage per pixel, apply
   paint, blend. One pass writes final pixels.

Advantages: minimal CPU, near-constant cost in path count, perfect AA, great for
the “scroll a 100k-record Listener” case. It slots in **behind the same Scene
API**, so nothing above the medium changes. We adopt it incrementally
(primitive-by-primitive), keeping Tier 1 as fallback and oracle.

> **De-risking option (explicitly on the table):** rather than write Tier 2 from
> scratch, we *could* bind an existing battle-tested Rust 2D engine (Vello or
> Lyon) through a thin C ABI. That trades “100% native CL rendering” for years of
> saved effort and proven quality. Recommendation: keep it as a **fallback
> renderer behind the Scene API**, decide at the Phase-10 gate based on whether
> the from-scratch Tier 2 is meeting perf/quality targets. The Scene API makes
> this a swap, not a rewrite.

### 5.4 Damage, repaint, and frame scheduling
- **Event-driven by default**: no continuous render loop; we render a surface
  only when its scene is dirty (CLIM `handle-repaint`, geometry change, gadget
  state, blink cursor, etc.). This keeps idle CPU/GPU at zero.
- **Dirty regions**: damage is a region; we re-emit only output records
  overlapping it (`map-over-output-records-overlapping-region`) and render with a
  scissor/clip to the damage. Falls back to full-surface redraw when damage is
  large or tracking is uncertain.
- **Layer/texture caching**: stable subtrees (e.g., a static background, a
  scrolled-away region) cache to a pixmap and re-composite cheaply; scrolling
  becomes blit + redraw of the newly exposed strip.
- **Animation/continuous mode**: an opt-in extension (`CLIM-EXTENSIONS`) drives
  a surface at vsync for apps that want it; presents via `wgpuSurfacePresent`.

### 5.5 Color, blending, gamma, HDR
- Work in linear color with sRGB surface formats (correct AA blending happens in
  linear space). Designs/inks define color in CLIM’s model (RGB/IHS, opacity);
  the kernel converts to linear premultiplied for the renderer.
- Standard src-over alpha blend; opacity groups via `push-layer` (render to a
  temp target, composite with group opacity).

### 5.6 The “flipping ink” / XOR problem
Classic CLIM uses *flipping inks* (XOR) for rubber-banding, drag feedback, and
highlighting. WebGPU core has **no logic-op (XOR) blending**. We do **not**
emulate XOR. Instead:
- Highlight/feedback is drawn on a separate **overlay layer** composited over the
  scene and cheaply removed by re-compositing (no destructive XOR needed,
  because we retain the scene).
- `+flipping-ink+` and `make-flipping-ink` are still provided for API
  conformance; we render them as a high-contrast overlay design whose *visual
  intent* (reversible feedback) is preserved even though the *mechanism* differs.
  This is documented as a conforming, mechanism-level deviation.

---

## 6. The text & font subsystem

Text is a first-class, large subsystem (its own workstream), because CLIM leans
on text heavily (every stream pane, every label, every interactor) and quality
text is what makes a UI feel native.

- **Font loading:** TrueType/OpenType parsing + metrics. Default engine:
  **FreeType** via CFFI (broadest coverage incl. CFF/OTF, hinting, color emoji
  bitmaps). Optional pure-CL path (`zpb-ttf` + `cl-vectors`) for a
  zero-C-dependency build. Pluggable behind a `font-engine` protocol.
- **Shaping:** **HarfBuzz** via CFFI for correct kerning, ligatures, and complex
  scripts; a built-in simple shaper handles Latin when HarfBuzz is absent.
  (CLIM’s text API is per-character-metric simple, but real shaping is what makes
  it look right.)
- **Rasterization + atlas:** glyphs rasterized into a dynamic **glyph atlas**
  texture, drawn as **instanced textured quads** (text is then nearly free).
  Two atlas modes:
  - **Hinted grayscale** for small axis-aligned UI text (pixel-crisp).
  - **MSDF** (multi-channel signed distance field) for scalable, rotated, and
    large text from a single atlas entry (resolution-independent, sharp under
    CLIM transforms).
  A cache keyed by (font, size-bucket, glyph-id, mode) with LRU eviction and
  atlas repacking.
- **CLIM text metrics:** implement `text-size`, `text-style-*` metrics,
  per-character widths, ascent/descent/line-height, so stream line-wrapping,
  cursor positioning, and `formatting-table` column sizing are exact.
- **Text styles → fonts:** the CLIM text-style model (family/face/size, logical
  sizes like `:small`/`:large`) maps to concrete fonts via a configurable
  **text-style mapping** table (with sensible cross-platform default font sets
  bundled or discovered via SDL/fontconfig/system dirs).
- **Internationalization:** Unicode throughout; bidi and emoji are scoped as
  later enhancements (design leaves room: shaping is already segmented by
  script/direction).

---

## 7. FFI strategy: wgpu-native, SDL3, fonts

Three native dependencies, all via **CFFI**, all isolated in `ffi.*` systems and
**never** referenced by the CLIM layers.

### 7.1 Binding generation
- **Generate, don’t hand-maintain, the raw layer.** Use `c2ffi` (via
  `cffi/c2ffi`) to produce raw bindings from `webgpu.h` + `wgpu.h` and the SDL3
  headers. This survives upstream ABI churn (regenerate against a pinned header
  set) and avoids transcription bugs across hundreds of structs/enums.
- **Hand-write the ergonomic wrapper** on top: lispy enums (keywords ↔ C
  enums), struct *builders* (chained `SType` descriptors are verbose in C —
  hide them), `with-*` macros for RAII over GPU/native handles, and
  condition-based error reporting.
- **Pin versions.** `wgpu-native` changes its C ABI between releases; pin an
  exact release, vendor its headers for `c2ffi`, and gate upgrades behind the
  golden-image + smoke suites.

### 7.2 wgpu-native specifics
- **Instance → adapter → device → queue** bring-up; surface creation per
  platform (see §8.3). Configure the surface (swapchain) for the window size +
  preferred sRGB format; reconfigure on resize/DPI change.
- **Async APIs** (`requestAdapter`, `requestDevice`, buffer `mapAsync`) use C
  callbacks → bridged with `cffi:defcallback`; we provide synchronous wrappers
  that pump `wgpuDevicePoll`. Callback userdata lifetimes are GC-pinned to avoid
  use-after-free.
- **Error handling**: install the device **uncaptured-error** callback and use
  **error scopes** around risky operations; surface WGPU validation errors as
  Lisp conditions (invaluable during bring-up).
- **Resource lifetime**: every WGPU object (`Buffer`, `Texture`, `BindGroup`,
  `Pipeline`, …) is wrapped with explicit release; `with-*` macros + finalizers
  prevent leaks. Pools for transient per-frame buffers.

### 7.3 SDL3 & fonts
- **SDL3**: window create/destroy, resize, DPI/scale, the event queue, keyboard
  (with keysyms + scancodes + modifiers), mouse/wheel, text input + **IME**,
  **clipboard**, cursors, and timers. We use SDL3 *only* for windowing/input —
  never for rendering.
- **Native handle plumbing**: `SDL_GetWindowProperties` yields the X11
  `Display*`+`Window`, the Wayland `wl_display`+`wl_surface`, the Win32 `HWND`,
  or the Cocoa `NSWindow`/`CAMetalLayer`; we build the platform-specific
  `WGPUSurfaceDescriptor` chained struct from these.
- **FreeType / HarfBuzz / stb_image (or pngload/cl-jpeg)**: optional CFFI deps
  for fonts and image decoding, behind protocols with pure-CL fallbacks where
  practical.
- **Security / robustness** (house style): env-var-driven library discovery
  (e.g., `BIFROST_WGPU_LIB_DIR`), no hardcoded or world-writable search paths,
  version validation on load, and guarded foreign calls — mirroring Sigyn’s
  hardened `libsapnwrfc` loader.

---

## 8. Windowing, the display server, and the threading model

### 8.1 The constraint that shapes everything
- **macOS requires all windowing/event calls on the process main thread** (Cocoa).
- **A WGPU device is not free-threaded**; access must be externally synchronized.
- SDL event pumping must happen on the thread that owns the windows.

### 8.2 The display-server model
We resolve all three with a single owner: a **display-server loop** on the main
thread that exclusively owns SDL, *all* windows, the WGPU instance/adapter/
device/queue, the glyph atlas, and the renderer. CLIM frames are **clients**:

- Frames run their top-level/command loops in their own threads.
- Clients talk to the server through **lock-free queues**: a *request* channel
  (create window, present scene, set cursor, read clipboard…) and per-client
  *event* channels (translated CLIM input/window events).
- The server is the single point of GPU and OS-window access → no GPU
  multithreading hazards, and macOS’s main-thread rule is satisfied by
  construction.

This is, in effect, a tiny in-process **compositor / display server** — a clean,
modern architecture that also happens to make multi-window CLIM and future
remote/headless rendering natural.

### 8.3 Cross-platform surface creation
A single `make-wgpu-surface (window) → surface` shim with per-OS branches
(X11/Wayland/Win32/Cocoa), each reading SDL3 window properties and assembling
the matching chained surface descriptor. This is the *only* place platform
window internals appear.

### 8.4 Lisp portability of the main thread
`bifrost.compat` provides `run-display-server` that takes over the calling
(main) thread, plus a REPL-friendly trampoline (start the server, interact from
other threads) — accounting for differences in how SBCL/CCL/ECL/LispWorks expose
the main/foreign thread and timers.

---

## 9. CLIM kernel: geometry, designs, styles

Pure, renderer-blind, heavily unit-tested. These are the most spec-mechanical
parts and the easiest to get *provably* right.

- **Regions (`clim.geometry`)**: the region protocol — points, paths, areas;
  standard regions (rectangles, polygons/polylines, ellipses/elliptical arcs,
  lines, point sets); region **set algebra** (union/intersection/difference,
  region-set), `region-contains-*`, `region-intersects-*`, `region-equal`,
  bounding rectangles. Correctness validated against spec invariants
  (idempotence, commutativity, De Morgan on region sets, etc.).
- **Transformations (`clim.geometry`)**: affine transforms — make/compose/invert,
  identity/translation/rotation/scaling/reflection, predicates
  (translation-p, even/odd, rectilinear, singular), and `transform-*` /
  `untransform-*` over points, distances, angles, regions, rectangles. Property
  tests assert algebraic laws (composition associativity, inverse round-trips).
- **Designs & inks (`clim.graphics`)**: the full design protocol — colors (RGB &
  IHS), `+foreground/background/transparent-ink+`, opacity, `compose-over/in/out`,
  patterns, stencils, tiles, indexed/array patterns, gradients (extension), and
  flipping inks (see §5.6). Designs lower to Scene-API paints at draw time.
- **Line & text styles (`clim.graphics`)**: line-style (thickness, joint/cap,
  dashes, unit) and text-style (family/face/size, merging, defaulting,
  device mapping). Drawing options (`with-drawing-options`, ink/line-style/
  clipping/transformation binding).

The **drawing protocol** (`draw-point* … draw-text*`, `draw-design`, the
`draw-*` family with `:filled`, `:ink`, `:line-style`, `:clipping-region`,
`:transformation`) is defined here against an abstract medium; the concrete GPU
medium (in the backend) turns each call into output records and/or Scene ops.

---

## 10. Silica: sheets, ports, grafts, mediums, mirrors, events

The substrate, split into a spec-defined protocol (renderer-blind) and the GPU
realization (the backend).

- **Sheets**: genealogy (parent/children/adopt/disown), geometry (region +
  transformation, `sheet-device-transformation/region`), the input & output
  state mixins, enabling/disabling, repaint protocol (`handle-repaint`,
  `repaint-sheet`, `queue-repaint`), and the standard sheet mixin classes.
- **Ports & grafts**: the abstract port/graft protocol (find-port, port
  properties, graft as screen-root, graft units/DPI, multiple grafts/monitors).
- **Mediums**: `medium` protocol — drawing state (ink, line-style, text-style,
  clipping-region, transformation, `medium-buffering-output-p`), the medium
  drawing methods, `medium-force-output`/`medium-finish-output`, `with-sheet-
  medium`. The **GPU medium** is the translator to the Scene API (§5.1).
- **Mirrors**: the subset of sheets backed by real surfaces. A mirrored sheet ⇒
  an SDL3 window + a WGPU surface managed by the display server. Mirror
  geometry, stacking, native-region/native-transformation, and resize/DPI
  handling live here. (Most sheets are *unmirrored* and composite into their
  mirrored ancestor’s scene — exactly how a GPU compositor wants it.)
- **Events**: the event class hierarchy (device events: pointer button/motion/
  enter/exit, key press/release; window events: configure/repaint/map; timer
  events), the event queue, `process-next-event`, `dispatch-event`,
  `distribute-event`, pointer & keyboard input focus, pointer grabbing, and the
  SDL→CLIM **event translation** table (keysyms, modifiers, wheel, IME/text
  input, HiDPI coordinate scaling).

This phase yields the milestone **“draw into a window via a CLIM medium and
receive CLIM input events.”**

---

## 11. Output recording & extended streams

- **Output records (`clim.recording`)**: the record protocol — bounding
  rectangles, position, parent/children, `add/delete/clear-output-record`,
  `replay`/`replay-output-record`, `map-over-output-records*` (incl. spatial
  queries overlapping a region — *the* hook for damage-driven repaint and Tier-2
  culling), graphics-output-records (one per drawing op) and text-output-records,
  `with-output-recording-options`, `with-new-output-record`,
  `with-output-to-output-record`. A spatially indexed (e.g., R-tree/bucket)
  child store so overlap queries stay fast on huge trees.
- **Extended output streams**: text cursor + pointer cursor, line wrapping, the
  page/viewport abstraction, `stream-write-*`, text margins, `*standard-output*`
  integration, `with-room-for-graphics`, `with-end-of-line/page-action`.
- **Extended input streams**: `read-gesture`/`unread-gesture`, `stream-read-*`,
  pointer tracking (`tracking-pointer`), `with-input-editing`/the input editor
  (emacs-like editing of typed input), `*standard-input*` integration.
- **The recording↔rendering bridge**: replay emits Scene ops; damage replays only
  overlapping records; incremental redisplay (§13) diffs records and patches the
  scene. This is where “CLIM’s display list” and “the GPU’s display list” become
  one thing.

---

## 12. Presentations & commands

The signature CLIM machinery — semantically the heart of CLIM, and one of the
trickiest internals.

- **Presentation type system (`clim.presentations`)**: a type lattice layered
  over CLOS but distinct from it — `define-presentation-type` (with parameters
  and options), `presentation-type-of`, `presentation-subtypep`,
  `presentation-typep`, `with-presentation-type-decoded/options/parameters`, the
  standard presentation types (numbers, strings, sequences, `member`, `or`/`and`,
  `subset`, etc.). Needs a **custom method dispatch** for presentation methods.
- **Presentation methods (`define-presentation-method`)**: a bespoke
  method-combination/dispatch keyed on presentation type *and* the CLOS class of
  arguments — used by `present`, `accept`, `describe-presentation-type`,
  `presentation-typep`, `accept-present-default`, etc. This mini meta-layer is
  built on closer-mop.
- **Present/accept**: `present`/`accept` and their stream forms, default
  handling, the input-context stack (`with-input-context`), and
  `with-output-as-presentation` (tagging output records with a presentation +
  type so the pointer can pick them).
- **Translators**: `define-presentation-translator`,
  `define-presentation-action`, `define-drag-and-drop-translator`,
  translator matching against the input context, gesture-driven invocation, and
  pointer-sensitive highlighting (which uses the overlay layer from §5.6).
- **Commands (`clim.commands`)**: `define-command`, command tables
  (inheritance, menus, keystroke accelerators, `add/remove-command*`), command
  accessibility, the command-line / pointer / menu **command processors**, and
  `read-command`/`execute-frame-command`. Commands and presentations interlock:
  presentation translators produce commands; the command loop reads gestures via
  the extended input stream.

---

## 13. Frames, panes, layout, gadgets, look-and-feel

- **Application frames (`clim.frames`)**: `define-application-frame` (slots,
  panes, layouts, command-table, menu/pointer-doc/disabled-commands),
  `make-application-frame`, `run-frame-top-level` /
  `default-frame-top-level`, the frame state machine, `frame-exit`,
  `redisplay-frame-panes`, `*application-frame*`, frame ↔ port/graft binding,
  and the **frame manager** (adopts frames, applies look-and-feel).
- **Layout protocol & panes (`clim.frames`)**: the space-requirement /
  composition protocol (`compose-space`, `allocate-space`,
  `change-space-requirements`, `space-requirement` arithmetic) and the composite
  panes — `vbox`/`hbox`, `table`/`grid`, `spacing`, `outlining`, `bboard`,
  `restraining`, `scrolling`/viewport, `labelling`, plus fixed/relative sizing.
  The interaction panes: `application-pane`, `interactor-pane`,
  `command-menu-pane`, `title-pane`, `pointer-documentation-pane`,
  `accept-values-pane`.
- **Gadgets (`clim.gadgets`)**: because there are **no native widgets**, *every*
  gadget is drawn by us on the GPU. The gadget protocol (value,
  value-changed/activate callbacks, armed/disarmed, client/id, `gadget-active-p`)
  plus the full standard set: push-button, toggle-button, radio/check boxes,
  slider, scroll-bar, text-field, text-editor, label, list-pane, option-pane,
  menu-bar, separator, (and extensions: tab-layout, tree, progress). Each gadget
  is a sheet that renders via the medium/Scene API and consumes CLIM input
  events.
- **Look-and-feel / theming**: since we own pixels, ship a modern, DPI-aware
  theme system (light/dark, tunable metrics/colors, crisp at any scale) as the
  default frame manager’s realization. This is a *feature* of GPU-only: identical,
  controllable appearance on every OS.
- **Formatting (`clim.formatting`)**: `formatting-table`/`-row`/`-cell`/
  `-column`, `formatting-graph`/`-node`, `surrounding-output-with-border`,
  `indenting-output`, `filling-output` — built on output recording.
- **Incremental redisplay**: `updating-output` / `redisplay` — unique IDs +
  cache values on output records, diff old vs new on redisplay, and patch only
  changed records → minimal Scene updates. This is what makes a CLIM table or
  inspector update a single cell without redrawing the world, and it maps
  perfectly onto dirty-region GPU repaint.
- **Dialogs & menus**: `menu-choose`, `accepting-values` (the dialog DSL built on
  presentations + incremental redisplay), `notify-user`, `select-file`.

---

## 14. Module & package map

ASDF-system-per-module (Sigyn house style), reverse-DNS package names. Public
CLIM packages keep their **spec-mandated names** so conformant code runs
unchanged; internal packages live under a project prefix.

| ASDF system | Package(s) | Responsibility |
|---|---|---|
| `bifrost.compat` | `bifrost.compat` | Per-Lisp threads/timers/FFI/main-thread/weak-tables shims |
| `bifrost.ffi.wgpu` | `bifrost.ffi.wgpu(.raw)` | Generated + wrapped wgpu-native bindings |
| `bifrost.ffi.sdl3` | `bifrost.ffi.sdl3(.raw)` | SDL3 windowing/input bindings |
| `bifrost.ffi.text` | `bifrost.ffi.text` | FreeType/HarfBuzz/image bindings (optional) |
| `bifrost.render` | `bifrost.render`, `bifrost.scene` | Scene API + Tier-1/Tier-2 renderers, paints, clip masks, glyph atlas, pixmaps, layer cache |
| `bifrost.platform` | `bifrost.platform` | Display-server loop, windows, surface creation, event pump, DPI |
| `clim.geometry` | `clim` (regions/transforms) | Region algebra + affine transforms |
| `clim.graphics` | `clim` (designs/styles/drawing) | Designs/inks, line/text styles, drawing protocol |
| `clim.silica` | `clim`, `clim-silica` | Sheets, ports, grafts, mediums, mirrors, events |
| `clim.recording` | `clim` | Output records + extended I/O streams |
| `clim.presentations` | `clim` | Presentation types, methods, translators, accept/present |
| `clim.commands` | `clim` | Commands, command tables, command processors |
| `clim.frames` | `clim` | Frames, panes, layout protocol, redisplay |
| `clim.gadgets` | `clim` | Gadgets + theming/look-and-feel |
| `clim.formatting` | `clim` | Tables, graphs, borders, indenting, filling |
| `clim` (umbrella) | `clim`, `clim-lisp`, `clim-sys`, `clim-extensions` | Public spec API surface |
| `bifrost.backend` | `bifrost.backend` | Wires Silica medium/mirror/port to `bifrost.render` + `bifrost.platform` (**the only backend**) |
| `clim.demo` | `clim-demo` | Demos, the Listener, integration tests |

> **Naming note:** `bifrost` is a placeholder codename (a “rainbow bridge” from
> CL to the GPU). Final naming, and whether to publish under a reverse-DNS root
> like `net.goenninger.<name>`, is the user’s call.

---

## 15. Cross-cutting concerns

- **Concurrency & safety**: the display-server-owns-the-GPU model (§8) is the
  primary safety mechanism. Above it, frames are isolated; the event/command
  queues are the only shared mutable state, guarded and lock-free where hot.
- **Error model**: WGPU validation/uncaptured errors → Lisp conditions; FFI
  boundary guards; never let a foreign error corrupt the image silently. A
  restart-rich condition system for app-level CLIM errors (consistent with how
  CLIM apps expect a debugger pane / `notify-user`).
- **Resource lifetime**: `with-*` macros + finalizers for every GPU/native
  handle; per-frame arenas for transient buffers; explicit atlas/texture
  eviction; leak tests in CI.
- **Security/robustness** (Sigyn ethos): env-var lib discovery, no
  world-writable search paths, version pinning/validation, careful pointer
  lifetime management, ASAN/valgrind on the C boundary in CI.
- **Determinism & testing**: a CPU reference renderer behind the Scene API +
  golden-image diffing make rendering testable without a GPU; McCLIM as a
  behavioral oracle for the upper layers.
- **Documentation**: the spec mapping (which symbols, which section, conformance
  notes/deviations like §5.6) maintained alongside the code.

---

## 16. Open questions

1. **Project name & package root** — keep `bifrost`, or a reverse-DNS root?
2. **Font dependency posture** — FreeType/HarfBuzz (CFFI, best quality) as
   default vs. pure-CL (`zpb-ttf`+`cl-vectors`) default for a no-C-deps build?
3. **Tier-2 build vs. borrow** — commit to a from-scratch compute rasterizer, or
   pre-plan the Vello/Lyon-via-C fallback as the perf path? (Decide at Phase-10
   gate; Scene API makes it swappable either way.)
4. **CLIM-EXTENSIONS scope** — which de-facto extensions (tab-layout, gradients,
   raster images, drag-and-drop, bezier curves, threads) to include in v1?
5. **Conformance bar for v1** — define the “CLIM core profile” subset that the
   first usable release must pass (see ROADMAP Phase exit criteria).
6. **Headless/remote** — is server-side/headless rendering (offscreen → image)
   an early requirement (it’s nearly free given the display-server model), or
   strictly later?
