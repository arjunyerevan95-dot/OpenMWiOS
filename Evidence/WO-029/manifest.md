# WO-029 Evidence Manifest

## Execution identity

- Work order: `WO-029`
- Canonical status observed: `ACTIVE`
- Execution branch: `codex/wo29-ios-crash-isolation`
- Issued baseline: `88bce1f0bdf709661d2c45644b6eef26c021c87b`
- READY issuance commit: `a585fea4f17b7de15718a263c0b833e4c3262391`
- Canonical activation commit observed on the execution branch: `7377ac81b113546e4d8bcb765680e2a37e90e9ad`
- Accepted runtime baseline (WO27): `6db1c2af5066f810df97c5af39bdbf2a48fb86b5`
- Rejected candidate under investigation: `1dc819cea447f8ac40c878e1a6d7f4d478e94063`
- Initial evidence snapshot time: `2026-08-22T02:18:19.9860921+05:30`
- Completion evidence time: `2026-08-22T14:10:18.7571904+05:30`

The activation commit changed only canonical ControlPlane files. It was present when the worker resumed WO-029; the worker did not author or amend those files.

## Pre-existing worktree state

The following unrelated state was present before WO-029 evidence writes and was left untouched/un-staged:

- modified `docs/ios-port-ledger.md`
- untracked `.tmp/`
- untracked historical `WORK-ORDER-*-HANDOFF.md` files
- untracked `scripts/__pycache__/`
- untracked `validation/__pycache__/`

## Rejected candidate CI and artifact

- Fast Development run: `32511443555`
- Workflow: `.github/workflows/ios-fast.yml`
- Run conclusion: `success`
- Run head: `1dc819cea447f8ac40c878e1a6d7f4d478e94063`
- Artifact ID: `9457442141`
- Artifact name: `OpenMW-iOS-fast-30`
- Artifact wrapper SHA-256: `b2cb617ddf3b2a1a8c279fa2ed088f6b5ea7c14ae4213ad10a59e2d6eb61a6b5`
- Artifact retention observed through: `2026-08-28`
- IPA SHA-256: `0E4169BFF35D0D2D37FFD7730A6FD6AF0A97ABDFAF4643DCBD4C3DDF63B082D0`
- Executable SHA-256: `2D87E61D8F6F372EBC90F4B0A1E747D3E9721EA0A9A1B87C629810BB06686B39`
- Local artifact reference: `.tmp/wo28-amended-32511443555/artifacts/OpenMW-iOS-unsigned.ipa`
- Exact extracted candidate: `.tmp/wo29/rejected-32511443555/Payload/OpenMW.app/openmw`
- Full Qualification: did not run

No active or newer WO-029 workflow was present when queried. The latest run remained WO28 Fast run `32511443555`; WO-029 has not duplicated CI.

## Bundle and Mach-O identity

- Bundle identifier: `org.openmw.ios`
- `CFBundleShortVersionString`: `0.1`
- `CFBundleVersion`: `1`
- Executable name: `openmw`
- Architecture: thin arm64 Mach-O
- Mach-O UUID: `FD8A7812-C514-3995-BB1C-08F921EBCD7B`
- Minimum iOS: `16.3`
- SDK: iPhoneOS 18.5
- Xcode: 16.4 (`DTXcodeBuild=16F6`)
- Embedded provisioning profile in unsigned artifact: absent

The unsigned CI identity remains distinct from any SideStore-re-signed installed identity. Installed binary UUID/signing identity has not yet been independently read back.

## Symbolication inventory

- dSYM in uploaded artifact: absent
- link map in uploaded artifact: absent
- `__DWARF` segment in executable: absent
- Mach-O symbol table: present (`292603` symbols; string table size `19777328`)
- debug-map/stab entries: present, including `N_SO`/`N_OSO`; the executable references CI object files that are not contained in the uploaded artifact

The matching reports and executable symbol table were sufficient to establish the function-level fault and exact Objective-C selector/receiver evidence. A diagnostic-only Fast build was therefore not needed and was not run. Exact source-line dSYM symbolication remains unavailable for both uploaded artifacts.

## Candidate change inventory

Relative to accepted WO27 runtime baseline `6db1c2af...`, the rejected WO28 candidate changes touch implementation/model/assets and touch regression fixtures/tests, plus repo-backed control-plane records. Runtime-relevant files are:

- `ios/openmw_ios_touch_controls.mm`
- `ios/openmw_ios_touch_icons.hpp`
- `ios/openmw_ios_touch_model.hpp`
- `validation/fixtures/android-touch-2.7.4-reference.json`
- `validation/test_ios_touch_controls.py`

No causal conclusion follows from the changed-file inventory alone.

## Crash classification and causal finding

Thirteen matching August 22 reports were pulled from the device. Every report has slice UUID `FD8A7812-C514-3995-BB1C-08F921EBCD7B`, an exact match for the rejected CI executable. All thirteen fault at `-[OpenMWTouchOverlay drawRect:] + 0x35c` while sending `imageWithTintColor:renderingMode:` to a stale/reused cached icon pointer. Nine are `EXC_BAD_ACCESS`/SIGSEGV in `objc_msgSend`; four are `NSInvalidArgumentException`/SIGABRT and name the unrelated object classes now occupying the address.

The exact CI compile command contains no `-fobjc-arc`. The rejected cache stored autoreleased results from `+[UIImage imageWithData:]` in a raw-pointer `std::array`, so the process-lifetime cache did not own the images after the autorelease pool drained.

Launch, `New Game`, and overlay-action paths are now classified `CONVERGED` at this common source mechanism. See [crash-classification.md](crash-classification.md) for report identities, hashes, path stacks, and the pairwise basis.

The lazy SDL virtual-controller path was not on the faulting application frame and is not causal to these reports.

## Device/crash capture status

- Device: iPhone17,2, iOS 26.6 (23G71), USB connection
- Existing OpenMW crash reports pulled: 23 total, of which 13 match the rejected WO28 UUID and August 22 test window
- Installed signed bundle: `org.openmw.ios.7CP756AU4P`, version/build `0.1`/`1`
- Installed executable UUID: established by all matching reports as `FD8A7812-C514-3995-BB1C-08F921EBCD7B`
- `Library/OpenMW/startup.jsonl`: retrieved read-only to `.tmp/wo29/device/pre/startup.jsonl`
- WO27 data discovery in retrieved log: `Morrowind.esm and Morrowind.bsa found`, current Documents path supplied at runtime

Path classifications:

| Path | Matching reports/evidence | Classification |
|---|---|---|
| Intermittent immediate launch-time failure | 5 reports; `prepareEngine`/loading stacks | `CONVERGED` |
| `New Game` failure after menu | 3 reports; explicit `MainMenu::onButtonClicked`/`newGame` stacks | `CONVERGED` |
| Overlay-action failure after menu | 5 menu-frame reports; MENU action at 18:48:59Z correlates to report at 18:49:00Z | `CONVERGED` |

## Bounded correction and local validation

Changed runtime file:

- `ios/openmw_ios_touch_controls.mm`: construct cached icons with owned `[[UIImage alloc] initWithData:]` objects and release the temporary `NSData`

Focused regression:

- `validation/test_ios_touch_controls.py`: asserts the non-ARC process-lifetime cache owns each image and forbids the previous autoreleased return
- focused suite: 20 tests run, 19 passed, 1 skipped because no host C++ compiler is installed
- aggregate suite: 106 tests run; 100 passed, 4 compiler-dependent tests skipped, and 2 pre-existing shell-script execution tests errored on Windows with `WinError 193`; no WO29 functional assertion failed
- `git diff --check`: passed for WO29 paths

No runtime mapping, layout, opacity, renderer, WO27 data path, dependency, cache, or workflow behavior changed. No diagnostic-only build was needed because the existing matching reports were already function-symbolicated and contained the exact Objective-C exception selector/receiver evidence.

## Corrected candidate CI and artifact

- Correction commit: `45c1d8c696fb328d977893b79efc78689a3f4d08`
- Execution branch: `codex/wo29-ios-crash-isolation`
- Pull request: `https://github.com/arjunyerevan95-dot/OpenMWiOS/pull/16`
- Fast Development run: `32548876888`
- Run URL: `https://github.com/arjunyerevan95-dot/OpenMWiOS/actions/runs/32548876888`
- Run conclusion: `success`
- Run start/end: `2026-08-22T03:24:23Z` / `2026-08-22T04:51:56Z`
- Total run duration: approximately `1h27m33s`
- CI regression suite: `109` tests completed in a successful validation step
- Configure/dependency preparation: `2197s`
- Production compile/link: `2725s`
- Production compile, link, bundle validation, packaging, and upload: passed
- Artifact ID/name: `9470501854` / `OpenMW-iOS-fast-31`
- Artifact wrapper SHA-256: `DB896B05A9D2CAA4CEAF4A99FDD9A72E2997C2E911B64A8603BF69BDD78DC27C`
- IPA SHA-256: `E295561EE9BF1F52A7337C6AACFE7777F530E9E394462F3C143DEB98E14BDD63`
- Executable SHA-256: `6FF52E861FF44D4C4449E1A82481EE7F52B515932A56279EB5C057F9E740F0C2`
- Corrected Mach-O UUID: `52739477-31F4-3693-9D6F-30366E3D640D`
- Corrected dSYM/link map: not present in the uploaded artifact
- Temporary delivery URL: `https://tempfile.org/3VaEXqg9i3J/download` (24-hour temporary host)
- Full Qualification: did not run

Cache fingerprint/source:

- ABI: `ios-fast-v4-xcode16.4-ios16.3-arm64-edd5fbcd7e18a5d33a4de616e039704d860dd513c9140bfb34ccbee5f1003987`
- Source digest: `3174ada24c81a0899132dafc3b5ab15feffb00a1a65c0a09aed30df230cc044a`
- Scope: `refs/pull/16/merge`, base `codex/wo28-android-touch-fidelity`
- Source-download, vcpkg, and qualified build-state caches: miss
- Cache architecture was not changed.

An evidence-only completion push unexpectedly triggered pull-request run `32563091883` because the PR's cumulative diff still contains runtime files even though the new commit changed only Markdown. The worker cancelled it immediately. It ran for 34 seconds, stopped during qualified build-state cache restore, and skipped configure, compile, link, package, and artifact upload. It is not a second production build.

## Corrected device observation

The user installed the exact corrected IPA and reported: "That was a pass. It boots up normally and the controls work fine." The session reached both indoor and Seyda Neen exterior gameplay and produced nine screenshots. No native crash, unexplained termination, or jetsam was user-observed. This materially falsifies the rejected candidate's immediate launch/menu/action crash behavior for the observed session.

The formal Phase 5 attempt-count matrix was not recorded:

- consecutive launch count: `NOT RECORDED` (at least one successful launch observed)
- fresh `New Game` transition count: `NOT RECORDED`
- per-control enumeration: `NOT RECORDED`; user reported controls generally working
- movement/look/additional-action enumeration: `NOT RECORDED`; extended indoor/exterior traversal and combat screenshots were supplied
- post-test crash inventory: unavailable because `pymobiledevice3 usbmux list` returned `[]` after the session

The worker therefore records a strong corrected-device pass but does not self-declare canonical acceptance of the unrecorded numeric quota. Orchestrator review is required.

## Device screenshot evidence

Local attachment directory (external to the repository):

`C:\Users\arjun\.codex\codex-remote-attachments\019ffd24-a544-7153-9790-108f7079471e\BE58A696-FDDD-48EE-A6C9-584584F95F0E`

| Screenshot | SHA-256 | Observation |
|---|---|---|
| `1-Photo-1.jpg` | `7487B9B882E225BFE648E81A8B4D5B3F1DE7992C338E1788724BB68463F0CA68` | Seyda Neen exterior; overlay present; foliage/distance defects visible |
| `2-Photo-2.jpg` | `8CA8BD23BF392F777846FB00171D306E244D1BBD7D93436F337971BE9B812716` | Interior scene renders; overlay present |
| `3-Photo-3.jpg` | `C1C5475E7EB8D7645EAB7F41611B285DE54FB8F924C0B411FA9FA0A04108A897` | Exterior gameplay/HUD and weapon visible |
| `4-Photo-4.jpg` | `A4A7765EED72104FEBA7084978A4118A3B2DFD5FE7945D3171323FB8FF667955` | Exterior foliage planes and white distance region visible |
| `5-Photo-5.jpg` | `EFAB3183908E5F37346090C49F797792869569248A642928BEF50C48DDB8F460` | Exterior traversal; blue horizon band/distance cutoff visible |
| `6-Photo-6.jpg` | `18B02DD614C44D3BF90CEC40592F7D9B536DFAA436263A17438B8A1416C52A73` | Exterior tree alpha/cutout failure and missing distance presentation visible |
| `7-Photo-7.jpg` | `C1E85A524E563A014677CBFF75359C5CA0277F0455487EB3BFC02C9710BB9B6B` | Exterior traversal with repeated foliage/distance symptoms |
| `8-Photo-8.jpg` | `C0E0B07D473B108FBD4A2A02AF43EBDA5AA39F5C5C1F47103F509BAE8A67F79B` | Combat scene with a transient blocky red effect |
| `9-Photo-9.jpg` | `540A4C777B366D8E49381E699D675DC084F238B270E78C01D506A9C1C6D40E1C` | Same combat area after the red block is absent |

User feedback also requests approximately 80% transparency and future control resizing/repositioning/customization. These are UX observations only and were not implemented or converted into a durable decision. Exterior foliage-alpha/cutout, distance fog/horizon, and the transient blocky combat effect remain unclassified renderer observations outside WO-029.

## Execution boundary

The bounded icon-cache ownership correction is source-proven, locally qualified, production-built, and positively device-observed. The formal numeric launch/transition/control matrix and an independent post-test crash inventory were not recorded. Execution stops at the orchestrator-review gate; no UX or renderer work was begun.
