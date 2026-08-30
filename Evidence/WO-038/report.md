# WO-038 Execution Report

Status: **BLOCKED — QUALIFIED DIAGNOSTIC IPA READY; REPRODUCIBLE TARGET PREPARATION REQUIRES OUT-OF-SCOPE TOUCH CHANGE**

## Scope

WO38 continues the reviewed WO37 diagnostic source and applies only the authorized optional-GLib discovery disable to recover cold OSG configuration. It does not contain a renderer correction or modify product defaults.

## Baseline integrity

- Branch: `codex/wo38-cold-osg-attribution`
- Start/continuation HEAD: `7c17095ff876909e31e4c7e63702fff52b237373`
- Accepted engineering baseline: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9` (verified ancestor)
- Canonical `Documentation/CURRENT_STATE.md`, `WorkOrders/`, and `Decisions/`: untouched
- Rejected WO34 terrain candidate: absent from this continuation
- WO35/WO36 configuration experiments: evidence/config-only and absent from product source

## Change

- `scripts/build-ios.sh`: add `-DCMAKE_DISABLE_FIND_PACKAGE_GLIB=ON` to the iOS OpenMW/OSG configuration.
- `validation/test_wo38_cold_osg_configuration.py`: add five deterministic scope and invariance checks.
- `Evidence/WO-038/`: compact execution records.

## Validation

- WO38 focused tests: 5/5 passed.
- Aggregate: 163 run, 8 skipped, with two pre-existing Windows executable-format errors and two CRLF checkout failures in inherited OSG patch tests.
- Python syntax: passed.
- Diff check: passed.
- macOS patch bootstrap/source validation: passed.
- Cold OSG configure/dependency preparation: passed in 1,958 seconds.
- Real production OpenMW compile/link: passed in 2,355 seconds.
- Bundle validation/package/artifact upload: passed.
- Fast cache restores: source downloads miss; vcpkg binary miss; qualified incremental state miss.
- Full Qualification: not run.

## CI and artifact

- Fast run: `33269657425` (success)
- Artifact: `OpenMW-iOS-fast-66`, ID `9720624645`
- Artifact digest: `sha256:17b27b5a0b4a957dafefb9792f545b0fed8826955b7ebdbb9c5f878148f9d8ed`
- IPA SHA-256: `d66f5c31a50a48a8a35c8b5e9bc74e558d224c2da9d0debf8072f8b61df194ee`
- Executable SHA-256: `3d0308bb45d1823b441c4bb627846eb92c239c24e57aa4238a6ac1105c949d54`
- Mach-O UUID: `0FBDA93C-0871-39E6-A80D-C16B14606AC3`

## Physical attribution

The qualified artifact is ready. Black-silhouette and blue/white-horizon target captures remain pending. No target classification is claimed yet.

The user reported that the current touch overlay cannot short-tap Pause/Menu: a long press enters control customization, while the short press does not open the pause menu. Consequently, the user cannot create a save at a prepared distant-silhouette viewpoint. The current one-shot diagnostic fires at the first eligible exterior frame, so installing the IPA and later moving to a target does not produce a trustworthy screenshot/target-record correlation.

On 2026-08-30 the user explicitly offered a one-time exception to fix Pause behavior because it is the simplest way to prepare a reproducible target. This is recorded as user evidence and requested scope change only. Canonical WO38 explicitly prohibits touch changes and states that user observations do not authorize amendment. No touch source, renderer source, build, or canonical ControlPlane file was changed in response.

## Current stop boundary

**Stop Condition A / D: authorization conflict and unusable capture preparation.** The exact next step requires orchestrator review: either amend WO38 to authorize the narrow Pause short-tap correction (and any build budget needed to deliver it), or provide another canonical capture method. Until then, device attribution cannot be made reproducible enough to satisfy WO38. No duplicate build or Full Qualification run was dispatched.
