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

Amendment 1 replacement run `32723328194` strengthened the source-side proof:

- The production macOS validation reconstructed pristine pinned OpenMW and GL4ES snapshots.
- All OpenMW patches 0001-0015 and GL4ES patches 0001-0009 applied in production order.
- All 146 CI regression tests and source/static gates passed.
- Bundled OSG population then failed while applying `ios/patches/osg-route-gl-entry-points-through-gl4es.patch`: after naming `src/osg/BlendFunc.cpp`, `/usr/bin/patch` reported `No file to patch`, ignored two hunks into `Oops.rej`, and CMake stopped with `Failed to route OSG GL entry points through GL4ES`.

This proves the repaired GL4ES production stack and intended OSG configuration, but the OSG patch failure still prevents linked retention or runtime exercise from being proven.

## Exact linked-product proof

Not obtained. Original run `32701930506` stopped during GL4ES patch bootstrap. Amendment 1 replacement run `32723328194` passed that boundary but stopped during OSG population before production compilation. No executable exists to inspect for the manual-route marker or `openmw_ios_renderer_diag_blend_event` retention/resolution.

## Runtime exercise proof

Not obtained. No installable candidate was produced, so source presence is explicitly not treated as proof of runtime exercise.
