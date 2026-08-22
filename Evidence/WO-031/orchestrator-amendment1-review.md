# WO-031 Amendment 1 orchestrator review

- Review date: 2026-08-22
- Disposition: **AMENDMENT REQUIRED**
- Worker execution commit: `12cb515e63072abc98f5ca6a4e42ca15b1e95aaf`
- Ownership repair: `8140aa4ee2af00e335b9212605524883571e65ed` — validated as evidence
- Accepted engineering baseline: `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27` — unchanged

## Execution and CI verification

- GitHub Actions run `32588069228`: completed / success, head `8140aa4ee2af00e335b9212605524883571e65ed`.
- Artifact: `OpenMW-iOS-fast-39`, ID `9479709482`, 39,168,891 bytes.
- Artifact digest: `sha256:7c085408be58c8187afda97f45462291c4fb552b00d959be2605c0c628f492d2`.
- Reported IPA SHA-256: `498D0285103C0F3664F44F35004FF1ADD8D463A6ACB6F4E5C11C4CE682A6C9CD`.
- Reported executable SHA-256: `5AA12617933D031E25D06C590BEA15507CC7CA863DB63EEBDC91FDBC994F2D40`.
- Reported Mach-O UUID: `56699F22-BA7C-3E7D-B5B6-0B9CEBB0AFC8`.
- No additional workflow was triggered and the final renderer-correction build was not used.

The source delta from the rejected candidate to the replacement gives `sPath` and `sSession` explicit copied process-lifetime ownership and adds a focused rejection check for the former raw assignments. The exact artifact reached the exterior without the prior crash. The lifetime repair is therefore accepted as execution evidence, not yet merged into the accepted engineering baseline.

## Supplied JSONL verification

- File: `device-renderer-diagnostic-amendment1.jsonl`
- Size: 7,028 bytes
- SHA-256: `5A6113914B4D90EEF274588E8914CA01D37F53BFB4CAB45DAE22F8E8ABD5FAC0`
- Session: `02306F28-5A6E-45AB-ADAC-414235769F83`
- Records: 23
- Sources: one `ios`, 22 `openmw`, zero `gl4es`
- Families: one `session`, 21 `r1.state`, one `r1.asset`, zero R2
- Correlation: 20 `unbound`; one water state; one `_land_default.dds` control asset

The attachment exactly matches the worker report. The user supplied the correct file. It is sufficient to establish that the bridge writes valid later OpenMW records and that the required GL4ES/R2 records are absent.

## Why it cannot diagnose the renderer yet

The order requires a comparison between the state OpenMW/OSG intended and the state GL4ES received/applied. This file contains only the upper OpenMW half. It also lacks the R2 fog/distance family entirely. Consequently it cannot identify where alpha/fog state first diverges and cannot support a renderer correction.

Direct source review found that the current GL4ES R1 probe emits only after GL4ES upload bytes hash to an OpenMW-registered texture and that later draw probes require that match. The only registered asset record was a non-translucent control and produced no GL4ES counterpart. The evidence does not yet distinguish a production linkage/availability failure from a representation/correlation mismatch or unhit call sites. Amendment 2 must distinguish them with an unconditional bounded GL4ES handshake and linked-product proof before another device run.

The R2 OpenMW and GL4ES probes also emitted nothing. Their actual exterior execution boundaries must be source-verified and instrumented with bounded milestones; absence alone cannot be interpreted as renderer state.

## Renderer and Menu disposition

- R1 cause: unknown.
- R2 cause: unknown.
- R1/R2 convergence: unproven.
- Renderer correction: none.
- Visible renderer defects: unchanged.
- Short-tap Menu: failed in the reported candidate; long-press editor entry worked; no touch-source delta.

The Menu result is preserved but does not authorize touch changes. Renderer observability remains the priority. It must be rechecked on the next diagnostic artifact and must pass before any final candidate can be accepted.

## Orchestrator action

Issue WO31 Amendment 2 as READY. Authorize one source-verified GL4ES/R2 diagnostic redesign and one further diagnostic Fast build, then resume the original R1/R2 investigation only if the required record chains are present.

See [DEC-009](../../Decisions/DEC-009.md) and [WO-031 Amendment 2](../../WorkOrders/WO-031.md).
