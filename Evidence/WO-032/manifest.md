# WO-032 evidence manifest

## Execution identity

- Original ControlPlane issue commit: `9100edc9ee3f9dc89ec6adafc28ec72a77ed48a8`.
- Amendment 1 ControlPlane commit: `6cae3de751382cf764defc8ab783b338e2351d4a`.
- Investigation continuation / issued execution baseline: `626b3321ee7ce83f82d22a707dfa4f9177cf6fff`.
- Execution branch: `codex/wo32-targeted-renderer-boundary`.
- Accepted product baseline remains `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27`; WO-032 does not alter accepted state.
- Targeted diagnostic implementation: `4b626d80dcf58bc5768c71f2e043c9f4edec6b07`.
- Amendment 1 parser repair and replacement diagnostic candidate: `79231c0fbf9293388f8f47456f8c2a2696291633`.
- R1 correction source candidate: `1625713b949ddb0cde5471feead75f29fedadfaa`.
- Canonical ControlPlane files changed by the worker: none.
- Touch/data-path/workflow changes: none.

## Referenced evidence and sampling design

- [Sampling model](sampling-model.md)
- [R1 targeted evidence](renderer-r1-targeted.md)
- [R2 targeted evidence](renderer-r2-targeted.md)
- [Replacement diagnostic device capture](device-capture-analysis.md)
- [WO-031 R1 evidence](../WO-031/renderer-r1-alpha-particles.md)
- [WO-031 R2 evidence](../WO-031/renderer-r2-distance-fog.md)
- [WO-031 diagnostic channel](../WO-031/diagnostic-channel.md)

## Superseded pre-build attempt

- Fast run `32623652029` stopped during regression validation before production compilation.
- Failure artifact: `OpenMW-iOS-fast-failure-44`, ID `9489106339`, digest `sha256:99b85d6fbf6f4981ead3e1fb07c58c76fb23a74e5ef0c98c36155673174b9045`.
- Amendment 1 repaired only the two test-side blank-context parsers and added compiler-independent regressions.
- Evidence-triggered run `32625672214` was cancelled immediately and produced no artifact.

## Replacement diagnostic build

- Fast run: `32627872506`.
- Job: `97165936192`.
- Commit: `79231c0fbf9293388f8f47456f8c2a2696291633`.
- Result: success.
- Run window: 2026-08-23 08:17:40Z–09:15:49Z (58m09s job duration).
- Dependency preparation: 27m48s.
- Production compile/link: 26m49s.
- Package/upload: pass.
- Artifact: `OpenMW-iOS-fast-47`, ID `9490874268`, digest `sha256:d32529f56a7d495ffb689db40781aa4cf088517213579aa2b7e15ad132d25675`.
- IPA size: 39,147,174 bytes.
- IPA SHA-256: `90C6AA65BBAADE4FF1C0D13D2BC7E124E1EBD119D2A91C513E80FA39C802A942`.
- Executable SHA-256: `BA7E32C8A3E5BBBFF0D38DBE89606D0D009C562E323F4F9B206C8BEE6513F316`.
- Mach-O UUID: `1173DA95-B273-3CE7-948D-BA2EDA504701`.
- Full Qualification: not run.

## Device evidence

- Device JSONL SHA-256: `F2D73B5C697E326EDA889244366281AB9A40752E3FD6C8EE7D5C14D779FB3B02`.
- JSONL size/records: 100,514 bytes / 317 records.
- Session: `39288F15-DB13-4C3D-AFC8-DCE9DF45E5C1`.
- The five supplied screenshots and their hashes are recorded in [device-capture-analysis.md](device-capture-analysis.md).
- User clarification: all supplied distance observations used maximum view distance. There is no qualified two-distance R2 comparison.
- Visible results: opaque foliage cards, blocky chimney smoke, white/blank distance, sharp blue horizon, opaque blue spell cards, and opaque orange fire cards remain present.

## R1 result

- Foliage target: hit, `textures/tx_bc_moss.dds`, texture 292 / program 21.
- Chimney-smoke target: hit, `textures/tx_smokealpha00a.dds`, texture 129 / program 9.
- Opaque control: hit, texture 134 / program 12.
- Smoke reaches the draw as a translucent DXT5 asset with standard alpha factors, disabled depth writes, and an alpha-producing/discarding fragment shader, but GL4ES records `blend=0`.
- The linked diagnostic executable defines GL4ES core wrappers while importing unprefixed `_glEnable`, `_glDisable`, and `_glBlendFunc` from native GLES.
- Earliest proven smoke/particle divergence: OSG direct core state calls mutate native GLES while GL4ES owns program conversion and draw submission, so GL4ES does not observe the blend enable.
- The captured foliage target is already opaque before raster output; its distinct root cause remains unresolved.

## R2 result

- One effective maximum-distance generation was captured: selected/far 7168, fog start 2007.04, color `0.960784,0.921569,0.878431,1`, scale `0.000193762404`.
- OpenMW intent, OSG application, GL4ES receipt, and eight of nine sampled live programs agree on those values.
- Program 81 lacks builtin fog locations, but its render purpose is not established.
- No second materially different stable view-distance generation exists in the supplied capture.
- R2 remains insufficient and no distance/fog/content/cull/sky/clear/depth correction was made.

## R1 correction source and local validation

- Commit `1625713b949ddb0cde5471feead75f29fedadfaa` routes OSG's two core mode-application sites and ordinary `BlendFunc::apply` through GL4ES only for Apple manual-init builds.
- Non-iOS OSG paths retain their direct GL calls.
- No device resolution, FBO, shader, touch, data-path, dependency revision, or workflow behavior was changed.
- OSG patch apply check: pass.
- Focused WO-032 tests: 8 passed, 1 skipped on the Windows host because no C compiler is present.
- Aggregate tests excluding the POSIX-only linked-product verifier: 129 passed, 6 skipped.
- Full local discovery: 131 tests; the only two errors are the known Windows `WinError 193` attempts to execute a POSIX shell verifier. CI/macOS is authoritative for those checks.
- `git diff --check`: pass.

## Final correction Fast result

- Fast run: `32634038454`.
- Job: `97181008153`.
- Commit: `1625713b949ddb0cde5471feead75f29fedadfaa`.
- Run window: 2026-08-23 10:32:42Z–12:33:10Z (2h00m28s).
- Conclusion: cancelled by GitHub's two-hour job limit.
- Source/bootstrap, ordered patch application, and patch validation: pass.
- Cache ABI hash: `e450a18045485e1ccbeb921b8d7c3abff8faaf3ebaa70756dfb02b8e53128786`.
- Source-download cache: restored.
- vcpkg binary cache: miss.
- qualified incremental build-state cache: miss.
- GL4ES: rebuilt successfully during dependency preparation.
- Cancellation boundary: `Incremental configure and dependency preparation` after 1h58m49s in that step.
- Production OpenMW compile/link: skipped.
- Bundle/package/upload: skipped.
- Executable/IPA/artifact: none.
- Failure-diagnostics upload: skipped by workflow cancellation.
- No second correction build was triggered.
- Full Qualification: not run.

## Disposition

- Stop condition: **G — build budget exhausted**.
- The R1 smoke/particle cause is proven and a narrow source correction exists, but no production artifact or device qualification exists for that correction.
- The foliage and R2 distance/horizon causes remain unresolved.
- Accepted project state is unchanged pending orchestrator review.
