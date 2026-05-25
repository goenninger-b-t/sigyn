# Freya

> **A clean-room, high-performance Common Lisp implementation of the CLIM 2
> specification with a GPU-only WebGPU backend** (`wgpu-native` + SDL3).
>
> Named for the Norse goddess Freyja. Slug: `freya`. Package root:
> `net.goenninger.freya`.

**Status:** early scaffolding. The architecture and roadmap are designed
(`docs/`); the source tree is a package/system skeleton. No runtime
functionality yet — see `docs/ROADMAP.md` for the phase plan.

---

## What Freya is

Freya draws *every pixel itself on the GPU*: no X11/GDI/Quartz drawing
primitives, no native OS widgets, no CPU rasterizer in the hot path. It aims to
be a faithful, conformant CLIM 2 — so existing CLIM programs run — while the UI
is crisp at any DPI, smoothly animated, and identical across Linux, macOS, and
Windows because Freya owns the rendering.

The central design idea is a **Scene API** seam between CLIM's `medium` and the
GPU: everything above it is renderer-blind clean-room Common Lisp; everything
below it is the GPU backend (a small 2D vector + text engine on WebGPU). See
[`docs/PLAN.md`](docs/PLAN.md).

## Foundational decisions

| Topic | Choice | ADR |
|---|---|---|
| CLIM strategy | Clean-room, spec-guided (McCLIM as oracle only) | ADR-0001 |
| Lisp targets | Broad portability; **AllegroCL** is the target (SBCL = dev/CI) | ADR-0001/0011 |
| Platforms | Cross-platform day one (Linux/macOS/Windows) | ADR-0001 |
| Runtime stack | SDL3 + wgpu-native | ADR-0001 |
| Name & packages | **Freya** / `net.goenninger.freya.*` | ADR-0002 |
| Fonts | FreeType + HarfBuzz default (pure-CL fallback) | ADR-0003 |
| Tier-2 renderer | Built from scratch (CL + WGSL compute) | ADR-0004 |
| Extensions (v1) | Images, gradients, beziers, drag-and-drop, tab-layout, clim-sys/clime | ADR-0005 |
| v1 bar | **Full** CLIM 2 conformance (Phases 0–11) | ADR-0006 |
| Headless / remote | Both first-class; headless early, remote parallel track | ADR-0007 |
| License | MIT | ADR-0008 |
| Type & perf discipline | Typed everywhere · hot-path inlined · compile-time checks, zero runtime cost | ADR-0009 |
| Observability | Built-in Prometheus telemetry (zero-cost when off) | ADR-0010 |

Full, living decision log: [`docs/DECISIONS.md`](docs/DECISIONS.md).

## Repository layout

```
net.goenninger.freya.asd     One primary system + secondary systems (…/render, …/silica, …)
src/
  compat/                    Per-Lisp shims + shared optimize policy / type-decl helpers
  telemetry/                 Built-in Prometheus metrics (zero-cost when compiled out)
  ffi/{wgpu,sdl3,text}/      CFFI bindings (generated + ergonomic wrappers)
  render/                    Scene API + Tier-1/Tier-2 renderers, glyph atlas, paints
  platform/                  Display-server loop, windows, surfaces, event pump
  clim/
    geometry/ graphics/      CLIM kernel: regions+transforms, designs/inks, styles
    silica/                  Sheets, ports, grafts, mediums, mirrors, events
    recording/               Output records + extended I/O streams
    presentations/           Presentation types, methods, translators, accept/present
    commands/                Commands + command tables + processors
    frames/                  Frames, panes, layout protocol, redisplay
    gadgets/                 GPU-drawn gadgets + theming
    formatting/              Tables, graphs, borders, indenting, filling
    public/                  Public CLIM packages (clim, clim-lisp, clim-sys, clim-extensions)
  backend/                   The (only) backend: wires Silica → render + platform
  remote/                    Headless offscreen + remote/streaming transport
demo/                        Demos, a Listener (integration tests)
tests/                       Unit / property / golden-image / conformance tests
docs/                        PLAN.md, ROADMAP.md, DECISIONS.md
.github/workflows/           CI (activates once this is its own repo root)
```

## Building (once implementation begins)

Native prerequisites (planned): `wgpu-native` (pinned), `SDL3`, and optionally
`FreeType`/`HarfBuzz`. Foreign libraries are discovered via environment
variables (no hardcoded/world-writable paths), e.g. `FREYA_WGPU_LIB_DIR`,
`FREYA_SDL3_LIB_DIR`.

```lisp
(asdf:load-system "net.goenninger.freya")   ; loads CLIM + the GPU backend
(asdf:test-system "net.goenninger.freya")   ; runs the test suite
```

Two build profiles are selected by feature (ADR-0009 / PLAN §17): *checked*
(`safety 3`, full runtime + compile-time type checks — used for tests/CI) and
*release* (`speed 3` / `safety 0` in hot modules — compile-time-verified types,
**zero runtime type-check cost**). Built-in Prometheus telemetry (ADR-0010) is
enabled by adding `:freya-telemetry` to `*features*` and compiles to nothing
otherwise.

> Today these systems only define packages (skeleton). They will fail to load
> until the external Lisp dependencies are present and the modules are filled in.

## This repo currently lives inside `sigyn`

Freya is an **independent project** (unrelated to Sigyn's SAP NetWeaver RFC
code). For now it incubates under `freya/` on a branch of the `sigyn`
repository, because that is the only remote this environment can push to. To
lift it into its own repository, preserving history:

```sh
# from a clone of the sigyn repo, on the freya branch:
git subtree split --prefix=freya -b freya-standalone
mkdir ../freya && cd ../freya && git init
git pull ../sigyn freya-standalone
git remote add origin git@github.com:<you>/freya.git
git push -u origin main
```

(Then the `.github/workflows/` here becomes active at the new repo root.)

## License

**MIT** — see [`LICENSE`](LICENSE) (ADR-0008). Third-party runtime dependencies
remain under their own licenses (wgpu-native, SDL3, FreeType, HarfBuzz).
