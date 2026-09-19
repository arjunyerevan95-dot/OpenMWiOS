# WO-037 original diagnostic compile-failure review

- Review date: 2026-08-27
- Disposition: **AMENDMENT REQUIRED**
- Accepted engineering baseline: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9` — unchanged
- Worker branch: `codex/wo37-distant-pixel-attribution`
- Diagnostic source: `7dc76a962fb5cd54494a41296b138badee15038a`
- Worker evidence commit: `e6a6a5b5f9b63b985d93068fb16feaacbb5f4737`

## Authorization reconciliation

The original WO37 start directive was delivered through the user to the existing worker on 2026-08-26. The worker thread contains the exact canonical order, accepted baseline, explicit `Start WO-037 now` directive, and acknowledgement of branch and baseline. Canonical CURRENT_STATE and the work-order header were not separately advanced from READY to ACTIVE before execution. This was a missed bookkeeping transition, not unauthorized worker execution. It is recorded explicitly and is not precedent for inferring ACTIVE from file reads or source changes.

## Repository and evidence review

The worker branch is pushed and clean at `e6a6a5b5f9b63b985d93068fb16feaacbb5f4737`. Its diff from the accepted baseline contains only the WO37 bounded diagnostic implementation, tests/fixtures, and `Evidence/WO-037/`; it does not modify canonical CURRENT_STATE, WorkOrders, or Decisions.

The worker report, manifest, source/attribution model, diagnostic design, target-capture placeholder, and build-failure record are accepted as execution evidence. They remain candidate diagnostic state and do not advance the accepted product baseline. The unlisted report Gist is a convenience mirror; the repo-backed report at the evidence commit remains the durable execution record.

## CI and artifact verification

- Fast run `33002709474`: completed / failure at head `7dc76a962fb5cd54494a41296b138badee15038a`.
- Run interval: 2026-08-26 18:59:13Z to 19:43:41Z.
- Patch bootstrap and validation passed.
- `Incremental configure and dependency preparation` failed while compiling changed pinned GL4ES `src/gl/drawing.c`.
- Exact compiler error: undeclared `fpe_glReadPixels` at the added `LOAD_GLES_FPE(glReadPixels)` call; CI identifies `gles_glReadPixels` as the existing declaration.
- Production OpenMW compile/link, packaging, artifact upload, and device execution were skipped. No IPA, executable, Mach-O UUID, screenshot, JSONL, or target-pixel attribution was produced.
- No duplicate build or Full Qualification ran.

## Exact failure classification

This is a narrow diagnostic implementation compile defect, not a renderer result. `LOAD_GLES_FPE(name)` routes non-ES1 builds to `fpe_##name`; pinned GL4ES has no `fpe_glReadPixels`. Codebase Memory located the relevant loader macros and readback function, and direct inspection of pinned source verified that `gl4es_glReadPixels` uses `LOAD_GLES(glReadPixels)` before calling `gles_glReadPixels`.

The original replacement clause allowed replacement only for failure before changed-source compilation, so the worker correctly stopped under Condition F. The defect is nevertheless fully discriminated and repair does not require renderer speculation or diagnostic redesign.

## Disposition

Accept the diagnostic design, tests, build failure, and source-level failure classification as execution evidence only. Issue WO37 Amendment 1 as READY to:

1. replace only the invalid `glReadPixels` loader with the pinned-source-correct ordinary GLES loader;
2. add deterministic validation for that exact loader contract and the pristine ordered patch stack;
3. authorize one replacement Fast diagnostic run; and
4. if the IPA is produced, resume the original device-attribution and conditional-correction phases without changing their evidence requirements or correction budget.

If the replacement fails to produce the intended IPA, stop without another diagnostic build. No renderer correction is authorized until representative black-silhouette and blue/white targets are causally attributed as required by the original order.

See [WO-037 Amendment 1](../../WorkOrders/WO-037.md).
