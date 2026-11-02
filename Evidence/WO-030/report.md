# WO-030 execution report

## Outcome

**PARTIAL / STOPPED — Stop Condition B (renderer cause unproven).**

The persistent on-device touch editor reached device acceptance, including the corrected live opacity preview. The foliage-alpha and distance/fog renderer investigations remained source-verified but did not establish the earliest invalid runtime boundary. No speculative renderer correction was applied.

## Control and execution boundary

- Issued baseline: `765deec93d0b7e4ff0ccebd24483f704ee925c0a`.
- Amended READY control commit: `2b72ab9`.
- Execution branch: `codex/wo30-renderer-touch-customization`.
- Diagnostic/touch commit: `d1d5182b344f77aa2cdee1169c30d3e2ee0dd955`.
- Final opacity correction: `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27`.
- Canonical `Documentation/CURRENT_STATE.md`, `WorkOrders/`, and `Decisions/` were not modified by the worker.
- Pre-existing unrelated modified/untracked files were preserved and excluded from WO-030 commits.

## R1 — foliage, particles, and alpha/cutout

Direct source inspection verified the intended path from DDS alpha detection through NIF/OSG alpha state, OpenMW shader alpha-test state, and GL4ES compressed-texture handling. The diagnostic candidate added bounded observation-only records and did not change rendering.

The user confirmed no visible change to foliage sheets and supplied additional evidence of blocky rectangular spell-fire and chimney-smoke particles. The shared app log contained 96 startup DDS records but no `WO30 R1 alpha-state` record. The DDS budget was exhausted by early UI/cursor/water textures before a representative exterior foliage sample was isolated. GL4ES DXT records were `stderr`-only and were not present in the shared log.

The expanded symptom family supports prioritizing a shared alpha/blending-path investigation, but it does not prove an earliest invalid operation. See [renderer-r1-alpha.md](renderer-r1-alpha.md) and [shared-log-analysis.md](shared-log-analysis.md).

## R2 — distance, fog, and horizon

Direct source inspection verified the intended OpenMW FogManager-to-OSG-to-GL4ES path and eliminated the hypothesis that fixed-function fog application was compiled out of the pinned OSG build.

The shared log records OpenMW's intended exterior fog values:

- start: `2007.04`;
- end/far: `7168`;
- color: `0.960784,0.921569,0.878431`;
- underwater: `0`.

The user confirmed that the white distance regions and sharp blue horizon remained unchanged. The matching GL4ES received-state and built-in-uniform probes were `stderr`-only, so the OpenMW-to-GL4ES comparison could not be completed from the shared files. The earliest R2 divergence remains unlocalized. See [renderer-r2-distance.md](renderer-r2-distance.md).

## Shared-log finding

The 914,535,996-byte `openmw.log` was caused by an existing warning flood, not by WO-030's bounded probes. Across 8,960,913 lines:

- unsupported `ColorMaski::apply`: 8,864,974;
- `invalid operation`: 67,563;
- `invalid enumerant`: 28,115;
- all other lines: 261.

`invalid enumerant` is repeatedly reported after `TransparentDepthBinCallback::drawImplementation`, and `invalid operation` after `RenderBin::draw(..)`. This temporal association is relevant but is not causal proof. `ColorMaski` handling was deliberately not changed because WO-030 did not establish it as the earliest cause. See [shared-log-analysis.md](shared-log-analysis.md).

## Touch-editor implementation

The implementation preserves the accepted WO29 non-ARC icon ownership and the existing movement/look/action architecture. It adds:

- 0.75-second long-press Menu entry with deferred short-tap Pause dispatch and no long-press Pause leak;
- direct in-game editing with gameplay input suppression;
- move/resize for all twelve fixed controls, including Menu;
- adjustable floating-movement radius;
- normalized safe-area-relative, versioned profile persistence in `NSUserDefaults` key `OpenMWIOSTouchProfileV1`;
- Done, Cancel rollback, confirmed Reset/Undo, and global opacity controls;
- default idle alpha `0.20`, clamp `0.05-0.85`, and pressed rule `min(0.92, idle + 0.42)`.

The diagnostic candidate's edit mode forced alpha `0.82`, preventing a visible opacity preview. Commit `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27` removed the override and made editor and normal rendering use the current profile alpha directly.

## Local and CI validation

- Focused touch/diagnostic tests: 27 run; 26 pass; 1 environment/compiler skip; 0 failures.
- Final aggregate iOS tests: 59 run; 55 pass; 4 environment/compiler-dependent skips; 0 failures.
- Both deterministic dependency diagnostic patches passed `git apply --check` against pinned sources.
- Full Qualification was not run.

### Diagnostic Fast Development

- Run `32568335889`; success; `1h25m02s`.
- All three exact caches missed.
- Artifact `OpenMW-iOS-fast-33`, ID `9475554610`.
- Executable SHA-256 `C642A179E6A989CBF276407F98F63DFCC5EEC6D851E04DBB14583E0F14D01A0C`.
- IPA SHA-256 `497DC02A1CB056DCA09F4BD2875CE2CE590342226FDB10E98857AEED129D6B03`.
- Mach-O UUID `D84F4FE7-2BC9-3BA0-BD22-0E3B6C6373CB`.

### Final Fast Development

- Run `32573611821`; success; `39m06s`.
- Source-download and vcpkg caches hit; incremental build-state cache missed.
- Artifact `OpenMW-iOS-fast-34`, ID `9476386162`.
- Executable SHA-256 `5ABD1BC40F5FDFF67747E329FE56D2593D2FCDCE9847139BBFF3C97749A85D66`.
- IPA SHA-256 `7ADADF613AC36DED1F63B2848B6622654231AF8243643B0791CC682536C426E6`.
- Mach-O UUID `0BA296A8-24AC-364C-A804-F4601A399F99`.
- Bundle validation qualified `org.openmw.ios`; exactly one normal IPA was produced.

## Device acceptance

The user installed both candidates without requiring usbmux as a qualification gate.

- Diagnostic candidate: customization worked except opacity preview; renderer symptoms remained unchanged.
- Final candidate: the user classified opacity as a pass and confirmed both plus and minus visibly changed it.
- Acceptance screenshot SHA-256: `2605641B92C3696C569ED39E94E2121EAEE969B98C7EA07C2237290C658B41B4`.
- No touch-editor crash, data-path regression, or touch-caused renderer regression was reported.

The final message did not independently assert force-quit/relaunch persistence, provide a post-test crash inventory, or repeat the complete action-control matrix. Those limits are recorded rather than inferred. Persistence and interaction invariants are source/test-backed; the visible opacity behavior is device-observed.

## Acceptance comparison

| Track | Result |
|---|---|
| Touch editor entry/customization | User accepted on diagnostic candidate |
| Opacity preview | Failed diagnostic candidate; corrected and device-accepted on final candidate |
| Profile model/safe-area behavior | Source and deterministic-test qualified |
| Renderer R1 causal model | Unproven; no correction applied |
| Renderer R2 causal model | Unproven; no correction applied |
| Qualified renderer/data-path baseline preservation | No regression reported; relevant aggregate tests pass |
| CI budget | One diagnostic Fast plus one final Fast; no Full Qualification |

## Strongest conclusion and review boundary

WO-030 successfully delivers the authorized touch-customization track, including nominal 20% idle opacity and a working live opacity control. It does not deliver a renderer correction: the shared evidence reveals a massive `ColorMaski`/GL-error warning flood and incomplete alpha/fog diagnostic capture, but does not prove the earliest renderer fault.

The worker stops under **Condition B**. Any next renderer diagnostic design, file-backed GL4ES logging, warning-rate correction, or renderer fix requires orchestrator review and a new or amended canonical order.
