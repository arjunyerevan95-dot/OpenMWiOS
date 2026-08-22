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
- Evidence snapshot time: `2026-08-22T02:18:19.9860921+05:30`

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

The existing executable may permit function-level symbolication if a matching crash address/UUID is obtained. Exact source-line symbolication may require a matching dSYM or preserved CI object files. A diagnostic-only Fast build remains authorized only if the existing report/executable pair proves insufficient.

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

## Current boundary

The bounded correction is locally qualified. A single corrected Fast Development build remains to be committed, pushed, monitored, and device-qualified. No WO-029 CI run has begun as of this update.
