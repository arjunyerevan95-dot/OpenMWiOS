# WO-031 execution report

## Outcome

**BLOCKED / STOPPED — Condition F (diagnostic candidate regression/hard crash).**

WO-031 implemented and production-built the required bounded, user-shareable renderer diagnostics channel. The exact IPA installed and launched, showed the loading screen for roughly half a second, and hard-crashed before reaching representative exterior state. No renderer correction was selected or attempted.

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

## Diagnostic result

The retrieved `Documents/OpenMW/renderer-diagnostic.jsonl` contains exactly one 253-byte startup record with session `C0912F7F-958B-4FC5-BA81-379A75345C7D`. File SHA-256 is `16F3B558437016BE03447688D3D7B26465FCF9B466C897B5B0D01F951139851A`.

Counts:

- session records: 1
- OpenMW intended-state records: 0
- GL4ES received/applied records: 0
- R1 representative records: 0
- R2 representative records: 0

This proves the app-owned Documents path, JSON schema, initial file creation, and initial write. It also proves the crash occurred before the diagnostics channel could commit its first later renderer record.

## Earliest source-backed crash boundary

The new Objective-C++ bridge stores `sPath` and `sSession` as persistent raw `NSString*` globals. `openmw_ios_renderer_diag_begin()` wraps initialization in `@autoreleasepool`; `beginLocked()` assigns autoreleased results from `stringByAppendingPathComponent:` and `NSUUID.UUID.UUIDString`; the pool then drains. The OpenMW target does not enable ARC in repository CMake/Xcode configuration. CI compiled the new file as Objective-C++ and showed no explicit ARC option in the visible invocation. A later renderer record calls `appendRecord()` with the now-invalid persistent Foundation objects.

The observed sequence is exactly consistent with that ownership defect:

1. startup objects are alive inside the pool;
2. initial record writes successfully;
3. pool drains;
4. loading/rendering begins;
5. first later record dereferences persistent objects;
6. process hard-crashes before a second record is committed.

No native crash report was available, so this is a strong source-and-sequence causal conclusion rather than a symbolicated stack proof.

## R1 and R2 disposition

- R1 earliest invalid renderer boundary: **not reached / unknown**.
- R2 earliest invalid renderer boundary: **not reached / unknown**.
- Shared alpha/fog cause: **not established**.
- Renderer fixes: **none**.
- Accepted renderer baseline: not contradicted; the regression is isolated to the new diagnostic candidate.

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

## Required orchestrator review

WO-031 cannot continue under its current build budget and Stop Condition F. A future orchestrator-authorized order or amendment would need to repair the diagnostics bridge ownership (for example explicit retained/copied Objective-C objects or an ARC-enabled translation unit), requalify startup, and only then resume R1/R2 correlation. This report does not authorize that work.
