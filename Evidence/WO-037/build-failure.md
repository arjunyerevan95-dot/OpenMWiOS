# WO-037 Fast Build Failure

## Identity

- Fast Development run: `33002709474`
- Head: `7dc76a962fb5cd54494a41296b138badee15038a`
- Branch: `codex/wo37-distant-pixel-attribution`
- Job: `98288395009`
- Started: `2026-08-26T18:59:18Z`
- Completed: `2026-08-26T19:43:40Z`

## Boundary

Patch bootstrap and validation succeeded. The failure occurred during the workflow step named `Incremental configure and dependency preparation`, while Xcode was compiling the changed pinned GL4ES source `src/gl/drawing.c`. The later production OpenMW compile/link and packaging steps were skipped.

## Exact diagnostic

```text
deps/gl4es/src/gl/drawing.c:323:5: error: use of undeclared identifier 'fpe_glReadPixels'; did you mean 'gles_glReadPixels'?
    LOAD_GLES_FPE(glReadPixels);
```

`LOAD_GLES_FPE` assigns the native GLES pointer from an FPE wrapper named `fpe_glReadPixels`; pinned GL4ES has no such wrapper for readback. This is a changed-source compile failure, not a patch-bootstrap, test-harness, cache, or infrastructure failure.

## Consequence

- IPA: NOT PRODUCED
- Executable: NOT PRODUCED
- Artifact: failure diagnostics only
- Device launch/capture: NOT PERFORMED
- Correction: NOT AUTHORIZED
- Full Qualification: NOT RUN

The WO37 replacement-dispatch condition requires failure before changed product sources compile. That condition is not met, so no replacement was dispatched.
