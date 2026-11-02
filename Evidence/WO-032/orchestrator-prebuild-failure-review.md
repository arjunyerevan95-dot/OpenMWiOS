# WO-032 pre-build failure orchestrator review

- Review date: 2026-08-23
- Disposition: **AMENDMENT REQUIRED**
- Diagnostic implementation: `4b626d80dcf58bc5768c71f2e043c9f4edec6b07`
- Worker evidence commit: `271df132cb17a8897e69b6d2ae31cde411a26e1b`
- Accepted engineering baseline: `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27` — unchanged

## CI verification

- Run `32623652029`: completed / failure, head `4b626d80dcf58bc5768c71f2e043c9f4edec6b07`.
- Failure occurred during Python regression validation before production compilation.
- Failure artifact: `OpenMW-iOS-fast-failure-44`, ID `9489106339`, 6,496 bytes.
- Artifact digest: `sha256:99b85d6fbf6f4981ead3e1fb07c58c76fb23a74e5ef0c98c36155673174b9045`.
- Run `32625672214`: completed / cancelled, no artifact. It was stopped immediately after the evidence-only push.
- No IPA, executable, Mach-O UUID, device result, renderer correction, or Full Qualification exists for WO32 yet.

## Failure classification

The production patch path is not the failure boundary. CI successfully applied all ordered OpenMW patches `0001`–`0015` and GL4ES patches `0001`–`0008`.

Both failing tests implement a local `apply_file_patch` parser. Required cleanup of whitespace-only added blank lines made some embedded unified-diff context lines empty. The helpers handle context lines beginning with a space, additions, removals, and no-newline markers, but do not handle `line == ""`. They therefore fail to consume the corresponding blank source line and assert on misaligned subsequent context.

The narrow repair is evidence-backed: when a patch-hunk line is empty, each helper must assert that the current source line is blank, append/preserve it, and advance the source cursor. A synthetic compiler-independent regression must cover this case so Windows cannot silently skip the only proof.

## Source review

- Diagnostic source changes are confined to the authorized renderer-observability paths and deterministic dependency patches.
- Touch and canonical ControlPlane source diffs are empty.
- Dependency revisions are unchanged.
- `git diff --check 626b332..4b626d8` passes.
- No renderer correction was attempted.

## Evidence discrepancy

The worker manifest's “Referenced WO-031 evidence” section transcribes the prior WO31 IPA and executable hashes incorrectly. Canonical WO31 evidence remains authoritative:

- Correct WO31 IPA SHA-256: `824395081D76CBC7B5B164B4FC9CDC4CEBB752D7D7D451E011246B42674B6857`.
- Correct WO31 executable SHA-256: `0B19227B2E7950307385BE5B467D36C7D2F01AC6AD05FFE0B74C239879314447`.

This transcription error does not affect the WO32 CI failure classification. The worker-authored manifest is preserved as execution evidence rather than silently rewritten.

## Disposition

Issue WO32 Amendment 1 as READY. Authorize only the two test-helper repairs, synthetic blank-context regressions, and one replacement Fast diagnostic run. If that run produces the IPA, resume the already-authorized WO32 device and conditional correction phases without changing renderer scope.

See [WO-032 Amendment 1](../../WorkOrders/WO-032.md).
