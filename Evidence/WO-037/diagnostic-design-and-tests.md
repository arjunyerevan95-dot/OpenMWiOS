# WO-037 Diagnostic Design and Tests

## Activation contract

Target attribution is inactive unless this UTF-8 request file exists at process start and contains 1–80 non-whitespace characters:

`Documents/OpenMW/renderer-target-request.txt`

The request label identifies the session. Capture arms only on the first exterior-fog generation after startup and completes after one presented frame. Removing the request file returns later launches to the pre-WO37 observer behavior.

## Bounds

- Target: normalized NDC `(0,0)` / viewport center.
- Candidate draw budget: 96.
- `r3.*` record-family budget: 112.
- Total diagnostic file cap: 256 KiB.
- Readback: two 1×1 RGBA samples per correlated direct draw, plus one 1×1 post-pre-swap RGBA sample.
- No full framebuffer, full shader, or per-frame indefinite logging.

## Changed files

- `ios/openmw_ios_renderer_diagnostics.h`
- `ios/openmw_ios_renderer_diagnostics.mm`
- `ios/patches/osg-route-gl-entry-points-through-gl4es.patch`
- `patches/gl4es/0010-ios-target-pixel-attribution.patch`
- `patches/openmw/0016-ios-renderer-diagnostics-target-pixel-present.patch`
- `validation/fixtures/osg-01cc2b5-RenderLeaf.cpp`
- `validation/test_wo37_target_pixel_attribution.py`
- `validation/test_wo33_blend_transition_diagnostics.py` (keeps the historical WO33 fixture scoped to its original patch range)

## Validation

Focused command:

`python -m unittest validation.test_wo37_target_pixel_attribution validation.test_wo33_blend_transition_diagnostics`

Original result: 22 run, 20 passed, 2 compiler-dependent skips.

Amendment 1 result after the native loader repair: 24 run, 22 passed, 2 compiler-dependent skips. The strengthened fixture rejects `LOAD_GLES_FPE(glReadPixels)` and `fpe_glReadPixels`, requires `LOAD_GLES(glReadPixels)`, and applies the complete ordered GL4ES patch stack to pristine pinned revision `c9895df34cd466c23bc60c2bd3db3d87e98fcbe7`.

Aggregate command:

`python -m unittest discover -s validation -p "test_*.py"`

Original result on Windows host: 153 run, 143 passed, 8 skipped, 2 errors. Amendment 1 result with pinned dependency checkouts available: 155 run, 145 passed, 8 skipped, 2 errors. Both errors are the existing `test_verify_linked_product` cases attempting to execute a Unix script directly on Windows (`WinError 193`). No product validation assertion failed.

Covered constraints include request gating, file/draw budgets, zero-candidate presentation classification, multiple candidate classification, behind/near-plane flagging, missing names/bounds fallback, camera identity, OSG→GL4ES TLS correlation, direct-draw one-pixel reads, post-swap one-pixel read, no GL state mutation, render-list ambiguity, and real-parser application of the RenderLeaf patch to pristine pinned source.

`git diff --check`: pass.
