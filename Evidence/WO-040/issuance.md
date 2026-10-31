# WO-040 — Issuance evidence

- Date: 2026-10-31
- Author: orchestrator
- Pre-issuance canonical HEAD: `6001b1f39dcfb94f594d3d1a80d2b801749c8a26` (local/remote equal, clean)
- Decision: [DEC-018](../../Decisions/DEC-018.md)

## User-selected scope

The user proposed adopting the other iOS port and adding their preferred customizable touch controls. After the orchestrator identified the exact repository and described a stock-renderer qualification gate plus touch porting, the user explicitly accepted all reported limitations and waived that first gate: they have seen Reddit reports of correct rendering and acceptable performance and direct proceeding to control porting. No independent device verification is claimed or required before implementation.

## Pinned external foundation (read-only inspection)

- Repository: <https://github.com/joedemo42/OpenMW>
- Release: <https://github.com/joedemo42/OpenMW/releases/tag/v0.52-149>, published 2026-10-28
- Source tag verified through GitHub commit API: `2931be63bd2147e437a2b077ed6c97f563648a0a`
- Published asset: `OpenMW-0.52.0-149-unsigned.ipa`, 26,265,819 bytes
- GitHub-reported asset SHA-256: `60e679503cf6db9638759cbf0fbf34adfd3e6badcc9b26676d14bbe8e320f59a` (API metadata, not a locally recomputed download)
- [iOS requirements/build/limitations](https://github.com/joedemo42/OpenMW/blob/2931be63bd2147e437a2b077ed6c97f563648a0a/ios/README.md)
- [Dependency patches](https://github.com/joedemo42/OpenMW/blob/2931be63bd2147e437a2b077ed6c97f563648a0a/ios-deps/patches/README.md)
- [Mesa recipe](https://github.com/joedemo42/OpenMW/blob/2931be63bd2147e437a2b077ed6c97f563648a0a/ios-deps/recipes/mesa.sh): 25.1.9; Zink enabled, GLES disabled
- [SDL recipe](https://github.com/joedemo42/OpenMW/blob/2931be63bd2147e437a2b077ed6c97f563648a0a/ios-deps/recipes/sdl2.sh): 2.32.10; UIKit EGL, no Apple GLES backend
- [OSG recipe](https://github.com/joedemo42/OpenMW/blob/2931be63bd2147e437a2b077ed6c97f563648a0a/ios-deps/recipes/osg.sh): `01cc2b585c8456a4ff843066b7e1a8715558289f`, desktop GL2 profile
- [Input/platform implementation](https://github.com/joedemo42/OpenMW/blob/2931be63bd2147e437a2b077ed6c97f563648a0a/apps/openmw/ios/platform.mm): GCVirtualController, two-finger menu, device-driven controller menus
- [SDL EGL/Metal presentation patch](https://github.com/joedemo42/OpenMW/blob/2931be63bd2147e437a2b077ed6c97f563648a0a/ios-deps/patches/sdl2/0002-uikit-desktop-opengl-via-egl.patch)

The orchestrator inspected the recipes/platform/SDL patch and our checked-out touch adapter/model/install seam directly. `ios/build.sh` currently builds signed device apps and strips signing when packaging `--unsigned`; a credential-free CI build may need a narrow packaging adaptation. Do not mistake packaging unsigned for proof that its preceding build needs no signing configuration.

## Worker and project continuity

- Existing assigned worker: OpenMWiOS Astra Worker, `01a0b99a-8578-7503-bc57-a9665b14950f`; settings unchanged.
- Latest worker execution is interrupted at WO39 preliminary recovery; no new worker or overlapping run is required. See [closure review](../WO-039/orchestrator-final-review.md).
- New candidate directory and remote `codex/wo40-zink-touch` branch did not exist during issuance checks.
- Latest repository CI is unrelated `patch-1` run `40158810951`, October 25, completed/action_required. Last successful project iOS run remains WO38 `33306995685`. No queued/in-progress run was returned. Do not approve, cancel or modify the unrelated run/PR.
- Codebase Memory currently lists unrelated projects only, no OpenMW tree. No reindex or configuration change was made. Source fallback is authorized.

## Publication and dispatch

Initial state is READY, with no WO40 start directive sent at this checkpoint. Publish issuance before dispatch; record delivery/activation separately. No source changes or CI dispatch occurred during issuance.

## Subsequent activation — 2026-10-31

READY issuance was committed and pushed as `b8bf69b4b73f991a35eecb0029dff812c3e2310b`. At approximately 11:53 UTC, the orchestrator sent `Start WO-040 now` directly to assigned worker `01a0b99a-8578-7503-bc57-a9665b14950f`, naming the canonical file/publication, exact Zink baseline, waived comparison, new checkout guard, closed WO38/39 authority and stop/review protocol. The send returned the same thread ID without error. No model/thinking override was supplied.

WO40 transitions READY -> ACTIVE in a separate canonical commit. Successful delivery does not itself prove worker receipt or technical completion; subsequent acknowledgment and work results must be reported as such. No duplicate directive or CI run was sent by the orchestrator.
