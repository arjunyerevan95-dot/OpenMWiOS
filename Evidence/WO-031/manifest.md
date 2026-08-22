# WO-031 evidence manifest

## Execution identity

- Issued baseline: `dfe9e1e875c7020658aa59d22121a7cc0061ac69`
- Execution branch: `codex/wo31-exterior-renderer-correction`
- Diagnostic infrastructure commit: `50aa047c3010be5380393a81c452bcfae206407d`
- Amendment 1 ownership repair commit: `8140aa4ee2af00e335b9212605524883571e65ed`
- Renderer correction commit(s): pending evidence; none selected
- Final stop condition: **B — diagnostic channel insufficient, and F — accepted touch regression**

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

- Installation: successful; exact diagnostic IPA launched.
- Launch result: loading screen visible for approximately half a second, followed by a user-observed hard crash.
- Diagnostic file: 253 bytes, SHA-256 `16F3B558437016BE03447688D3D7B26465FCF9B466C897B5B0D01F951139851A`.
- Diagnostic session: `C0912F7F-958B-4FC5-BA81-379A75345C7D`.
- Records: one `session/startup`; zero OpenMW records; zero GL4ES records.
- Native crash report/symbolication: not available; live device transport was not required or used.
- R1 representative samples: not reached.
- R2 two-distance samples: not reached.
- Renderer correction: none selected or attempted.
- Build budget: one diagnostic Fast run consumed; no second/final run triggered.
- Strongest causal conclusion: persistent autoreleased Foundation path/session objects in the non-ARC diagnostics translation unit become invalid after the startup autorelease pool drains; first later record use is the earliest source-backed crash boundary.
- Existing accepted renderer/touch/data-path baseline was not requalified because the diagnostic candidate crashed before gameplay.

## Amendment 1 replacement diagnostic candidate

- Amendment activation ControlPlane commit: `3265016fd1d583e98bebf1379eea95853a85674e`.
- Ownership repair commit: `8140aa4ee2af00e335b9212605524883571e65ed`.
- Repair: under the production translation unit's MRC semantics, `sPath` and `sSession` now take explicit copied process-lifetime ownership. Schema, path, budgets, correlations, probes, and renderer state are unchanged.
- Focused ownership/diagnostic tests: 11/11 pass. The new test also synthesizes the rejected raw-autoreleased assignments and proves the ownership predicate rejects them.
- Full Python discovery: 114 pass, 4 skip, 2 pre-existing Windows-only errors executing the POSIX linked-product verifier; no WO31 test failed.
- Replacement diagnostic Fast run: `32588069228` (`success`, head `8140aa4ee2af00e335b9212605524883571e65ed`).
- Run duration: 14m12s. Configure/dependency preparation: 160 seconds. Production compile/link: 142 seconds.
- Cache: source downloads and vcpkg exact hits; qualified incremental state restored through the prior matching key/prefix, while the new exact source-delta key reported `build_state_cache_hit=false`.
- Artifact: `OpenMW-iOS-fast-39`, ID `9479709482`, Actions size 39,168,891 bytes, digest `sha256:7c085408be58c8187afda97f45462291c4fb552b00d959be2605c0c628f492d2`.
- IPA: 39,135,179 bytes, SHA-256 `498D0285103C0F3664F44F35004FF1ADD8D463A6ACB6F4E5C11C4CE682A6C9CD`.
- Executable SHA-256: `5AA12617933D031E25D06C590BEA15507CC7CA863DB63EEBDC91FDBC994F2D40`.
- Mach-O UUID: `56699F22-BA7C-3E7D-B5B6-0B9CEBB0AFC8`.
- Bundle validation: qualified; bundle ID `org.openmw.ios`, executable `openmw`.
- Temporary replacement IPA delivery: `https://tempfile.org/mKqmrMyMQoA/download` (24-hour host).
- Full Qualification: not run.
- Replacement diagnostic build budget: 1 of 1 consumed. Final renderer-correction build budget: 0 used.
- Replacement device launch: passed the repaired lifetime boundary, reached the exterior, and did not reproduce the diagnostic hard crash.
- Replacement diagnostic file: 7,028 bytes; SHA-256 `5A6113914B4D90EEF274588E8914CA01D37F53BFB4CAB45DAE22F8E8ABD5FAC0`; session `02306F28-5A6E-45AB-ADAC-414235769F83`.
- Replacement records: 23 total = 1 iOS startup + 22 OpenMW; 0 GL4ES. Families: 21 `r1.state`, 1 `r1.asset`, 1 `session`; 0 R2.
- The only bound asset record was the non-translucent control texture `textures/_land_default.dds` (`category=3`); the captured state did not correlate a representative defective foliage/particle draw through GL4ES.
- Visible exterior result: foliage cards, white/blank regions, and the blue horizon band remained present in all supplied views.
- Touch smoke regression: short-tap Menu did not open the menu; long-press Menu still entered the touch editor. No touch source changed in the candidate, so the cause is unclassified, but the observed behavior fails the accepted touch baseline and triggers Condition F.
- Screenshot evidence hashes:
  - `2-Photo-2.jpg`: `AD1388E735EC312A68394919C3EF6D0765E2D961EDC24C7784E3707D8A63D05D`
  - `3-Photo-3.jpg`: `DB0B547FB6301CAF6A9B3CDEBAA4C876754B2BA12876D92EB2F5CE0ABC9E361F`
  - `4-Photo-4.jpg`: `0F950FE36B95D6A18752CDE18D609A6C27164824707DE0DC0257B284FA6A5C63`
  - `5-Photo-5.jpg`: `70C2C020A0145758C574DFFBD0852E6BE2743B3E53E6104175CE675C996CB12E`
  - `6-Photo-6.jpg`: `A24C64D8DDCA813DE39BCE2C147DB47D16983020C4F47BBABC6026A4A8643EB9`
  - `7-Photo-7.jpg`: `DE1DAB725B95A0A05B844B8F4FE41CC80CC40F11ADCD820ABC0B6137F7F8BEE1`
- Amendment 1 qualification gate: failed because later GL4ES records were absent and accepted touch behavior regressed.
- Renderer correction: none. Final renderer-correction build budget remains 0 used.
