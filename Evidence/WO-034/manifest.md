# WO-034 evidence manifest

## Authorization and baselines

- Canonical order: `WorkOrders/WO-034.md` at ControlPlane commit `8d4045c0bfbe1eca3658ffee7aa86313294b17c6`.
- Accepted engineering baseline: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`.
- Evidence-only execution base: `49f5f0bd80e83ef87eaebd3f69c07072796738aa`.
- Execution branch: `codex/wo34-distance-horizon-coverage`.
- Correction commit: `398a91759b1b327b464cf81e41320b8e5f312c9b`.
- Pull request: <https://github.com/arjunyerevan95-dot/OpenMWiOS/pull/20>.

## Source and causal evidence

- [Source and math proof](source-and-math-proof.md)
- [Causal model](causal-model.md)
- Runtime correction: `patches/openmw/0016-ios-cover-perspective-frustum-terrain.patch`
- Deterministic regression suite: `validation/test_wo34_terrain_frustum_coverage.py`
- Pinned OpenMW: `f4bec41444214a7903bebd178389ca22ca13f646`.
- Pinned OSG: `01cc2b585c8456a4ff843066b7e1a8715558289f`.
- Pinned GL4ES: `c9895df34cd466c23bc60c2bd3db3d87e98fcbe7`.

## Accepted predecessor evidence

- WO33 R2 trace session: `9504FA5C-CF45-46D9-908E-2F1838B8B0B9`.
- WO33 R2 trace SHA-256: `6D57F23FEE227608A5285BC52BB0AB386BB4E7ABEE7EB9F9787931E39E8B2C3B`.
- Accepted projection: `2868x1320`, aspect `2.17272727`, vertical FOV `60`, near `1`, far `7168`.
- Accepted deficient terrain coverage: `8276.89`.
- Existing accepted screenshot/device references remain in `Evidence/WO-033/device-capture.md` and `Evidence/WO-029/max-view-distance-observations.md`.

## Local validation

- Focused WO34 tests: 5 passed.
- Full Python discovery: 150 tests executed; 140 passed, 8 skipped, and 2 existing Windows-host launcher errors occurred because `verify-linked-product.sh` is not directly executable as a Win32 binary. No WO34 test failed.
- Git production parser: all ordered OpenMW patches through `0016` reconstructed from pristine pinned source; the reconstructed `renderingmanager.cpp` exactly matched the independently patched source.
- Ordered GL4ES patches `0001..0009`: production `git apply --check` and application passed from pristine pinned source.
- OSG routing/blend patch: production `git apply --check` and application passed from pristine pinned source.
- Reconstructed OpenMW, GL4ES, and OSG trees passed `git diff --check`, apart from already-existing whitespace warnings in GL4ES diagnostic patch `0006`.
- Local CMake aggregate was unavailable because CMake is not installed on the Windows host; CI's pinned aggregate validation is authoritative.

## CI and artifact

- Fast Development run: `32854124142`.
- Event: `workflow_dispatch`, `benchmark_mode=none`.
- Exact run head: `398a91759b1b327b464cf81e41320b8e5f312c9b`.
- Run URL: <https://github.com/arjunyerevan95-dot/OpenMWiOS/actions/runs/32854124142>.
- Result: success; run number `56`; job `97821822621`.
- Created: `2026-08-25T13:34:14Z`; completed: `2026-08-25T14:57:33Z`; total job duration approximately `83m16s`.
- Configure/dependency preparation: `2432s`; production compile/link: `2272s`.
- Cache ABI: `ios-fast-v4-xcode16.4-ios16.3-arm64-8343c2cf178c7bfd5c48b3096c07d5c46bbaa5a7f11c3727425c9b4c5d4b5ef8`.
- Source fingerprint: `046765a82eafa711dcc1b1522de5242f16b7d61a5169361b0d25a3083b4bdeaf`.
- Source-download, vcpkg, and build-state caches missed; no cache retry or redesign was attempted.
- Artifact name: `OpenMW-iOS-fast-56`; artifact ID `9568728950`; wrapper size `39,187,598` bytes.
- Artifact wrapper SHA-256: `6A3661D67F14838D74A8AE3B29F5FAB77E6FC3086C727D4ABE0DA773B058A6BC`.
- IPA: `OpenMW-iOS-unsigned.ipa`, `39,154,460` bytes, SHA-256 `EE9631158A008A2304A3CA766F2DDD9BFBDA2DD9ED6A9775297DE9FC3DEDB043`.
- Executable: `openmw`, `117,474,728` bytes, SHA-256 `CA6F0BDDA065C64E933B8912474C83ADD97E9532481EF4661A8382BE9AE79AC4`.
- Mach-O UUID: `55DF5E1E-3ED9-399F-A083-A191DCD52B3B`.
- Bundle ID/executable and resource-relocation validation passed.
- Temporary device-delivery URL: <https://litter.catbox.moe/k4xxi2.ipa> (72-hour Litterbox retention; non-authoritative delivery convenience).
- Full Qualification: not run.

## Device evidence

- [Device capture](device-capture.md)
- The user installed and exercised the exact WO34 IPA at maximum view distance.
- Seven screenshots were supplied from the exterior session; identities and hashes are recorded in `device-capture.md`.
- Large fog-colored/white terrain gaps: unchanged.
- Sharp blue horizon/cutoff band: unchanged.
- Pure-black distant silhouettes: unchanged and explicitly clarified by the user as a pre-existing part of the original reported distance weirdness, not a new WO34 regression.
- No crash was reported during the captured exterior session.
- Device outcome: Route A's visible causal prediction was falsified.

## Scope preservation

No change was made to camera near/far distance, user view distance, fog, clear color, active-grid policy, cell loading, OSG, GL4ES, SDL, shaders, foliage, particles, touch, data paths, CI, or canonical ControlPlane records.
