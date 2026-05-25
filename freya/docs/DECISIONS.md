# Freya — Architecture Decision Records

A living log of significant decisions. Each ADR is short: context, the decision,
and consequences. Status ∈ {Accepted, Open, Superseded}.

| ADR | Topic | Status |
|---|---|---|
| [0001](#adr-0001--foundational-direction) | Foundational direction | Accepted |
| [0002](#adr-0002--project-name--package-root) | Project name & package root | Accepted |
| [0003](#adr-0003--font-dependency-posture) | Font dependency posture | Open |
| [0004](#adr-0004--tier-2-renderer-build-vs-borrow) | Tier-2 renderer: build vs. borrow | Open |
| [0005](#adr-0005--clim-extensions-scope-for-v1) | CLIM-EXTENSIONS scope for v1 | Open |
| [0006](#adr-0006--v1-conformance-bar-the-clim-core-profile) | v1 conformance bar | Open |
| [0007](#adr-0007--headlessremote-rendering-timing) | Headless/remote rendering timing | Open |
| [0008](#adr-0008--project-license) | Project license | Open |

---

## ADR-0001 — Foundational direction
**Status:** Accepted.

**Context.** Building a full CLIM 2 with a GPU-only backend admits several
high-level strategies that reshape the whole effort.

**Decision.**
- **CLIM strategy:** clean-room, **spec-guided**. The CLIM II specification is
  normative; McCLIM is used only as a *behavioral oracle* (run the same program
  and compare), never copied.
- **Lisp targets:** **broad portability** (SBCL, CCL, ECL, LispWorks, …), with
  **SBCL as the performance reference**. Per-Lisp differences are isolated in
  `…/compat`.
- **Platforms:** **cross-platform from day one** — Linux (X11+Wayland), macOS
  (Metal), Windows (D3D12/Vulkan).
- **Runtime stack:** **SDL3** (windowing/input/IME/clipboard/HiDPI) **+
  wgpu-native** (WebGPU C ABI), both via CFFI.

**Consequences.** Maximum ambition combination; mitigated by developing each
phase SBCL-on-Linux first, then fanning out via CI at phase gates. See
`PLAN.md` §3 and `ROADMAP.md`.

---

## ADR-0002 — Project name & package root
**Status:** Accepted.

**Context.** The name gates directory, ASDF system, and package naming.

**Decision.** The project is **Freya** (slug `freya`). Internal packages and
ASDF systems use the **reverse-DNS root `net.goenninger.freya`** (one primary
system + `net.goenninger.freya/<module>` secondaries). The public CLIM packages
keep their spec-mandated names (`clim`, `clim-lisp`, `clim-sys`,
`clim-extensions`).

**Consequences.** Collision-proof, matches the house style; apps see a
spec-conformant `clim` package. Codename references in the docs were renamed
accordingly.

---

## ADR-0003 — Font dependency posture
**Status:** Open.

**Context.** Text quality vs. dependency footprint. Options: (a) **FreeType +
HarfBuzz** via CFFI as the default — best coverage, hinting, shaping, color
emoji; (b) **pure-CL** default (`zpb-ttf` + `cl-vectors`) — zero C font deps,
weaker shaping/coverage; (c) **both**, default pure-CL with FreeType/HarfBuzz
opt-in (or vice-versa). Affects `…/ffi-text` deps and the `font-engine` default.

**Decision.** _Pending (decision walk-through)._

---

## ADR-0004 — Tier-2 renderer: build vs. borrow
**Status:** Open.

**Context.** The high-performance renderer (compute-coverage rasterizer) is the
biggest technical risk. Options: (a) **build** a from-scratch Vello/piet-gpu-style
rasterizer in CL+WGSL — fully native, highest effort; (b) **borrow** by binding
an existing Rust engine (Vello/Lyon) through a thin C ABI — proven, far less
effort, adds a Rust artifact; (c) **defer/decide at the Phase-10 gate** based on
whether the Scene-API Tier-1 perf is insufficient. The Scene API makes either a
drop-in.

**Decision.** _Pending (decision walk-through)._

---

## ADR-0005 — CLIM-EXTENSIONS scope for v1
**Status:** Open.

**Context.** Beyond the spec, real CLIM apps rely on de-facto extensions.
Candidates: tab-layout, gradients, raster images / `draw-image`, bezier curves,
drag-and-drop translators, pointer-documentation niceties, thread/clim-sys
helpers, 24-bit color/opacity everywhere, rubber-banding helpers.

**Decision.** _Pending (decision walk-through)._

---

## ADR-0006 — v1 conformance bar (the "CLIM core profile")
**Status:** Open.

**Context.** Full CLIM 2 is enormous; we need a precise, testable subset that
the first usable release (ROADMAP Phase 7 gate) must pass, and a definition of
"done" for v1.

**Decision.** _Pending (decision walk-through)._

---

## ADR-0007 — Headless/remote rendering timing
**Status:** Open.

**Context.** The display-server model makes offscreen rendering (scene → image,
no window) nearly free, which is valuable for CI golden images and potential
server-side/remote use. Question: is headless an **early** first-class target,
or a later nicety?

**Decision.** _Pending (decision walk-through)._

---

## ADR-0008 — Project license
**Status:** Open.

**Context.** The repo ships a **provisional proprietary** `LICENSE` (the Sigyn
house default). A CLIM implementation intended for reuse might warrant an
OSI-approved license (e.g., MIT/BSD/Apache-2.0/LGPL); a commercial product might
not. Note runtime deps carry their own licenses (wgpu-native: MIT/Apache-2.0;
SDL3: zlib; FreeType: FTL/GPL; HarfBuzz: MIT).

**Decision.** _Pending — confirm intended license._
