# Vendored pinned C headers

These headers are committed to the repo so binding generation
(`scripts/gen-bindings.sh`) is reproducible without network access. The matching
shared library is **not** vendored — it is provided by the user via the
`FREYA_*_LIB_DIR` environment variables (PLAN §7, Sigyn ethos).

## wgpu-native — pinned to `v25.0.2.1`

Source:
- `webgpu.h`, `wgpu.h` extracted from
  https://github.com/gfx-rs/wgpu-native/releases/download/v25.0.2.1/wgpu-linux-x86_64-release.zip
  (path `include/webgpu/*.h` inside the archive)

Keep `+pinned-version+` in `src/ffi/wgpu/library.lisp` in sync with the tag here.
Refresh with `scripts/vendor-headers.sh`.

## SDL3 — TODO

SDL3 has a large header set across many files; vendoring is deferred until the
ergonomic SDL3 wrapper begins. For now the loader uses the system's installed
SDL3 (discovered via `FREYA_SDL3_LIB_DIR`).

## FreeType / HarfBuzz — TODO (Phase 2)

Same as SDL3 — header vendoring deferred until the font subsystem (Phase 2).
