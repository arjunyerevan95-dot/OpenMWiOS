# WO-038 Execution Report

Status: **AMENDMENT 1 IN PROGRESS — FAST BUILD PASSED; DEVICE PAUSE CHECK PENDING**

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

The original authorization conflict was superseded by Amendment 1 at ControlPlane commit `ae3fa28`. Continuation began from exact commit `6f3eb24ae9be73950c3813964755169497bcc26e`.

Direct inspection revalidated that the same-callback START true/false pair could collapse in SDL's stored virtual-button state. The bounded correction now preserves START pressed through one `SDL_JoystickUpdate()` opportunity and then stores exactly one release. Its executable C++ fixture proves ordering, cancellation suppression, long-press non-leakage, and clean repeated pulses. See `pause-short-tap-correction.md`.

The single authorized Amendment 1 Fast build was dispatched exactly once and completed successfully:

- Runtime correction commit: `457ab881442302a9bd59435c1878ed4e72f6e52b`
- Fast run: `33306995685` (success)
- Run URL: <https://github.com/arjunyerevan95-dot/OpenMWiOS/actions/runs/33306995685>
- Product artifact: `OpenMW-iOS-fast-67`, artifact ID `9730898326`
- Artifact digest: `sha256:41709748e6cad3d8e48b1244ae42ee96a35ea7eb2607b751f8d6f834b69c315b`
- IPA SHA-256: `9312ea3b1ad757e9cee8a22785907f93ad9c68a33e02d845210ff5f733660593`
- Executable SHA-256: `26a73e55775a15bfdb60cc6c05861e1f790f60dfc920a5ef7b4087f7822ed912`
- Job duration: 731 seconds; end-to-end run duration: 758 seconds
- Cache result: exact source-download and vcpkg hits; qualified incremental state restored by fallback key rather than exact source-key match.
- Production OpenMW compile/link: passed
- Bundle validation/package/artifact upload: passed
- Full Qualification: not run
- Replacement build: not run and not authorized

The Litterbox API rejected the binary upload from the worker's current network with HTTP 403. The verified GitHub Actions artifact remains the authoritative installation source; this transport failure did not alter the artifact or trigger another build.

Device Pause/editor checks, prepared save creation, and the existing target attribution remain pending. No target classification is claimed yet.
