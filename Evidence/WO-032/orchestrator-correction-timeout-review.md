# WO-032 correction-timeout orchestrator review

- Review date: 2026-08-23
- Disposition: **PARTIAL ACCEPT / AMENDMENT REQUIRED**
- Diagnostic candidate: `79231c0fbf9293388f8f47456f8c2a2696291633`
- Correction source candidate: `1625713b949ddb0cde5471feead75f29fedadfaa`
- Worker evidence commit: `f19632bdaa4d2915c4ea754756b97d5dd61f8311`
- Accepted engineering baseline: `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27` — unchanged

## Independently verified CI

Replacement diagnostic run `32627872506` completed successfully at `79231c0fbf9293388f8f47456f8c2a2696291633`. It compiled, linked, packaged, and uploaded `OpenMW-iOS-fast-47`, artifact ID `9490874268`, digest `sha256:d32529f56a7d495ffb689db40781aa4cf088517213579aa2b7e15ad132d25675`.

Correction run `32634038454` used exact head `1625713b949ddb0cde5471feead75f29fedadfaa`. Bootstrap and ordered patch application passed. The job was cancelled at the two-hour limit during `Incremental configure and dependency preparation`; OpenMW compile/link, package, upload, and artifact creation were skipped. GitHub reports zero artifacts for the run.

## Source review

Direct diff inspection from the diagnostic candidate to the correction candidate shows two files only:

- `ios/patches/osg-route-gl-entry-points-through-gl4es.patch`;
- `validation/test_wo32_targeted_renderer_diagnostics.py`.

The OSG patch routes the two inline core-mode applications and ordinary `BlendFunc::apply` through `gl4es_glEnable`, `gl4es_glDisable`, and `gl4es_glBlendFunc` only under `__APPLE__ && OPENMW_GL4ES_MANUAL_INIT`. Existing direct GL behavior remains under `#else`. The validation change asserts this scope. No touch, data-path, dependency revision, shader, FBO, canonical ControlPlane, or unrelated production source change is present.

Codebase Memory identified the pinned OSG `BlendFunc::apply` and `State::apply` ownership paths. Direct checked-out source and the correction diff were used as authority; no reindex was performed.

## Accepted evidence

The device JSONL and linked-product symbol evidence prove the earliest smoke/particle divergence: OSG core state changes bypass GL4ES tracking even though GL4ES owns the converted program and draw. The correction is causally justified and narrowly scoped.

The foliage sample is already opaque before raster output, so its separate cause is not proven. R2 lacks a second stable view-distance generation, so the distance/horizon cause is also not proven. Neither is accepted as corrected.

## Disposition

Accept the R1 smoke/particle causal localization. Preserve the worker evidence. Do not advance the qualified runtime baseline and do not accept the unbuilt correction.

Issue [WO-032 Amendment 2](../../WorkOrders/WO-032.md) as READY for one unchanged-correction build and device qualification. Because the exact correction changes the ABI/cache identity and the first cold dependency path exceeded the existing two-hour job limit, Amendment 2 may change only the Fast job timeout from 120 to 180 minutes. Any other workflow, cache, source, or renderer change requires a new orchestrator review.
