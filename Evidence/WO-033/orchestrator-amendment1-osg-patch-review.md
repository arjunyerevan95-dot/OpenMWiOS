# WO-033 Amendment 1 OSG patch failure orchestrator review

- Review date: 2026-08-24
- Disposition: **AMENDMENT REQUIRED**
- Amendment 1 implementation: `10b88885e754121931cac2c3bbeed8230a5f997d`
- Worker evidence commit: `ee516855d205ef830823221e0591f3b1ae115619`
- Accepted engineering baseline: `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27` — unchanged

## CI and artifact verification

- Fast run `32723328194`: completed / failure, head `10b88885e754121931cac2c3bbeed8230a5f997d`.
- The run lasted from 2026-08-24 11:43:38Z to 12:31:21Z.
- `Bootstrap exact sources and validate patches` passed, including 146 tests and the complete ordered GL4ES 0001–0009 stack.
- `Incremental configure and dependency preparation` failed during bundled OSG population. Compile, link, package, and device execution were skipped.
- Failure artifact `OpenMW-iOS-fast-failure-53`, ID `9520078724`, contains 460,840 bytes and has digest `sha256:6d14927bc77c0b5b10f668a8be720f4faf063b99fbf201f96910e08d72568a94`.
- No IPA, executable, Mach-O UUID, renderer JSONL, screenshot, or runtime transition evidence exists.
- No second run or renderer correction was started.

## Amendment 1 result

The GL4ES patch-order repair is accepted as execution evidence:

- patch 0009 was rebased against the exact post-0008 pinned source;
- the complete 0001–0009 series applied in production order;
- the hermetic fixture and test passed in CI; and
- the worker recorded byte-identical intended output hashes for all five affected GL4ES files.

These diagnostic changes remain an unaccepted candidate because no product compiled or ran. They do not change the accepted engineering baseline.

## Exact OSG failure classification

The bundled OSG patch is syntactically invalid as a standard unified diff. Blank context lines inside multiple hunks are stored as empty lines instead of lines containing the required context prefix.

Independent local parsing of the exact committed blob `41a52f8c6ccec6e42c08cd830f00c29b76f44a91` establishes:

- `git apply --numstat` reports `corrupt patch at line 33`;
- line 33 is the first empty, unprefixed context line inside the `include/osg/State` hunk;
- the same malformed form recurs in later State and BlendFunc hunks; and
- production `/usr/bin/patch -N -f -p1` partially processed the payload, then reported `No file to patch` and rejected two hunks into `Oops.rej`.

The local OSG checks did not exercise the production patch parser. Their custom `apply_file_patch` helper deliberately treats `line == ""` as blank source context, so it accepts the malformed representation that both Git and production patch tooling reject. Static token checks likewise cannot establish patch materialization.

This is an OSG patch-format/hermeticity failure, not an OSG source incompatibility and not a renderer result.

## Validation note

An outer `git diff --check` can flag a one-space line inside a patch payload as trailing whitespace even though that space is the required unified-diff context prefix. Patch validity must therefore be established with the actual patch parser and pristine pinned input, not by deleting required context prefixes to silence the outer diff checker.

## Disposition

Accept the Amendment 1 report, GL4ES hermeticity result, and CI failure as execution evidence only. Issue WO33 Amendment 2 as READY to:

1. regenerate only the bundled OSG routing/diagnostic patch as a valid unified diff against pristine pinned OSG `01cc2b585c8456a4ff843066b7e1a8715558289f`;
2. preserve the intended patched source and diagnostic semantics;
3. add an exact pristine-input test using the production `/usr/bin/patch -p1` contract, with Git parsing as a preflight; and
4. authorize one replacement Fast diagnostic run because neither earlier run reached compilation or produced an IPA.

If that run produces the intended IPA, resume the original WO33 device-capture and conditional-correction phases. If it fails before producing the IPA, stop without another replacement.

See [WO-033 Amendment 2](../../WorkOrders/WO-033.md).
