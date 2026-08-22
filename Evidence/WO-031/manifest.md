# WO-031 evidence manifest

## Execution identity

- Issued baseline: `dfe9e1e875c7020658aa59d22121a7cc0061ac69`
- Execution branch: `codex/wo31-exterior-renderer-correction`
- Diagnostic infrastructure commit: `50aa047c3010be5380393a81c452bcfae206407d`
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

- Diagnostic Fast run: `32581482760` (`success`, PR 17, head `50aa047c3010be5380393a81c452bcfae206407d`).
- Run duration: 1h22m20s (2026-08-22T15:22:08Z through 2026-08-22T16:44:28Z).
- Configure/dependency preparation: 2,208 seconds.
- Production compile/link: 2,393 seconds.
- Cache state: cold/miss; source-download, vcpkg, and qualified build-state cache-hit fields were empty. Cache ABI `ios-fast-v4-xcode16.4-ios16.3-arm64-edd5fbcd7e18a5d33a4de616e039704d860dd513c9140bfb34ccbee5f1003987`.
- Artifact: `OpenMW-iOS-fast-37`, ID `9478916654`, 39,170,007-byte Actions artifact, digest `sha256:6e7e468aca8a2394b86136b1ac3b668d035b719086c5d77f364d156ab17815f0`.
- IPA: `OpenMW-iOS-unsigned.ipa`, 39,136,868 bytes.
- Executable SHA-256: `EC6FD36924513DBF3BF3D61307A4442898EE4314B4D004B04FD352B7A24AA33F`.
- IPA SHA-256: `351F218A48D0054BBEF7C1D7D9C513548E0F0EE93B89BA0C55EA2370D18D66A7`.
- Mach-O UUID: `98121EA4-1B76-30BC-83E0-14326772000A` (64-bit Mach-O, 41 load commands).
- Bundle validation: qualified; bundle ID `org.openmw.ios`, executable `openmw`.
- Temporary diagnostic IPA delivery: `https://tempfile.org/2LM2PxBNN9e/download` (24-hour host).
- Full Qualification: not run.

## Device evidence

- Diagnostic file retrieval: pending.
- R1 representative samples: pending.
- R2 two-distance samples: pending.
- Final correction matrix: pending; no correction has been selected before causal device evidence.
