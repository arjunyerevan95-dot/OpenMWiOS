# WO-033 evidence manifest

## Baselines

- Accepted product baseline: `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27`
- Investigation continuation: `164abe4ba2becf46ea043811963ac28195d29bcd`
- Execution branch: `codex/wo33-blend-state-transition`
- Control-plane order: `WorkOrders/WO-033.md` at `6dab03257a9cac213c377203f16d5fdbec08e74d`
- Durable predecessor decision: `Decisions/DEC-012.md`

## Local evidence

- [Transition model](blend-transition-model.md)
- [Linked route proof](linked-route-proof.md)
- [Device capture](device-capture.md)
- [Execution report](report.md)
- Focused tests: `validation/test_wo33_blend_transition_diagnostics.py`
- Compiled sequence fixture: `validation/fixtures/wo33_blend_transition_fixture.c`

## CI/artifact evidence

- Diagnostic candidate commit: `f0427d8d40ea66a86f78f127082581bf10eae883`
- Pull request: [#19](https://github.com/arjunyerevan95-dot/OpenMWiOS/pull/19)
- Fast Development run: [32701930506](https://github.com/arjunyerevan95-dot/OpenMWiOS/actions/runs/32701930506)
- Run result: **failure** in `Bootstrap exact sources and validate patches`; production compile never started.
- Exact failure: GL4ES patch 0009 did not apply at `src/gl/enable.c:111` and `src/gl/listdraw.c:727` after the preceding production patch stack.
- Failure artifact: `OpenMW-iOS-fast-failure-52`, artifact ID `9510853902`, ZIP SHA-256 `d0bc419b0315ae1909fca6f8c9e749f31ea04f891c095786c55c2ed5d663a5c2`.
- Targeted failure artifact remains available from GitHub Actions for its seven-day retention window; decisive failure lines are preserved in this manifest and the execution report.
- Cache fingerprint: ABI `ios-fast-v4-xcode16.4-ios16.3-arm64-2eda39a9091108d154477354b5b98761d2712745417d9feec4d4b7f41bd0e538`; source `18e243db8a2cd23af4302969f31216fce83fde8ac910c6e76ccb2bc7324c91bc`.
- No executable, IPA, Mach-O UUID, bundle validation, installation, or device capture exists for WO-033.

## Scope

WO-033 changed bounded diagnostics and tests only. No blend, factor, depth, shader, texture, draw, foliage, distance/horizon, touch, data-path, dependency-version, or accepted-runtime correction was made. Build budget is exhausted; execution stopped at the orchestrator-review gate.
