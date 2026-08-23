# WO-032 evidence manifest

## Execution identity

- Canonical ControlPlane commit: `9100edc9ee3f9dc89ec6adafc28ec72a77ed48a8`.
- Investigation continuation / issued execution baseline: `626b3321ee7ce83f82d22a707dfa4f9177cf6fff`.
- Execution branch: `codex/wo32-targeted-renderer-boundary`.
- Accepted product baseline remains WO-029/WO30 source candidate `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27`; WO-032 does not alter accepted state.
- Diagnostic implementation commit: `4b626d80dcf58bc5768c71f2e043c9f4edec6b07`.
- Diagnostic Fast run: `32623652029` (failure at cheap regression validation).
- Failure diagnostics artifact: `OpenMW-iOS-fast-failure-44`, ID `9489106339`, size 6,496 bytes, digest `sha256:99b85d6fbf6f4981ead3e1fb07c58c76fb23a74e5ef0c98c36155673174b9045`.
- Production artifact / IPA / executable: none; compile, link, package, and upload steps were skipped.
- Renderer correction commit/run: not authorized unless targeted device evidence proves a causal correction.

## Referenced WO-031 evidence

- `Evidence/WO-031/renderer-r1-alpha-particles.md`: R1 defect remained visible; broad sampling did not reach a representative defective applied draw.
- `Evidence/WO-031/renderer-r2-distance-fog.md`: accepted fog intent/receipt evidence did not reach post-receipt exterior program consumption or two-distance projection/cull boundaries.
- `Evidence/WO-031/diagnostic-channel.md`: file-backed bounded channel and lifecycle findings.
- WO-031 Amendment 2 Fast run `32597504051`, artifact `OpenMW-iOS-fast-42` (ID `9482706450`), IPA SHA-256 `82439580B2518CC2227C0884EC6B7E21186A5CB6127FBF75585A65F5387B4BF1`, executable SHA-256 `0B192B5B5EB9CF20C4548799FA51536DF66AB64A3968B2ECA4FBFE73F010E1FD`.

## WO-032 sampling design

- [Sampling model](sampling-model.md)
- [R1 target contract](renderer-r1-targeted.md)
- [R2 target contract](renderer-r2-targeted.md)

## Local validation

- Focused WO-031 + WO-032 tests: 19 run, 17 pass, 2 skipped because no C compiler is installed on this Windows host; no failures.
- The C fixture remains enabled for CI/platform environments with a compiler.
- GL4ES `0007` reverse patch check after whitespace cleanup: pass against the applied pinned stack.
- OpenMW `0014` reverse patch check after whitespace cleanup: pass against the applied pinned stack.
- GL4ES `0008` reverse patch check: pass against the edited pinned stack.
- OpenMW `0015` reverse patch check: pass against the edited pinned stack.
- `git diff --check`: pass.
- Touch source changes: none.
- Canonical ControlPlane changes: none.

## Diagnostic Fast result

- PR: `https://github.com/arjunyerevan95-dot/OpenMWiOS/pull/18`.
- Run: `https://github.com/arjunyerevan95-dot/OpenMWiOS/actions/runs/32623652029`.
- Job: `97155562871`.
- Run window: 2026-08-23 06:43:03Z through 06:44:53Z (1m50s).
- Source snapshots, all 15 OpenMW patches, all 8 GL4ES patches, revisions, shell/static/data checks: pass.
- Python regression tests: 131 run; 129 pass and 2 fail.
- Both failures occur in the test-only `apply_file_patch` helper after the required patch-payload whitespace cleanup changed blank unified-diff context lines from a single prefix space to empty lines. The helper does not advance its source cursor for empty context; the real ordered patch application passed.
- Cache restore steps completed successfully, but the failure artifact's cache fields were emitted empty before later resolution; no compile timing or product cache qualification was reached.
- Diagnostic build budget: 1 of 1 consumed.
- Full Qualification: not run.
- Stop condition: **G — build budget exhausted**.

## Pending device evidence

- Bounded renderer JSONL: not produced; no IPA/device run.
- Foliage screenshot/hash: not produced for WO-032.
- Chimney-smoke screenshot/hash: not produced for WO-032.
- Two view-distance screenshots/hashes: not produced for WO-032.
- R1 target hit/miss result: not reached.
- R2 post-receipt/two-generation result: not reached.
