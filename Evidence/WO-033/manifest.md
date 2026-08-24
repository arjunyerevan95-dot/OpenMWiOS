# WO-033 evidence manifest

## Baselines

- Accepted product baseline: `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27`
- Investigation continuation: `164abe4ba2becf46ea043811963ac28195d29bcd`
- Execution branch: `codex/wo33-blend-state-transition`
- Original ControlPlane order: `WorkOrders/WO-033.md` at `6dab03257a9cac213c377203f16d5fdbec08e74d`
- Amendment 1 ControlPlane order: `WorkOrders/WO-033.md` at `6d4e7a8b73be44553a3552386ff4398d2435394e`
- Durable predecessor decision: `Decisions/DEC-012.md`

## Local evidence

- [Transition model](blend-transition-model.md)
- [Linked route proof](linked-route-proof.md)
- [Device capture](device-capture.md)
- [Execution report](report.md)
- Focused tests: `validation/test_wo33_blend_transition_diagnostics.py`
- Compiled sequence fixture: `validation/fixtures/wo33_blend_transition_fixture.c`
- Hermetic pinned patch-input fixture: `validation/fixtures/gl4es-c9895df-wo33-patch-inputs.zip`
- Fixture SHA-256: `1601090e10fda84c4e9b8343219deea1ad5c4398638005f22977e8f7e5c6bda6`
- Original diagnostic commit: `f0427d8d40ea66a86f78f127082581bf10eae883`
- Original evidence commit: `a54c7f832138c4719a000a6d3dc0fce5fe98cddd`
- Amendment 1 patch-hermeticity commit: `10b88885e754121931cac2c3bbeed8230a5f997d`

## Ordered GL4ES patch hashes in Amendment 1

- `0001-avoid-darwin-symbol-aliases.patch`: `0350c7c9298515df212f66c7626a9791c1d6832599600b89a70af57aa2ea28ab`
- `0002-handle-mainless-linked-shaders.patch`: `92491968f110275bf1c4dde479d7b999e9011d7018dac71728c244bfa23a0a9a`
- `0003-normalize-openmw-debug-uniform-initializer.patch`: `0b3a91711f33cf90b0d50a65b89ea27775804a0e5dbf2d2a1894f5f48649a93d`
- `0004-log-openmw-debug-shader-boundary-once.patch`: `6593aec9c6c52008a57c94ab1ac37ab864520103d82a94f318fc81d5aba602dc`
- `0005-map-external-default-drawable.patch`: `04afc57e305114ed8b30ffe9718bb74906d4988f108a3b68c0f591f7f11a7dfa`
- `0006-ios-file-backed-renderer-diagnostics.patch`: `7195fc637e2a4749daa94c243c3b46f7b46cf996e5aa60d26bc869c3d90b4349`
- `0007-ios-renderer-diagnostics-observable-paths.patch`: `75af307b3d2835a60173cdb61ed05888912e9ade3706240a67ab5545ca171bb4`
- `0008-ios-renderer-diagnostics-targeted-boundaries.patch`: `7b7125336eb6bd34478687d24db34e068a975d9c01739f4c4e48ac48a894c1c9`
- `0009-ios-blend-transition-diagnostics.patch`: `9e44e6f8013b52bcf2efa491008f5479f38820a3c6e3869c17f1275cca047fe1`

## CI and artifact evidence

### Original run

- PR: https://github.com/arjunyerevan95-dot/OpenMWiOS/pull/19
- Fast run: https://github.com/arjunyerevan95-dot/OpenMWiOS/actions/runs/32701930506
- Result: failed in GL4ES patch bootstrap before compile.
- Failure artifact: `OpenMW-iOS-fast-failure-52`, ID `9510853902`, ZIP SHA-256 `d0bc419b0315ae1909fca6f8c9e749f31ea04f891c095786c55c2ed5d663a5c2`.

### Amendment 1 replacement run

- Fast run: https://github.com/arjunyerevan95-dot/OpenMWiOS/actions/runs/32723328194
- Job: `97419193887`, `Real OpenMW arm64 iPhone development build`.
- Candidate: `10b88885e754121931cac2c3bbeed8230a5f997d`.
- Result: failed during OSG population after source validation and ordered OpenMW/GL4ES patch gates passed.
- Failure boundary: `ios/cmake/apply-osg-patch.cmake` rejected the OSG routing patch with `No file to patch`, two ignored hunks, and `Oops.rej`; CMake exited through OSG populate error 65.
- Failure artifact: `OpenMW-iOS-fast-failure-53`, ID `9520078724`, digest `sha256:6d14927bc77c0b5b10f668a8be720f4faf063b99fbf201f96910e08d72568a94`.
- Cache ABI: `ios-fast-v4-xcode16.4-ios16.3-arm64-2eda39a9091108d154477354b5b98761d2712745417d9feec4d4b7f41bd0e538`.
- Cache source: `0f846919acced2f4fb9837fa84f3652e183898404ada19343e673bf71f6367e2`.
- Source SHA: `e7d881a9761d3607b22ea5928305d4cb60a0ea0f`.
- All cache-hit fields were empty; benchmark mode was `none`.
- No executable, IPA, Mach-O UUID, bundle validation, installation, or device capture exists for WO-033.

## Scope and stop

WO-033 changed bounded diagnostics, patch context, and focused validation only. No blend, factor, depth, shader, texture, draw, foliage, distance/horizon, touch, data-path, dependency-version, accepted-runtime, or canonical ControlPlane change was made. The one Amendment 1 replacement build failed before IPA, so Stop Condition G applies and no second run is authorized.
