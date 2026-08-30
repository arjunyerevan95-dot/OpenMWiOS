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
- [Compact transition capture](blend-transition-capture.md)
- [Execution report](report.md)
- Focused tests: `validation/test_wo33_blend_transition_diagnostics.py`
- Compiled sequence fixture: `validation/fixtures/wo33_blend_transition_fixture.c`
- Hermetic pinned patch-input fixture: `validation/fixtures/gl4es-c9895df-wo33-patch-inputs.zip`
- Fixture SHA-256: `1601090e10fda84c4e9b8343219deea1ad5c4398638005f22977e8f7e5c6bda6`
- Original diagnostic commit: `f0427d8d40ea66a86f78f127082581bf10eae883`
- Original evidence commit: `a54c7f832138c4719a000a6d3dc0fce5fe98cddd`
- Amendment 1 patch-hermeticity commit: `10b88885e754121931cac2c3bbeed8230a5f997d`
- Amendment 2 OSG-patch repair and diagnostic candidate: `fd300ba12351252ece9e7b481c0b2d366228f9e8`
- Conditional correction commit: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`

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

### Amendment 2 diagnostic run

- Fast run: https://github.com/arjunyerevan95-dot/OpenMWiOS/actions/runs/32742643722
- Candidate: `fd300ba12351252ece9e7b481c0b2d366228f9e8`
- Result: success; production compile/link, bundle validation, and packaging passed.
- Artifact: `OpenMW-iOS-fast-54`, ID `9528845874`.
- Artifact digest: `sha256:eb8c96d038e8e67a7f22b07b0c58f08e2ef8c4f7898b085c370b4acea153c306`.
- IPA SHA-256: `9A5CD26DAAE7FF5C4B56B630EB5BAE148A2A80B120D2466B415BA9C89E87ED5B`.
- Executable SHA-256: `05C86BB43574092B1D0AF26E7517DCFF1E576ABAC9AAC1D84B59F255FCED17FB`.
- Mach-O UUID: `98B76201-B444-3844-8AB2-E5DF9B61B953`.
- Device trace: installed and launched; smoke remained visibly opaque as expected for diagnostics; bounded trace proved the OSG/GL4ES cache split.

### Conditional correction run

- Fast run: https://github.com/arjunyerevan95-dot/OpenMWiOS/actions/runs/32771773194
- Candidate: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`.
- Result: success; production compile/link, bundle validation, and packaging passed.
- Job: `97573507624`.
- Artifact: `OpenMW-iOS-fast-55`, ID `9538962155`, size 39,184,614 bytes.
- Artifact digest: `sha256:1af36e00a09f9056bf1bb63eaf0c4c09a35e6ed14155009425913717f9840be7`.
- IPA SHA-256: `34EB8106C60138F30DA8B59083CA026FDA013F68870DDC658C1584B6E939AC4E`.
- Executable SHA-256: `C759B9D09DF6A2CFFE7657839BD3DB25999A399743E811A7846A406A5826874C`.
- Correction trace SHA-256: `6D57F23FEE227608A5285BC52BB0AB386BB4E7ABEE7EB9F9787931E39E8B2C3B` (445 records; session `9504FA5C-CF45-46D9-908E-2F1838B8B0B9`).
- Device result: qualified success; smoke, spell, and foliage transparency visibly fixed; no crash reported.

## Scope and stop

WO-033 diagnostics first changed observation only. The Amendment 2 trace then authorized one minimal blend correction: on the Apple/manual route only, OSG reasserts a cache-matching `GL_BLEND` request through GL4ES while preserving OSG's cache-match return value and leaving GL4ES's normal state-change suppression authoritative. The correction trace records all four targeted smoke records at `blend=1` and none at `blend=0`; matching screenshots visibly confirm smoke, spell, and foliage transparency. No factor, depth, shader, texture, draw-time force, distance/horizon, touch, data-path, dependency-version, workflow, or canonical ControlPlane change was made. Stop condition: **H — qualified success**. Remaining distance/horizon behavior is deferred for orchestrator review.
