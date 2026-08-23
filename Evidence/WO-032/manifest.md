# WO-032 evidence manifest

## Execution identity

- Canonical ControlPlane commit: `9100edc9ee3f9dc89ec6adafc28ec72a77ed48a8`.
- Investigation continuation / issued execution baseline: `626b3321ee7ce83f82d22a707dfa4f9177cf6fff`.
- Execution branch: `codex/wo32-targeted-renderer-boundary`.
- Accepted product baseline remains WO-029 candidate `195f3a4b878ceca9a3a05c1d95cb2792d68f72f4`; WO-032 does not alter accepted state.
- Diagnostic implementation commit: pending.
- Diagnostic Fast run/artifact: pending.
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

## Pending device evidence

- Bounded renderer JSONL: pending.
- Foliage screenshot/hash: pending.
- Chimney-smoke screenshot/hash: pending.
- Two view-distance screenshots/hashes: pending.
- R1 target hit/miss result: pending.
- R2 post-receipt/two-generation result: pending.
