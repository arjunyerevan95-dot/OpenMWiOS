# WO-035 Evidence Manifest

Status: COMPLETE — Condition C; awaiting orchestrator review

## Execution identity

- Canonical order: `WorkOrders/WO-035.md` at ControlPlane commit `08d62dea4806c65052cbdcb7bf86f4ea22edb3f7`
- Accepted engineering baseline: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`
- Execution branch: `codex/wo35-sky-blending-qualification`
- Rejected WO-034 terrain correction is absent from this branch.
- No production source change has been made.
- No CI/build has been started.
- The user explicitly retained the Arm B setting after observing improved silhouette fading.

## Referenced prior evidence

- `Decisions/DEC-014.md`
- `Evidence/WO-034/orchestrator-final-review.md`
- `Evidence/WO-034/device-capture.md`
- `Decisions/DEC-013.md`
- `Evidence/WO-033/orchestrator-final-review.md`
- `Evidence/WO-032/renderer-r2-targeted.md`

## WO-035 evidence records

- `source-and-setting-proof.md` — source ownership and expected shader behavior
- `configuration-ab.md` — configuration A/B byte identity, hashes, and semantic delta
- `device-capture.md` — matching-view physical-device observations
- `diagnostic-extract.md` — bounded runtime activation/projection proof
- `report.md` — final execution outcome at the orchestrator-review gate

## Accepted device/artifact context

- Installed same-binary A/B candidate: WO-034 IPA
- IPA SHA-256: `EE9631158A008A2304A3CA766F2DDD9BFBDA2DD9ED6A9775297DE9FC3DEDB043`
- The rejected WO-034 terrain-radius change is held constant across both A/B arms and was already observed to be visually inert.
