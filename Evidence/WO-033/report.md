# WO-033 execution report

Status: **COMPLETE — Stop H (qualified success)**

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

## Amendment 2 diagnostic build and runtime result

Amendment 2 repaired only the malformed bundled-OSG patch representation and its hermetic validation:

- implementation commit: `fd300ba12351252ece9e7b481c0b2d366228f9e8`;
- pinned OSG: `01cc2b585c8456a4ff843066b7e1a8715558289f`;
- OSG patch SHA-256: `4D44A36449DDE6B9160BBB0BF97DAF69DC3E8A35A2A36D3A0DD6C2D228292DDA`;
- pristine fixture SHA-256: `91F3E31C4BD6999162F91C0ED1ACDEBFE889902D7E79D16CECF505392020409E`;
- focused WO31-WO33 host tests before the runtime correction: 35 total, 31 passed, 4 skipped for unavailable local compilers;
- Fast run `32742643722`: success;
- artifact `OpenMW-iOS-fast-54`, ID `9528845874`, digest `sha256:eb8c96d038e8e67a7f22b07b0c58f08e2ef8c4f7898b085c370b4acea153c306`;
- executable SHA-256 `05C86BB43574092B1D0AF26E7517DCFF1E576ABAC9AAC1D84B59F255FCED17FB`;
- IPA SHA-256 `9A5CD26DAAE7FF5C4B56B630EB5BAE148A2A80B120D2466B415BA9C89E87ED5B`;
- Mach-O UUID `98B76201-B444-3844-8AB2-E5DF9B61B953`.

The user installed the exact diagnostic candidate and reached the chimney-smoke view. The smoke remained opaque/blocky, which was expected because the candidate changed diagnostics and patch materialization only.

The supplied 438-record bounded JSONL then proved:

1. OSG's linked manual route repeatedly receives `GL_BLEND=1` for the target State/context.
2. Its cache reports `valid=1,last=1`, so OSG records `issued=0`.
3. The subsequent GL4ES intake/capture/intercept/common draw path retains `blend=0` on the same thread, with no active/pending render list.
4. The target draw has the correct alpha factors, disabled depth writes, and a fragment program that writes alpha and can discard.

The first observable invalid boundary is therefore the OSG mode-cache gate suppressing a GL4ES reconciliation call. The trace does not support a blend-factor, different-context, or replay correction.

## Conditional minimal correction

Commit `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9` implements the one Phase 4 correction authorized by that sequence:

- only under Apple + `OPENMW_GL4ES_MANUAL_INIT`;
- only for `GL_BLEND`;
- only when OSG's mode cache is valid and already matches the requested value;
- reasserts the request through `gl4es_glEnable` / `gl4es_glDisable`;
- returns `false`, preserving OSG's cache-match return semantics;
- leaves GL4ES's existing internal comparison responsible for suppressing a redundant native state change;
- does not force blend at draw time or alter factors, depth, shader, texture, render-list, foliage, horizon, touch, or other renderer behavior.

Validation after the correction:

- focused WO31-WO33 suite: 36 total, 32 passed, 4 skipped because no local C/C++ compiler is available;
- full Windows discovery: 145 total, 135 passed, 8 skipped, and the same 2 environment-only errors caused by direct execution of a POSIX verifier script on Windows;
- pristine OSG real-parser/materialization test: passed;
- output hash for patched `include/osg/State`: `378CB51658BA82278F8889F5E730CE114AC7B2CE30715DC499B0B2CABB17848B`;
- scope-limited `git diff --check`: passed.

## Amendment 2 correction build

- Fast run: `32771773194` ([Actions](https://github.com/arjunyerevan95-dot/OpenMWiOS/actions/runs/32771773194)); result: success.
- Candidate: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`.
- Job: `97573507624`.
- Run interval: 2026-08-24 20:04:11Z to 21:21:22Z (1h17m11s).
- Configure/dependency preparation: 2,051 seconds (34m11s).
- Compile/link: 2,276 seconds (37m56s).
- Artifact: `OpenMW-iOS-fast-55`, ID `9538962155`, size 39,184,614 bytes.
- Artifact digest: `sha256:1af36e00a09f9056bf1bb63eaf0c4c09a35e6ed14155009425913717f9840be7`.
- IPA size: 39,151,364 bytes.
- IPA SHA-256: `34EB8106C60138F30DA8B59083CA026FDA013F68870DDC658C1584B6E939AC4E`.
- Executable SHA-256: `C759B9D09DF6A2CFFE7657839BD3DB25999A399743E811A7846A406A5826874C`.
- Mach-O UUID: **NOT RECORDED**.
- Bundle validation: passed; bundle ID `org.openmw.ios`, executable `openmw`.
- Source-download cache hit: true. Other build-state cache fields were empty; benchmark mode was `none`.
- Full Qualification did not run.

## Correction device qualification

The user installed the exact correction candidate and supplied a 445-record bounded JSONL trace plus eight screenshots from the representative Seyda Neen exterior route.

- Trace SHA-256: `6D57F23FEE227608A5285BC52BB0AB386BB4E7ABEE7EB9F9787931E39E8B2C3B`.
- Trace size: 149,924 bytes.
- Session: `9504FA5C-CF45-46D9-908E-2F1838B8B0B9`.
- Runtime target: `textures/tx_smokealpha00a.dds`, target 2, texture 129.
- OSG cache-match reassertions: 55.
- GL4ES `proxy_glEnable(GL_BLEND)` ingress records: 55.
- Targeted smoke records: 4 with `blend=1`, 0 with `blend=0`.
- Representative draw path: intake, capture, intercept, and `glDrawElementsCommon` all retained `blend=1` on the same thread/GL4ES state with no active or pending render list.
- Target draw retained factors `770,771,770,771`, depth test enabled, depth writes disabled, fragment discard present, and fragment alpha output present.

The visible prediction passed. The user reported: “Smoke is fixed. But also spell and foliage transparencies are also fixed.” Screenshots confirm alpha-cutout foliage, non-blocky chimney smoke, and a correctly composited spell effect while landscape presentation, HUD, exterior traversal, and gameplay remained intact. No crash was reported.

The remaining distance/horizon presentation defect is real but explicitly outside WO-033. It was recorded as a deferred boundary and was not investigated or modified.

## Final causal conclusion

The opaque-card defect was caused by OSG's cache-match gate suppressing a blend request that GL4ES needed to reconcile its state. Reasserting only cache-matching `GL_BLEND` on the Apple/manual GL4ES route restores `blend=1` at the actual translucent draw without changing blend factors or forcing draw-time state. Runtime state and the physical screen changed in the predicted direction.

> WO-033 execution complete.
>
> Execution report: `Evidence/WO-033/report.md`
>
> Execution commit: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`
>
> Artifact / CI: run `32771773194`; artifact `OpenMW-iOS-fast-55` / `9538962155`
>
> Stop condition: **H — qualified success**
>
> Awaiting orchestrator review.
