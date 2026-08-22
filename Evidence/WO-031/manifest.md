# WO-031 evidence manifest

## Execution identity

- Issued baseline: `dfe9e1e875c7020658aa59d22121a7cc0061ac69`
- Execution branch: `codex/wo31-exterior-renderer-correction`
- Diagnostic infrastructure commit: pending
- Renderer correction commit(s): pending evidence; none selected
- Stop condition: pending

## Pinned dependency identity

- OpenMW: `f4bec41444214a7903bebd178389ca22ca13f646`
- GL4ES: `c9895df34cd466c23bc60c2bd3db3d87e98fcbe7`
- OSG: `01cc2b585c8456a4ff843066b7e1a8715558289f`
- SDL: `2.32.10`

No dependency revision was changed.

## Phase 1 local evidence

- Focused diagnostic tests: 10/10 pass.
- Full Python discovery: 113 pass, 4 skip, 2 host-only errors. The two errors are pre-existing Windows inability to execute the POSIX `scripts/verify-linked-product.sh`; no WO-031 assertion failed.
- Fresh pinned ordered OpenMW patch-stack check: pass through `0013-ios-file-backed-renderer-diagnostics.patch`.
- Fresh pinned ordered GL4ES patch-stack check: pass through `0006-ios-file-backed-renderer-diagnostics.patch`.
- `git diff --check`: pass.
- Prohibited touch source diff: empty.
- Diagnostic-channel design: [diagnostic-channel.md](diagnostic-channel.md).

## CI and artifact

- Diagnostic Fast run: pending.
- Cache state: pending.
- Artifact ID/digest: pending.
- Executable SHA-256: pending.
- IPA SHA-256: pending.
- Mach-O UUID: pending.
- Full Qualification: not run.

## Device evidence

- Diagnostic file retrieval: pending.
- R1 representative samples: pending.
- R2 two-distance samples: pending.
- Final correction matrix: pending; no correction has been selected before causal device evidence.
