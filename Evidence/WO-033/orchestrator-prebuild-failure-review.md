# WO-033 pre-build failure orchestrator review

- Review date: 2026-08-24
- Disposition: **AMENDMENT REQUIRED**
- Diagnostic implementation: `f0427d8d40ea66a86f78f127082581bf10eae883`
- Worker evidence commit: `a54c7f832138c4719a000a6d3dc0fce5fe98cddd`
- Accepted engineering baseline: `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27` — unchanged

## CI verification

- Fast run `32701930506`: completed / failure, head `f0427d8d40ea66a86f78f127082581bf10eae883`.
- The run lasted 1 minute 34 seconds and failed in `Bootstrap exact sources and validate patches`.
- GL4ES patch `0009-ios-blend-transition-diagnostics.patch` failed to apply at `src/gl/enable.c:111` and `src/gl/listdraw.c:727` after the preceding production patch stack.
- Compilation, link, packaging, upload, and device execution never began. No IPA, executable, Mach-O UUID, renderer JSONL, screenshot, or runtime transition evidence exists.
- Failure artifact `OpenMW-iOS-fast-failure-52`, ID `9510853902`, contains 4,008 bytes and has digest `sha256:d0bc419b0315ae1909fca6f8c9e749f31ea04f891c095786c55c2ed5d663a5c2`.
- No duplicate or correction run was started.

## Source and scope review

- The diagnostic commit changes only the authorized iOS/OSG/GL4ES renderer-observation paths, the new bounded transition fixture/tests, and WO33 evidence.
- The transition ring remains dynamically smoke-targeted and bounded. The reviewed diff does not force blending, factors, depth, shaders, textures, or draw behavior.
- No touch, foliage, distance/horizon, data-path, dependency-revision, workflow, or accepted-runtime correction was made.
- `git diff --check 164abe4..f0427d8` passes.
- The evidence commit modifies only the five WO33 evidence records.
- The worker did not modify canonical `CURRENT_STATE`, `WorkOrders`, or `Decisions`. Existing unrelated worker-worktree files remain outside this review.

The diagnostic source is preserved as an unaccepted execution candidate. It has not compiled or run and is not part of the accepted engineering baseline.

## Failure classification

This is a patch-order hermeticity failure, not a renderer result. The worker validated patch 0009 against a dirty verification checkout. Production correctly applied the earlier GL4ES patches first, then rejected stale contexts in the two files those earlier patches had already changed.

The WO33 test module reconstructs only the diagnostic bridge files across patches 0006–0009 and otherwise inspects patch text. It does not apply the complete GL4ES 0001–0009 series to a pristine snapshot of pinned revision `c9895df34cd466c23bc60c2bd3db3d87e98fcbe7`. Consequently, local tests could pass while the production stack could not be materialized.

No evidence selects any transition-model alternative. The first invalid smoke blend-state transition remains unproven, and a renderer correction remains unauthorized.

## Disposition

Accept the worker report and CI failure as execution evidence only. Issue WO33 Amendment 1 as READY to:

1. rebase only patch 0009's stale `enable.c` and `listdraw.c` contexts against the exact pristine pinned GL4ES tree after patches 0001–0008;
2. add or strengthen a deterministic clean-tree ordered-patch validation so a dirty dependency checkout cannot satisfy the gate;
3. preserve the diagnostic behavior and all original renderer prohibitions; and
4. authorize one replacement Fast diagnostic run because the original run never compiled or produced an IPA.

If the replacement produces the intended IPA, resume WO33's existing device-capture and conditional-correction phases. If it fails before producing that IPA, stop without a second replacement run.

See [WO-033 Amendment 1](../../WorkOrders/WO-033.md).
