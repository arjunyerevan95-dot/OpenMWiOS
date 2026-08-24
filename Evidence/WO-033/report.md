# WO-033 execution report

Status: **PARTIAL / BLOCKED — Stop Condition G (build budget exhausted)**

## Objective

Trace the exact OSG decision → GL4ES enable/disable/state/render-list → dynamically targeted chimney-smoke draw sequence. Do not correct renderer behavior unless the one authorized diagnostic device capture proves the first invalid transition.

## Work completed

- Re-established the exact continuation branch without modifying canonical ControlPlane files.
- Reconstructed OSG mode, `BlendFunc`, GL4ES enable/disable, draw-common, and render-list paths using Codebase Memory followed by pinned-source verification.
- Added a target-gated 48-event blend-transition ring with global ordering, thread/site/context/state/list/FPE detail and bounded output.
- Added OSG cache-decision and blend-factor observations.
- Added GL4ES ingress and intake/capture/intercept/common/replay observations.
- Added deterministic source/model tests and a compiled sequence fixture.
- Locally reconstructed the GL4ES patch series in a dirty verification checkout, but that check failed to expose that production applies patch 0009 after earlier modifications to `enable.c` and `listdraw.c`. The production bootstrap gate correctly rejected those two stale patch contexts.

## Local validation

- Focused WO31–WO33 unittest set: 33 passed, 4 skipped because no local C compiler is installed.
- Full host unittest discovery: 132 passed, 7 skipped, 2 Windows-only execution errors because `validation/test_verify_linked_product.py` invokes a POSIX shell script directly; this is an environment limitation and the same tests run under macOS CI.
- OSG WO-033 State and BlendFunc patch reconstruction matches the independently generated pinned-source result.
- `git diff --check` passed for tracked WO-033 edits.

## Build/device/cause

- Execution commit: `f0427d8d40ea66a86f78f127082581bf10eae883`
- PR: `#19`
- Fast Development run: `32701930506`
- Run duration: 2026-08-24 07:32:10Z–07:33:44Z (1m34s).
- Failure step: `Bootstrap exact sources and validate patches`.
- Failure boundary: patch 0009 failed at `src/gl/enable.c:111` and `src/gl/listdraw.c:727` after production applied the existing GL4ES patch stack.
- Compile/link/package: **not started**.
- Production artifact: **none**.
- Failure artifact: `OpenMW-iOS-fast-failure-52` / ID `9510853902` / ZIP SHA-256 `d0bc419b0315ae1909fca6f8c9e749f31ea04f891c095786c55c2ed5d663a5c2`.
- Device capture: **not performed**, because no installable candidate exists.
- Linked/runtime route proof: **not obtained**.
- First invalid smoke blend transition: **not proven**.
- Causal renderer correction: **not authorized or attempted**.
- Accepted product state: unchanged at `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27`.

The single diagnostic Fast-build budget was consumed by the pre-compile failure. No duplicate or correction build was started. A future orchestrator amendment would be required to repair the patch-order hermeticity defect and authorize another diagnostic build.

> Execution commit: `f0427d8d40ea66a86f78f127082581bf10eae883`
>
> Artifact / CI: run `32701930506`; failure artifact `9510853902`
>
> Stop condition: **G — build budget exhausted**
>
> Awaiting orchestrator review.
