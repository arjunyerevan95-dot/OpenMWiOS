# WO-031 execution report

## Outcome

**BLOCKED / STOPPED — Amendment 2 Conditions B (diagnostic channel insufficient) and G (diagnostic build budget exhausted).**

The original diagnostic candidate hard-crashed and was rejected. Amendment 1 repaired its proven MRC ownership defect but did not observe GL4ES. Amendment 2 proved the bridge and active lower-renderer probes on the exact shipped product and device. Its bounded file identifies real defective R1 assets and confirms GL4ES receives the intended R2 fog values, but probe-budget ordering prevents the required representative R1 draw and exterior R2 applied-program correlations. The one Amendment 2 diagnostic build is consumed, so no renderer correction was selected or attempted.

## Execution identity

- Branch: `codex/wo31-exterior-renderer-correction`
- Issued baseline: `dfe9e1e875c7020658aa59d22121a7cc0061ac69`
- Diagnostic source commit: `50aa047c3010be5380393a81c452bcfae206407d`
- Evidence-only commit before device result: `b218dbb`
- Fast run: `32581482760` (success)
- Artifact: `OpenMW-iOS-fast-37`, ID `9478916654`
- IPA SHA-256: `351F218A48D0054BBEF7C1D7D9C513548E0F0EE93B89BA0C55EA2370D18D66A7`
- Executable SHA-256: `EC6FD36924513DBF3BF3D61307A4442898EE4314B4D004B04FD352B7A24AA33F`
- Mach-O UUID: `98121EA4-1B76-30BC-83E0-14326772000A`
- Full Qualification: not run

### Amendment 1 identity

- Ownership repair commit: `8140aa4ee2af00e335b9212605524883571e65ed`
- Fast run: `32588069228` (success, 14m12s)
- Artifact: `OpenMW-iOS-fast-39`, ID `9479709482`
- IPA SHA-256: `498D0285103C0F3664F44F35004FF1ADD8D463A6ACB6F4E5C11C4CE682A6C9CD`
- Executable SHA-256: `5AA12617933D031E25D06C590BEA15507CC7CA863DB63EEBDC91FDBC994F2D40`
- Mach-O UUID: `56699F22-BA7C-3E7D-B5B6-0B9CEBB0AFC8`
- Replacement diagnostic build budget: 1 of 1 consumed
- Final renderer-correction build budget: 0 used

## Original diagnostic result

The retrieved `Documents/OpenMW/renderer-diagnostic.jsonl` contains exactly one 253-byte startup record with session `C0912F7F-958B-4FC5-BA81-379A75345C7D`. File SHA-256 is `16F3B558437016BE03447688D3D7B26465FCF9B466C897B5B0D01F951139851A`.

Counts:

- session records: 1
- OpenMW intended-state records: 0
- GL4ES received/applied records: 0
- R1 representative records: 0
- R2 representative records: 0

This proves the app-owned Documents path, JSON schema, initial file creation, and initial write. It also proves the crash occurred before the diagnostics channel could commit its first later renderer record.

## Original diagnostic crash boundary

The new Objective-C++ bridge stores `sPath` and `sSession` as persistent raw `NSString*` globals. `openmw_ios_renderer_diag_begin()` wraps initialization in `@autoreleasepool`; `beginLocked()` assigns autoreleased results from `stringByAppendingPathComponent:` and `NSUUID.UUID.UUIDString`; the pool then drains. The OpenMW target does not enable ARC in repository CMake/Xcode configuration. CI compiled the new file as Objective-C++ and showed no explicit ARC option in the visible invocation. A later renderer record calls `appendRecord()` with the now-invalid persistent Foundation objects.

The observed sequence is exactly consistent with that ownership defect:

1. startup objects are alive inside the pool;
2. initial record writes successfully;
3. pool drains;
4. loading/rendering begins;
5. first later record dereferences persistent objects;
6. process hard-crashes before a second record is committed.

No native crash report was available at the original worker stop. The later orchestrator review matched a supplied IPS to the artifact UUID and symbolicated the decisive `objc_retain` → diagnostics-record boundary, upgrading this to a proven diagnostic lifetime cause (DEC-008).

## R1 and R2 disposition

- R1 earliest invalid renderer boundary: **unknown**; Amendment 1 captured OpenMW state but no representative intended/applied GL4ES correlation.
- R2 earliest invalid renderer boundary: **not captured / unknown**; Amendment 1 produced no R2 or GL4ES records.
- Shared alpha/fog cause: **not established**.
- Renderer fixes: **none**.
- Accepted renderer baseline: exterior defects remained visible; short-tap Menu regressed despite an empty touch-source diff.

## Amendment 1 device result

- Launch/runtime: passed the previous ownership crash boundary and reached Seyda Neen exterior.
- Diagnostic file: 7,028 bytes, SHA-256 `5A6113914B4D90EEF274588E8914CA01D37F53BFB4CAB45DAE22F8E8ABD5FAC0`.
- Session: `02306F28-5A6E-45AB-ADAC-414235769F83`.
- Records: 23 total; 1 iOS startup, 22 OpenMW, 0 GL4ES.
- Families: 21 `r1.state`, 1 `r1.asset`, 1 `session`, 0 R2.
- Representative correlated defective R1 sample: not captured.
- Intended/applied R2 sample: not captured.
- Visible exterior result: foliage cards, white/blank distance regions, and blue horizon band unchanged.
- Touch result: short-tap Menu did not open the menu; long-press Menu still entered customization. The candidate contains no touch-source change, so cause is unclassified, but the accepted smoke behavior regressed.

The ownership correction is validated, but the replacement diagnostic candidate does not satisfy Amendment 1 qualification because it lacks later GL4ES records and regresses accepted touch behavior. Conditions B and F require an immediate stop; the final renderer-correction build cannot be used to repair diagnostics or touch.

## Validation and build budget

- Focused WO31 tests: 10/10 pass before CI.
- Ordered pinned OpenMW patch stack: pass.
- Ordered pinned GL4ES patch stack: pass.
- Production compile/link/package/bundle validation: pass.
- Cache: cold/miss; configure/dependencies 2,208s, compile/link 2,393s.
- Diagnostic Fast builds consumed: 1 of 1.
- Final Fast builds consumed: 0.
- Additional builds: none.
- Touch source changes: none.
- Canonical ControlPlane changes: none.

Amendment 1:

- Focused ownership/diagnostic tests: 11/11 pass, including synthetic rejection of the original raw-autoreleased assignments.
- Full Python discovery: 114 pass, 4 skip, 2 pre-existing Windows-only POSIX-verifier execution errors; no WO31 assertion failed.
- Production compile/link/package/bundle validation: pass in Fast run `32588069228`.
- Cache: source downloads and vcpkg exact hits; qualified build state restored from the prior matching state while the new exact delta key reported false.
- Configure/dependencies: 160s; production compile/link: 142s; run duration: 14m12s.
- Replacement diagnostic Fast builds: 1 of 1 consumed.
- Final renderer-correction Fast builds: 0 used.
- Full Qualification: not run.

## Amendment 1 required orchestrator review

WO-031 Amendment 1 cannot continue. The diagnostic ownership defect is corrected, but the one replacement diagnostic build did not produce the required GL4ES/R2 evidence and showed a touch smoke regression. The orchestrator must decide whether to authorize a new diagnostic design/build and separately disposition the Menu observation. This report does not authorize either action.

## Amendment 2 execution identity

- Observability commit: `626b3321ee7ce83f82d22a707dfa4f9177cf6fff`
- Fast run: `32597504051` (success, 1h00m47s)
- Artifact: `OpenMW-iOS-fast-42`, ID `9482706450`, digest `sha256:f48928d4f6b30c6b7e305fe27df69213f17405a35ac20c3367af6e98de6c41a5`
- IPA SHA-256: `824395081D76CBC7B5B164B4FC9CDC4CEBB752D7D7D451E011246B42674B6857`
- Executable SHA-256: `0B19227B2E7950307385BE5B467D36C7D2F01AC6AD05FFE0B74C239879314447`
- Mach-O UUID: `9A5D277A-AC2B-3E86-9E18-D1E85985EC88`
- Diagnostic build budget: 1 of 1 consumed
- Final renderer-correction build budget: 0 used
- Full Qualification: not run

## Amendment 2 device result

The exact Amendment 2 artifact reached Seyda Neen and wrote 396 valid records to [device-renderer-diagnostic-amendment2.jsonl](device-renderer-diagnostic-amendment2.jsonl). Both handshakes are present. Production Mach-O inspection independently shows all GL4ES probes retained and directly resolved to the app bridge. The former zero-GL4ES result was therefore observability-path failure, not link stripping.

R1 progressed to actual defective asset identification and GL texture IDs:

- smoke: `textures/tx_smokealpha00a.dds` → texture 115;
- fire: `textures/tx_firealpha01.dds` → texture 148;
- foliage controls include `textures/tx_treering_wg_01.dds` → texture 118 and multiple moss/fern/kelp textures.

But `r1.draw` exhausted at sample 199 and the first defective `r1.bound` record appears at sample 210. Every recorded draw is `category=-1`; none is a representative defective draw. The earliest invalid R1 renderer boundary therefore remains unknown.

R2 proves a longer partial chain. OpenMW records the exterior intent and OSG applies it: start `2007.04`, end/far `7168`, color `0.960784,0.921569,0.878431,1`. GL4ES later receives those exact values at samples 324–327. However, `r2.applied` exhausted at sample 41, before the exterior values arrived; its 32 records are only program-1 controls with `has_builtin_fog=0` and `received_count=0`. This proves OpenMW→OSG→GL4ES fog receipt but not consumption by the representative exterior program. The file also contains only one repeated exterior view-distance setting.

The user-visible defects remain unchanged. No source-backed R1 or R2 correction is authorized from this evidence, and the final build was not triggered. Short-tap Menu was not reported for this run; no touch source changed.

## Final orchestrator review gate

Amendment 2 must stop under Conditions B and G. A further probe-budget redesign would require a second diagnostic build, which the canonical order expressly forbids. The durable evidence establishes that the bridge works, real defective assets reach OSG texture objects, and GL4ES receives correct fog state; it does not establish the applied draw/program boundary. The orchestrator must decide whether a future order authorizes targeted late-session sampling. This report does not authorize or begin that work.
