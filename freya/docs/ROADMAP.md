# Freya — Execution Roadmap

Phased plan for building a clean-room **CLIM 2** with a **GPU-only WebGPU
backend** (`wgpu-native` + SDL3). Companion to [`PLAN.md`](PLAN.md) (architecture
& design).

> **Sequencing principle.** Each phase is developed **SBCL-on-Linux first**
> (fastest iteration), then **fanned out** to other Lisps (CCL/ECL/LispWorks)
> and OSes (macOS/Windows) at the phase’s exit gate via CI — rather than
> blocking daily work on all-platform parity. The **Scene API seam** lets the
> renderer and the CLIM stack mature in parallel.

---

## How to read the estimates

Effort is in **engineer-months (EM)** for a *small team of experienced CL +
graphics engineers*, with wide ranges because (a) clean-room CLIM means
spec-archaeology and (b) a GPU 2D engine is genuinely research-adjacent. Rough
totals:

- **Usable “CLIM core profile” demo:** ~**9–15 EM** (Phases 0–7, core subset).
- **Broad CLIM 2 conformance + Tier-2 performance:** ~**60–180 EM**
  (5–15 engineer-years), comparable in scale to mature CLIMs which accreted over
  decades. Treat the later phases as a *program*, not a sprint.

These are planning figures to set expectations, **not** commitments.

---

## Dependency graph between phases

```
P0 Foundations ─┬─> P1 Render Tier-1 ─┐
                │                      ├─> P4 Silica/medium ─> P5 Recording ─> P6 Presentations/commands ─> P7 Frames/panes ─> P8 Gadgets ─> P9 Formatting/redisplay ─> P11 Apps/polish
                ├─> P2 Text           ─┘                                                                                         │
                └─> P3 Kernel (geometry/designs/styles) ───────────────────────┘                                  P10 Performance (Tier-2) runs alongside P7→P11
```

P3 (kernel) is pure and can be built in parallel with P1/P2. P10 (Tier-2
renderer) is an independent track gated late, swappable behind the Scene API.

---

## Phase 0 — Foundations & de-risking spikes
**Goal:** prove the whole native stack end-to-end on all three OSes before
building anything tall on it.

- CFFI **binding-generation pipeline** (`c2ffi`) for `wgpu-native` + SDL3;
  pin versions; vendor headers; ergonomic wrapper skeleton.
- SDL3 window + **wgpu-native** bring-up: instance→adapter→device→queue,
  cross-platform **surface creation** (X11/Wayland/Win32/Cocoa), clear + a
  textured triangle, present.
- **Display-server / main-thread** skeleton (§8 of PLAN): main-thread loop owns
  GPU + windows; a client thread posts a “draw” request and gets events back.
- `freya.compat` v0 (threads/timers/main-thread per Lisp).
- **CI** with headless GPU: lavapipe (Linux), SwiftShader/Dawn (where needed),
  on Linux+macOS+Windows; first golden-image harness.

**Exit gate:** a triangle renders and presents, identically, on SBCL across
Linux(X11+Wayland)/macOS/Windows, plus on CCL/ECL on Linux; CI golden-image diff
green; resize + DPI change handled.

**Risk burned down:** “can we even drive wgpu-native from CL cross-platform with
correct surface creation and the macOS main-thread rule?” — the project’s #1
existential question.

---

## Phase 1 — Render engine, Tier 1
**Goal:** a correct, batched, MSAA 2D renderer behind the **Scene API**.

- Define the **Scene API** (PLAN §5.1) + a CPU **reference renderer** for golden
  tests.
- Fills: adaptive curve flattening; scanline trapezoidation; nonzero/even-odd.
- Strokes: stroke-to-fill expansion (caps/joins/miter/dashes).
- Anti-aliasing via MSAA offscreen + resolve.
- Clipping: scissor (rect) + stencil/mask (general).
- Paints: solid, linear/radial gradient, image/tile/pattern.
- Batching/instancing; per-frame arena buffers.
- **Pixmaps / render-to-texture**; layer compositing/opacity groups.

**Exit gate:** golden-image suite (primitives × paints × clips × transforms)
passes on all CI targets within perceptual tolerance; throughput baseline
recorded (rects/lines/glyph-quads per second).

---

## Phase 2 — Text & font subsystem
**Goal:** crisp, fast, measurable text.

- `font-engine` protocol; **FreeType** default loader (+ pure-CL fallback).
- **HarfBuzz** shaping (+ simple Latin shaper fallback).
- **Glyph atlas**: hinted-grayscale and **MSDF** modes; LRU + repack.
- Instanced glyph-run rendering via the Scene API.
- CLIM **text metrics** (`text-size`, ascent/descent/line-height, per-char
  widths) — exact enough for layout/cursoring/table sizing.
- Text-style → font mapping with bundled/discovered default font sets.

**Exit gate:** text golden images stable across platforms; metrics match
reference within tolerance; large-paragraph render is GPU-cheap (instanced).

---

## Phase 3 — CLIM kernel (parallel with P1–P2)
**Goal:** the pure, provable core.

- **Regions**: full region + region-set algebra, containment/intersection,
  bounding rects.
- **Transformations**: full affine protocol + predicates + transform/untransform.
- **Designs & inks**: colors (RGB/IHS), opacity, compositing, patterns/stencils/
  tiles, gradients, flipping inks (as overlay; PLAN §5.6).
- **Line & text styles**; drawing-options binding.

**Exit gate:** property-based tests assert spec algebraic laws; designs lower to
Scene-API paints; 100% of kernel symbols implemented + documented.

---

## Phase 4 — Silica (sheets/ports/grafts/mediums/mirrors/events)
**Goal:** the milestone **“draw into a real window via a CLIM medium and receive
CLIM input events.”**

- Sheet genealogy/geometry/enabling/repaint protocol.
- Port/graft (multi-monitor, DPI/graft units).
- **GPU medium** = Scene-API translator (the hinge); drawing state; force/finish.
- **Mirrors** = SDL window + WGPU surface via the display server; resize/DPI.
- **Events**: class hierarchy, queue, dispatch/distribute, focus, grabbing, and
  the **SDL→CLIM translation** table (keysyms/modifiers/wheel/IME/HiDPI).

**Exit gate:** a hand-built sheet hierarchy draws shapes/text in a window,
resizes correctly, and reports translated pointer/keyboard events.

---

## Phase 5 — Output recording & extended streams
**Goal:** retained, replayable, damage-driven output + stream I/O.

- Output-record protocol; graphics/text records; spatially-indexed children;
  `replay`, `map-over-output-records-overlapping-region`.
- Extended **output** streams (cursor, wrapping, viewport/page).
- Extended **input** streams (`read-gesture`, `tracking-pointer`, input editor).
- **Damage→replay→Scene** bridge; dirty-region repaint.

**Exit gate:** a scrollable text/graphics pane records, replays, and repaints
only damaged regions; input editor handles emacs-style line editing.

---

## Phase 6 — Presentations & commands
**Goal:** CLIM’s semantic heart.

- Presentation **type lattice** + `subtypep`/`typep` + standard types.
- Presentation **method dispatch** (closer-mop mini meta-layer).
- `present`/`accept`, input contexts, `with-output-as-presentation`.
- **Translators** (incl. drag-and-drop), pointer-sensitive highlighting (overlay).
- **Commands** + command tables (inheritance/menus/accelerators) + the three
  command processors; `read-command`/`execute-frame-command`.

**Exit gate:** a console-style interactor where typed and pointer gestures both
produce commands; clicking presented objects invokes translators with correct
highlighting.

---

## Phase 7 — Frames, panes, layout
**Goal:** real applications.

- `define-application-frame`, frame state machine, top-level/command loop,
  frame manager.
- **Layout protocol** (`compose-space`/`allocate-space`/space-requirements) +
  composite panes (vbox/hbox/table/grid/spacing/outlining/scrolling/labelling).
- Interaction panes (application/interactor/command-menu/title/pointer-doc).

**Exit gate (the big one — “CLIM core profile” demo):** a multi-pane application
frame with menus, a scrolling interactor, and presentation-driven commands runs
on SBCL across all three OSes.

---

## Phase 8 — Gadgets & look-and-feel
**Goal:** a complete, GPU-drawn widget set.

- Gadget protocol + full standard set (buttons/toggles/radio/check/slider/
  scroll-bar/text-field/text-editor/label/list/option/menu-bar).
- **Theming** (light/dark, DPI-aware) as the default frame manager realization.
- Dialogs/menus: `menu-choose`, `accepting-values`, `notify-user`, file select.

**Exit gate:** `accepting-values` dialogs and all gadgets work, themed and crisp
at fractional DPI scales.

---

## Phase 9 — Formatting & incremental redisplay
**Goal:** the productivity features.

- `formatting-table`/`-graph`, borders, indenting, filling.
- `updating-output`/`redisplay` incremental diffing → minimal Scene patches.

**Exit gate:** an inspector-style app updates single cells without full redraw;
incremental redisplay measurably beats full replay on a large table.

---

## Phase 10 — Performance (parallel track, gated late)
**Goal:** hit the high-performance targets.

- Tier-2 **compute coverage rasterizer** (encode→flatten→bin→coarse→fine),
  adopted primitive-by-primitive behind the Scene API; Tier-1 stays as fallback
  + oracle.
- **Decision gate:** from-scratch Tier-2 vs. binding Vello/Lyon-via-C (PLAN
  §5.3) based on measured perf/quality.
- Dirty-region + **layer/texture caching**; smooth scrolling via blit + strip
  redraw; instancing everywhere; per-frame allocation elimination.
- Profiling + the benchmark suite (below).

**Exit gate:** performance targets (below) met on reference hardware.

---

## Phase 11 — Applications, conformance & polish
**Goal:** prove it and harden it.

- Port `clim-demo` equivalents + a **Listener**; use them as integration tests.
- Full conformance pass vs. spec; document deviations (e.g., flipping ink).
- Cross-platform/cross-Lisp hardening; leak/ASAN/valgrind sweeps.
- Docs: user guide, spec-mapping, extension catalog. Accessibility groundwork.

**Exit gate:** the demos + Listener run on the full platform/Lisp matrix; CI all
green; conformance report published.

---

## Performance targets (validated in Phase 10)

| Scenario | Target |
|---|---|
| Idle UI | 0% CPU/GPU (event-driven; no continuous loop) |
| Interactive redraw | ≥ 60 fps; input→present latency < 16 ms |
| Incremental edit (one cell/line via `updating-output`) | < 1 ms scene patch |
| Scroll a 100k-record Listener | smooth 60 fps via dirty-region + layer cache |
| Live presentations on screen | thousands without lag (Tier-2 culling/binning) |
| Text | instanced glyph quads; whole paragraphs sub-ms after atlas warm |
| Startup (cold) | window + first frame in well under a second |

---

## Testing & conformance strategy

- **Unit / property tests** (kernel): region & transform algebraic laws,
  design/color math, presentation `subtypep`/`typep` against spec examples.
- **Golden-image tests**: Scene-API primitives rendered by Tier-1, Tier-2, and
  the CPU reference renderer, perceptually diffed; run headless in CI via
  lavapipe/SwiftShader on all OSes. Guards AA quality and cross-platform parity.
- **Behavioral oracle (McCLIM)**: run the *same* CLIM program on McCLIM and on
  Freya; compare output-record structure and rendered images. Used for
  validation only — **no code copied** (clean-room).
- **Integration**: `clim-demo` + Listener as living regression tests.
- **FFI hardening**: ASAN on the C boundary, valgrind for leaks, fuzzing the
  binding wrappers.
- **Matrix CI**: {SBCL, CCL, ECL, LispWorks?} × {Linux X11, Linux Wayland,
  macOS, Windows}, with the full matrix gated at phase exits and a fast
  SBCL-Linux subset on every commit.

---

## Top risks & mitigations

| Risk | Severity | Mitigation |
|---|---|---|
| **2D GPU vector engine is a mini-Skia/Vello** (biggest technical risk) | High | Tier-1 first for correctness; Tier-2 gated late behind the Scene API; **Vello/Lyon-via-C fallback** pre-planned as the swap-in perf path |
| **wgpu-native ABI churn** | Med-High | Pin versions, vendor headers, regenerate bindings, gate upgrades on golden+smoke suites |
| **macOS main-thread / GPU threading** | Med-High | Display-server model owns GPU+windows on the main thread by construction (PLAN §8) |
| **Presentation type system complexity** | Med | closer-mop mini meta-layer; McCLIM as behavioral oracle; spec-example test corpus |
| **Scope (full CLIM 2 is enormous)** | High | “CLIM core profile” first (Phase-7 gate); conformance-driven phase expansion; honest EM ranges |
| **Broad-portability ⨯ high-perf ⨯ cross-platform tension** | High | SBCL-Linux as perf reference; `freya.compat` isolates Lisp diffs; CI fan-out at gates, not daily |
| **Font correctness (shaping/bidi/emoji)** | Med | FreeType+HarfBuzz defaults; bidi/emoji scoped as later enhancements with room left in the design |
| **Clean-room IP discipline** | Med | Spec is normative; McCLIM only *run* as oracle, never transcribed; provenance noted in docs |

---

## Immediate next actions (if/when we start building)

1. Resolve [PLAN §16 open questions](PLAN.md#16-open-questions) (name, font
   posture, Tier-2 build-vs-borrow, extension scope, v1 conformance bar,
   headless requirement).
2. Stand up the repo skeleton: ASDF systems from the [module map](PLAN.md#14-module--package-map),
   `freya.compat` v0, CI scaffold.
3. Execute **Phase 0** as a hard go/no-go spike — it burns down the project’s
   single biggest existential risk (cross-platform wgpu-native from CL).
