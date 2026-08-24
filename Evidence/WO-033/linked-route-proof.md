# WO-033 linked-route proof

## Pre-build source/configuration proof

- Execution branch: `codex/wo33-blend-state-transition`
- Investigation continuation: `164abe4ba2becf46ea043811963ac28195d29bcd`
- Accepted product baseline remains `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27`.
- `scripts/build-ios.sh` configures the production OpenMW graph with `-DOPENMW_GL4ES_MANUAL_INIT=ON` and bundled OSG (`OPENMW_USE_SYSTEM_OSG=OFF`).
- Pinned OpenMW CMake declares `OPENMW_GL4ES_MANUAL_INIT` and calls global `add_compile_definitions(OPENMW_GL4ES_MANUAL_INIT)` before the bundled OSG `FetchContent` graph is materialized.
- The pinned OSG patch applies the Apple/manual-init route to `State::applyMode`, `State::applyModeOnTexUnit`, ordinary `BlendFunc::apply`, and `GLExtensions` lookup.
- The WO-033 OSG diagnostic additions reconstruct exactly against pinned OSG `01cc2b585c8456a4ff843066b7e1a8715558289f` in the local deterministic patch model.
- Local source inspection established the intended GL4ES patch locations, but the production bootstrap gate proved that patch 0009 was not hermetic against the preceding production patch stack: its `enable.c` and `listdraw.c` contexts did not apply.

This proves configuration and intended source inclusion, but not linked retention or runtime exercise.

## Exact linked-product proof

Not obtained. Fast run `32701930506` stopped during patch bootstrap before compilation. No executable exists to inspect for the manual-route marker or `openmw_ios_renderer_diag_blend_event` retention/resolution.

## Runtime exercise proof

Not obtained. No installable candidate was produced, so source presence is explicitly not treated as proof of runtime exercise.
