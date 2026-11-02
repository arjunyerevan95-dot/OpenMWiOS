# WO-030 evidence manifest

## Control and source identities

- Issued engineering baseline: `765deec93d0b7e4ff0ccebd24483f704ee925c0a`
- Amended READY control commit: `2b72ab9`
- Activation commit observed: `f193509cc8acaf5372ab169188d4d6b7e407b7f7`
- Execution branch: `codex/wo30-renderer-touch-customization`
- Diagnostic candidate: `d1d5182b344f77aa2cdee1169c30d3e2ee0dd955`
- Final candidate: `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27`
- OpenMW revision: `f4bec41444214a7903bebd178389ca22ca13f646`
- OSG revision: `01cc2b585c8456a4ff843066b7e1a8715558289f`
- GL4ES revision: `c9895df34cd466c23bc60c2bd3db3d87e98fcbe7`
- SDL revision: `2.32.10`

## Preserved unrelated worktree state

The execution began with a modified `docs/ios-port-ledger.md` and untracked historical handoffs, `.tmp/`, and Python cache directories. They were not modified, staged, deleted, or normalized by WO-030.

## Local tests

- Focused diagnostic/touch command: `python -m unittest validation.test_ios_touch_controls validation.test_wo30_renderer_diagnostics`
- Focused result: 27 run; 26 pass; 1 skip (local C++ compiler unavailable); 0 failures.
- Final aggregate command: `python -m unittest validation.test_ios_touch_controls validation.test_ios_data_path validation.test_ios_drawable_framebuffer validation.test_ios_fullscreen_scaling validation.test_ios_gl4es_presentation validation.test_ios_post_context_drawable validation.test_ios_render_scale validation.test_ios_runtime_resources validation.test_gl4es_mainless_linked_shader validation.test_gl4es_debug_uniform_initializer`
- Final aggregate result: 59 run; 55 pass; 4 environment/compiler-dependent skips; 0 failures.
- Both dependency patches passed `git apply --check` against the pinned, already-qualified source stacks.
- `scripts/validate-source.sh` passed under Git for Windows Bash.
- `git diff --check` reported only the pre-existing ledger line-ending warning plus unified-patch blank-context whitespace; no changed runtime source line had a whitespace error.

## Diagnostic Fast Development

- Workflow: `iOS Fast Development`
- Run: `32568335889`
- Candidate: `d1d5182b344f77aa2cdee1169c30d3e2ee0dd955`
- Event: manual `workflow_dispatch`, `benchmark_mode=none`
- Full Qualification: not run
- Cache result: source-download, vcpkg-binary, and qualified incremental-state caches all missed their exact keys.
- Status: success.
- Duration: `1h25m02s` (`2491s` configure/dependencies; `2311s` production compile/link).
- Artifact: `OpenMW-iOS-fast-33`, ID `9475554610`.
- Executable SHA-256: `C642A179E6A989CBF276407F98F63DFCC5EEC6D851E04DBB14583E0F14D01A0C`.
- IPA SHA-256: `497DC02A1CB056DCA09F4BD2875CE2CE590342226FDB10E98857AEED129D6B03`.
- Mach-O UUID: `D84F4FE7-2BC9-3BA0-BD22-0E3B6C6373CB`.
- User device result: the touch editor worked, but its opacity preview remained hardcoded and did not respond to the opacity controls. Renderer symptoms were unchanged, as expected from observation-only probes.

## Final Fast Development

- Workflow: `iOS Fast Development`.
- Run: `32573611821`.
- Candidate: `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27`.
- Status: success.
- Created/completed: `2026-08-22T12:40:11Z` / `2026-08-22T13:19:17Z`; total `39m06s`.
- Component timings: `118s` configure/dependencies; `1843s` production compile/link.
- Cache result: source-download and vcpkg-binary caches hit; qualified incremental build-state cache missed.
- Artifact: `OpenMW-iOS-fast-34`, ID `9476386162`.
- Artifact archive digest: `sha256:71bcceeef41de691538b23e0531e15da51b10004b03399aafda9c89fd255445b`.
- Executable SHA-256: `5ABD1BC40F5FDFF67747E329FE56D2593D2FCDCE9847139BBFF3C97749A85D66`.
- IPA SHA-256: `7ADADF613AC36DED1F63B2848B6622654231AF8243643B0791CC682536C426E6`.
- Mach-O UUID: `0BA296A8-24AC-364C-A804-F4601A399F99`.
- Bundle validation: qualified; bundle ID `org.openmw.ios`; exactly one normal IPA.
- Full Qualification: not run.

## Evidence records

- [R1 foliage alpha](renderer-r1-alpha.md)
- [R2 distance/fog](renderer-r2-distance.md)
- [Touch customization](touch-customization.md)
- [User-shared log analysis](shared-log-analysis.md)
- Completion report: `report.md` (required at the WO-030 stop boundary)

## App-owned diagnostic retrieval without usbmux

The user requested a repeatable renderer-diagnostic workflow that does not require connecting the phone to usbmux for every run.

- OpenMW already writes shareable app-owned logs under `Documents/OpenMW/`, principally `openmw.log` and `MyGUI.log`. The port has also previously produced `Library/OpenMW/startup.jsonl`.
- The WO-030 OpenMW-side probes (`WO30 R1 alpha-state`, DDS metadata, and `WO30 R2 intended fog`) use `Log(Debug::Info)` and therefore belong in `Documents/OpenMW/openmw.log` when that diagnostic candidate is installed.
- The WO-030 GL4ES-side probes (DXT alpha classification, received fog state, and built-in fog uniforms) use bounded `stderr` records. Those records are available through console capture but are **not** currently copied into an app-owned shareable file.
- Consequently, a user-shared `openmw.log` can provide the higher-level OpenMW half of the diagnostic without usbmux, but it cannot by itself establish the GL4ES half of the boundary.
- A future explicitly authorized diagnostic implementation may route the bounded GL4ES records into an app-owned file such as `Documents/OpenMW/renderer-diagnostic.log`, or expose a single shareable diagnostics archive. That is a proposed evidence-collection mechanism only; WO-030 did not implement it.
- The normal/final WO-030 candidate removes the temporary renderer probes, so it cannot retroactively produce the WO-030 renderer records.

No canonical ControlPlane state or durable decision was changed by recording this execution note.

## Device matrix

- Diagnostic candidate: installed and exercised by the user without usbmux logging. The editor worked except for opacity preview. Foliage sheets, white distance regions, and the blue horizon did not change. Blocky spell-fire layers and chimney smoke were additionally observed.
- Final candidate: installed and accepted by the user. `OPACITY -` and `OPACITY +` visibly changed the touch-control opacity. The user classified the result as a pass.
- Final acceptance screenshot SHA-256: `2605641B92C3696C569ED39E94E2121EAEE969B98C7EA07C2237290C658B41B4` (208,357 bytes). It visibly shows a substantially reduced-opacity overlay over the unchanged Seyda Neen renderer symptoms.
- No live usbmux logging, crash inventory, or independent force-quit/relaunch persistence observation was supplied for the final check. These limits are recorded rather than inferred.
- The accepted before references remain the user-supplied WO29/WO30 screenshots preserved by the orchestrator thread; large image binaries are not duplicated in Git.

## Stop condition

**B - Renderer cause unproven.** The touch-customization track reached device acceptance, including the corrected live opacity preview. R1 and R2 did not locate an earliest invalid renderer boundary, so no renderer correction was applied. WO-030 stops as **PARTIAL / STOPPED** for orchestrator review.
