# WO40 execution report

Status: **implementation/build complete; touch device validation pending**. Stop condition **C**: integrated IPA and evidence are ready for orchestrator review. No runtime acceptance is claimed.

The selected Zink source is pinned and the customizable touch port is isolated on codex/wo40-zink-touch. See [manifest](manifest.md), [integration](integration.md) and [validation](validation.md). Graphics/dependency pins and patches are unchanged. Existing repositories/artifacts and canonical files remain intact.

Implementation commit: 5b55597d9e183a50e7eed4594f9bc1444ec4dd6a; primary source/workflow: 439bf57a445297bfa0b5ac4afa839f3a20e6bdd7. Initial [skip ci] publication produced no workflow; the intentional primary publication produced only the candidate workflow.

Primary run [41199873586](https://github.com/arjunyerevan95-dot/OpenMWiOS/actions/runs/41199873586), 2026-10-31 12:09:57–12:10:13 UTC: failed before compilation in Verify foundation and runner. Runner was arm64 with Xcode 27.1 / 27A9275. The worker-authored version assertion piped xcodebuild to grep -q under pipefail. grep closed its input on the matching first line, and xcodebuild raised NSFileHandleOperationException/Broken pipe writing its second line (exit 134). No product/dependency compilation or IPA exists from this run.

Repair is solely the workflow preflight: capture the complete xcodebuild output, print it, and compare the first line with a Bash pattern, without a short-reading pipe. A local executable harness ran the actual old/fixed YAML shell step with delayed two-line xcodebuild output and stubbed runner identity: old exit 141, fixed exit 0; actual Git ancestry and renderer-diff checks passed. The first local harness attempt had a Windows PATH translation error; it was corrected before these results.

Primary log-only artifact: WO40-Zink-Touch-41199873586, ID 13042187353, 356 bytes, digest sha256:61744e644c7db50d837a2c2f8eb2fd36d2c363617191a174c8dffbda024a1cd7. This is not an IPA.

Repair preflight/evidence commit: f5514a8cd1ab828b8b45d35dbf3f2d7e7444e94a; successful build source/workflow: **f4d9f9d8d6bcba1b3bc59201724aab62627aaa4e**. Its intentional marker publication started [41200954123](https://github.com/arjunyerevan95-dot/OpenMWiOS/actions/runs/41200954123). Job 124536482475 ran 2026-10-31 12:24:24–13:23:43 UTC (59 minutes 19 seconds) and **succeeded**. Preflight, host tools, all 132 executable checks under Apple clang, integrated Objective-C++/engine compile/link, unsigned packaging and artifact upload passed. The repair commit's earlier [skip ci] publication produced no run. Monitoring was interrupted before result collection; the completed result and downloaded artifact were verified afterward.

Delivery: [WO40-Zink-Touch-41200954123](https://github.com/arjunyerevan95-dot/OpenMWiOS/actions/runs/41200954123/artifacts/13044247922), artifact ID **13044247922**, archive 29,249,965 bytes. GitHub-reported archive digest: `sha256:59fe21df1abead44b118d96517fade00f67a50445372c235994d2c1458a97abf`; expiry 2026-11-30 13:23:33 UTC. Includes IPA, dSYM, manifest and compact logs.

- IPA: `OpenMW-Zink-Touch-unsigned.ipa`, 26,317,147 bytes; SHA-256 `50890e180c42bdfe5c77c5c8b40aae3ea28d7534fd31958bed3f3b24d22dc620`.
- Executable SHA-256: `b80a8ae91a462948cd3d678ba3241262881232037f0656976387ca18abe5f76b`; Mach-O UUID `8D3AFF23-3332-305A-A4D1-E75003429268`.
- Identity: `org.openmw.ios.zinktouch` / `OpenMW Zink Touch`; version 0.52.0 (1), iOS 18.0 minimum, arm64, unsigned.
- Local preserved delivery directory: `C:/Users/arjun/Documents/Codex/2026-08-14/you-are-taking-over-an-existing-2/.candidates/wo40-zink-touch/DerivedData/wo40-delivery/DerivedData/wo40-artifact/`. IPA, `OpenMW.dSYM.zip` (3,089,843 bytes) and `manifest.json` are present. Large artifacts remain outside Git.

Independent download checks passed: IPA/dSYM ZIP integrity, actual Info.plist identity, source/workflow revisions, IPA byte count and hash, extracted executable hash/arm64/UUID, absence of an embedded signature/provisioning profile, and bundled license resources. Details and limits: [validation](validation.md).

Budget consumed: **2 of maximum 2 macOS runs**. No further dispatch under WO40. No renderer/dependency/source scope expansion is involved. Full logs are preserved locally at `DerivedData/wo40-logs/primary-full.log` and `DerivedData/wo40-logs/repair-full.log` (ignored, not committed).

Touch-only device checklist (all observations pending):

1. Sideload the distinct OpenMW Zink Touch candidate; launch and load with the donor's normal data flow.
2. Move/look and exercise action controls; release each without stuck input.
3. Short-tap Menu once and twice; each tap should make one Menu action. Hold for 0.75 seconds: editor opens without Pause.
4. Move/resize a control, adjust movement radius and opacity; check Done, Cancel, confirmed Reset and Undo.
5. Save, force-quit/relaunch and check the saved layout/opacity.
6. Background/resume while holding input and connect/disconnect an external input device; no duplicate controller/menu action or stuck input.

Device validation: **pending**. User-waived old-renderer/performance comparison remains waived. No runtime baseline is advanced by this worker.
