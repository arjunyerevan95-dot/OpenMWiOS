# WO-033 execution report

Status: **PARTIAL / BLOCKED - Stop Condition G (replacement build failed before IPA)**

## Objective

Trace the exact OSG decision -> GL4ES enable/disable/state/render-list -> dynamically targeted chimney-smoke draw sequence. Do not correct renderer behavior unless the authorized diagnostic device capture proves the first invalid transition.

## Original execution

- Diagnostic implementation: `f0427d8d40ea66a86f78f127082581bf10eae883`.
- Original evidence stop: `a54c7f832138c4719a000a6d3dc0fce5fe98cddd`.
- Fast run `32701930506` failed during production GL4ES patch bootstrap because patch 0009 used zero-context insertions and did not apply after patches 0001-0008.
- No compilation, IPA, device capture, or renderer correction occurred.

## Amendment 1 work completed

- Materialized pinned GL4ES `c9895df34cd466c23bc60c2bd3db3d87e98fcbe7` and applied production patches 0001-0008 in order.
- Rebased only the unified-diff context of `0009-ios-blend-transition-diagnostics.patch` against the exact post-0008 source.
- Added `validation/fixtures/gl4es-c9895df-wo33-patch-inputs.zip`, SHA-256 `1601090e10fda84c4e9b8343219deea1ad5c4398638005f22977e8f7e5c6bda6`, containing the pinned patch-input files required for deterministic reconstruction.
- Added a compiler-independent test that applies the complete 0001-0009 GL4ES series in production filename order without reading or mutating a persistent dependency checkout.
- Proved the rebased patch produces byte-identical diagnostic sources to the original intended transformation. SHA-256 matched for all five files:
  - `src/gl/drawing.c`: `99a0bd8a0659031f674301181b43401ee99eb68867e6e9d62a3486bd301846c1`
  - `src/gl/enable.c`: `3dc1942da562a23c8a1fd4f97a41919702d1db9f6388bb69efc04a9754639073`
  - `src/gl/ios_renderer_diag.c`: `cc35ecbfaa7ba91c79cd457af0e6374febc68362ff1aceafbaa0ba8a55f33b5c`
  - `src/gl/ios_renderer_diag.h`: `b96fd9a7d4a1f58e6aea173deca2522ceb40efd779dca9bdeb5f4c7db50f71d`
  - `src/gl/listdraw.c`: `fc5bffa01a83c6796d37c1eed2d9a0e0f640722a60594f30a15e74acdb0ff4f4`
- Amendment implementation commit: `10b88885e754121931cac2c3bbeed8230a5f997d`.

## Validation

- Focused WO31-WO33 host tests: 34 tests, 30 passed, 4 skipped because no local C compiler is installed.
- Full Windows host discovery: 143 tests, 133 passed, 8 skipped, 2 environment-only errors because `validation/test_verify_linked_product.py` invokes a POSIX shell script directly.
- Literal `git diff --check`: passed after the dedicated implementation commit; unrelated user worktree files remained untouched.
- Replacement CI source validation: 146 tests passed.
- Replacement CI clean source snapshots: OpenMW and GL4ES passed.
- Replacement CI ordered OpenMW patches 0001-0015: all passed.
- Replacement CI ordered GL4ES patches 0001-0009: all passed.
- Pinned revisions and JSON/plist/YAML/shell/static gates: passed.
- GL4ES patch 0009 SHA-256 in the replacement candidate: `9e44e6f8013b52bcf2efa491008f5479f38820a3c6e3869c17f1275cca047fe1`.

## Replacement Fast run

- Run: `32723328194`.
- URL: https://github.com/arjunyerevan95-dot/OpenMWiOS/actions/runs/32723328194
- Candidate: `10b88885e754121931cac2c3bbeed8230a5f997d`.
- Run interval: 2026-08-24 11:43:38Z to 12:31:21Z (47m43s).
- Patch bootstrap: passed, including the complete GL4ES 0001-0009 series.
- Failure step: `Incremental configure and dependency preparation`.
- Exact boundary: bundled OSG population invoked `ios/cmake/apply-osg-patch.cmake`; `/usr/bin/patch` reported `No file to patch. Skipping...` and `2 out of 2 hunks ignored--saving rejects to Oops.rej` while applying `ios/patches/osg-route-gl-entry-points-through-gl4es.patch`, after naming `src/osg/BlendFunc.cpp` and before continuing to `src/osg/Texture2D.cpp`.
- CMake fatal result: `Failed to route OSG GL entry points through GL4ES`; OSG populate exited 65.
- Production compile/link/package: not started.
- Executable/IPA/Mach-O UUID/bundle validation: none.
- Failure artifact: `OpenMW-iOS-fast-failure-53`, artifact ID `9520078724`, digest `sha256:6d14927bc77c0b5b10f668a8be720f4faf063b99fbf201f96910e08d72568a94`.
- Cache restore fields were empty; benchmark mode recorded `none`.

## Device and causal result

- No installable diagnostic candidate was produced, so no device capture was performed.
- Linked retention/runtime exercise was not obtained.
- The first invalid smoke blend transition remains unproven.
- No renderer correction was authorized or attempted.
- The accepted product baseline remains `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27`.

Amendment 1 authorizes exactly one replacement diagnostic run and requires a stop if it fails before an IPA. That run is exhausted. No second replacement run was started.

> WO-033 execution blocked.
>
> Execution report: `Evidence/WO-033/report.md`
>
> Execution commit: `10b88885e754121931cac2c3bbeed8230a5f997d`
>
> Artifact / CI: run `32723328194`; failure artifact `9520078724`
>
> Stop condition: **G - build budget exhausted**
>
> Awaiting orchestrator review.
