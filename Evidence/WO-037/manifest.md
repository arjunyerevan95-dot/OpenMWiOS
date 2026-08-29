# WO-037 Evidence Manifest

Status: blocked under Stop Condition F because the third and final authorized Fast Development run failed during configure before product compilation; no Amendment 2 IPA or device attribution exists.

## Authority and identity

- Canonical Amendment 2: `WorkOrders/WO-037.md` at ControlPlane commit `f9a41fba81feb1f9432d843e7c2e409441618f76`.
- Accepted engineering baseline: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`.
- Amendment 2 continuation point: `c890fcda3178c36bc34ae2e99760c971dc9dd4ec`.
- Execution branch: `codex/wo37-distant-pixel-attribution`.
- Amendment 2 product commit: `fbddf1f65fef8d3d56e5ee9b3511e0b72198163d`.
- Pinned OpenMW: `f4bec41444214a7903bebd178389ca22ca13f646`.
- Pinned OSG: `01cc2b585c8456a4ff843066b7e1a8715558289f`.
- Pinned GL4ES: `c9895df34cd466c23bc60c2bd3db3d87e98fcbe7`.

## Records

- [Execution report](report.md)
- [Source and attribution model](source-and-attribution-model.md)
- [Diagnostic design and tests](diagnostic-design-and-tests.md)
- [Original Fast build failure](build-failure.md)
- [Amendment 2 final Fast build failure](amendment2-build-failure.md)
- [Target-pixel capture status](target-pixel-captures.md)
- [Request-loader device evidence](request-loader-device-evidence.md)
- [Orchestrator compile-failure review](orchestrator-compile-failure-review.md)
- [Orchestrator Amendment 1 runtime review](orchestrator-amendment1-runtime-review.md)

## Amendment 2 local validation

- Focused: 27 tests; 25 passed; 2 compiler-dependent skips.
- Aggregate: 158 tests; 148 passed; 8 skipped; 2 existing Windows host-execution errors; no product assertion failure.
- Ordered OpenMW/OSG/GL4ES patch bootstrap: pass locally and in CI.
- `git diff --check`: pass.

## Final Fast run

- Run: `33265712820` (failure).
- Source: `fbddf1f65fef8d3d56e5ee9b3511e0b72198163d`.
- Failed step: `Incremental configure and dependency preparation`.
- Exact boundary: OSG `FindGLIB.cmake:91` could not read `/usr/local/Cellar/glib/2.88.2/lib/glib-2.0/include/glibconfig.h`.
- Product compilation, linking, packaging, and IPA upload: skipped.
- Failure artifact: `OpenMW-iOS-fast-failure-63`, ID `9718681291`.
- Failure artifact digest: `sha256:c7cc2fea29cf86ae6e8c16d78ee237c18487ef4e56409ffc6547c49a4966676e`.
- Executable SHA-256: not applicable.
- Mach-O UUID: not applicable.
- IPA SHA-256: not applicable.
- Full Qualification: not run.

## Device-attribution status

No Amendment 2 IPA exists, so no device installation, fresh exterior capture, target-pixel records, screenshot/session hashes, or renderer classification was produced. Prior Amendment 1 request-placement and unarmed-session evidence remains preserved in the referenced records.

## External report

- Unlisted report Gist: `https://gist.github.com/arjunyerevan95-dot/d8e93d65c0df86ae40a863d188e8e122`.
