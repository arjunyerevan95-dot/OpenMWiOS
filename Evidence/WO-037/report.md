# WO-037 Execution Report

Status: **BLOCKED - STOP CONDITION F**

## Scope

WO-037 is attributing, independently:

1. abrupt near-black distant silhouettes; and
2. the blue horizontal band plus pale/white horizon region.

No renderer correction was selected or implemented. The accepted WO33 product behavior remains unchanged. The WO37 request-gated diagnostic candidate did not produce an IPA.

## Current result

- Exact baseline and execution branch verified.
- Rejected WO34 terrain source and WO35/WO36 configuration experiments are absent.
- No active or queued GitHub Actions run existed before dispatch.
- OSG `RenderLeaf::render`, GL4ES direct draw, and native post-swap boundaries were directly verified in pinned source.
- A one-frame, one-pixel, request-gated correlation path has been implemented.
- Focused WO33 + WO37 validation: 22 tests, 20 passed, 2 compiler-dependent skips.
- Aggregate Windows-host validation: 153 tests, 143 passed, 8 skipped, 2 known host errors because a Unix verification script cannot execute on Windows. No renderer/touch/path regression failed.
- `git diff --cached --check`: pass.
- Diagnostic source commit: `7dc76a962fb5cd54494a41296b138badee15038a`.
- Fast Development run `33002709474` reached compilation of changed GL4ES source and failed in `drawing.c`.
- Exact compiler error: `use of undeclared identifier 'fpe_glReadPixels'; did you mean 'gles_glReadPixels'?` at the added `LOAD_GLES_FPE(glReadPixels)` call.
- Production OpenMW compilation, linking, packaging, artifact upload, and device capture did not occur.

## Build budget

- Diagnostic Fast dispatches used: 1
- Correction IPA dispatches used: 0 / 1
- Replacement dispatches used: 0 / 1
- Full Qualification: not run and not authorized

## Current boundary

Run `33002709474` is not eligible for the replacement clause. The failure occurred while compiling the changed product source, rather than before changed-source compilation because of patch bootstrap, deterministic tests, cache, or infrastructure. A second diagnostic dispatch is therefore not authorized. No target-pixel attribution was collected, both renderer defects remain unclassified, and no correction is authorized.

## Stop condition

**F - patch/build/infrastructure replacement budget exhausted.**

The precise continuation boundary is to replace the invalid GL4ES loader macro with a source-verified native GLES readback acquisition that compiles in pinned GL4ES, re-run the deterministic suite, and obtain explicit orchestrator authority for another diagnostic dispatch. This report does not authorize that continuation.
