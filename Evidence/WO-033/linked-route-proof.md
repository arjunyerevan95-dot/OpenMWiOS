# WO-033 linked-route proof

## Pre-build source/configuration proof

- Execution branch: `codex/wo33-blend-state-transition`
- Investigation continuation: `164abe4ba2becf46ea043811963ac28195d29bcd`
- Accepted product baseline remains `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27`.
- `scripts/build-ios.sh` configures the production OpenMW graph with `-DOPENMW_GL4ES_MANUAL_INIT=ON` and bundled OSG (`OPENMW_USE_SYSTEM_OSG=OFF`).
- Pinned OpenMW CMake declares `OPENMW_GL4ES_MANUAL_INIT` and calls global `add_compile_definitions(OPENMW_GL4ES_MANUAL_INIT)` before the bundled OSG `FetchContent` graph is materialized.
- The pinned OSG patch applies the Apple/manual-init route to `State::applyMode`, `State::applyModeOnTexUnit`, ordinary `BlendFunc::apply`, and `GLExtensions` lookup.
- The WO-033 OSG diagnostic additions reconstruct exactly against pinned OSG `01cc2b585c8456a4ff843066b7e1a8715558289f` in the local deterministic patch model.
- GL4ES patches 0001 through 0009 apply in order against pinned GL4ES `c9895df34cd466c23bc60c2bd3db3d87e98fcbe7`.

This proves configuration and source inclusion, but not linked retention or runtime exercise.

## Exact linked-product proof

Pending the one authorized diagnostic Fast build. The built executable must contain the manual-route diagnostic marker and resolve/retain `openmw_ios_renderer_diag_blend_event`; build/link records and executable inspection will be recorded here.

## Runtime exercise proof

Pending device capture. Source/link presence alone will not be treated as proof that OSG issued the target event.
