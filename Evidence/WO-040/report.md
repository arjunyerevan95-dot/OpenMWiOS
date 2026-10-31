# WO40 execution report

Status: primary build failed in CI preflight; bounded repair prepared and locally verified.

The selected Zink source is pinned and the customizable touch port is isolated on codex/wo40-zink-touch. See [manifest](manifest.md), [integration](integration.md) and [validation](validation.md). Graphics/dependency pins and patches are unchanged. Existing repositories/artifacts and canonical files remain intact.

Implementation commit: 5b55597d9e183a50e7eed4594f9bc1444ec4dd6a; primary source/workflow: 439bf57a445297bfa0b5ac4afa839f3a20e6bdd7. Initial [skip ci] publication produced no workflow; the intentional primary publication produced only the candidate workflow.

Primary run [41199873586](https://github.com/arjunyerevan95-dot/OpenMWiOS/actions/runs/41199873586), 2026-10-31 12:09:57–12:10:13 UTC: failed before compilation in Verify foundation and runner. Runner was arm64 with Xcode 27.1 / 27A9275. The worker-authored version assertion piped xcodebuild to grep -q under pipefail. grep closed its input on the matching first line, and xcodebuild raised NSFileHandleOperationException/Broken pipe writing its second line (exit 134). No product/dependency compilation or IPA exists from this run.

Repair is solely the workflow preflight: capture the complete xcodebuild output, print it, and compare the first line with a Bash pattern, without a short-reading pipe. A local executable harness ran the actual old/fixed YAML shell step with delayed two-line xcodebuild output and stubbed runner identity: old exit 141, fixed exit 0; actual Git ancestry and renderer-diff checks passed. The first local harness attempt had a Windows PATH translation error; it was corrected before these results.

Primary log-only artifact: WO40-Zink-Touch-41199873586, ID 13042187353, 356 bytes, digest sha256:61744e644c7db50d837a2c2f8eb2fd36d2c363617191a174c8dffbda024a1cd7. This is not an IPA.

Budget consumed: **1 of maximum 2 macOS runs**. Exactly one repair build remains authorized; no renderer/dependency/source scope expansion is involved.

Touch-only device checklist after successful artifact delivery:

1. Sideload the distinct OpenMW Zink Touch candidate; launch and load with the donor's normal data flow.
2. Move/look and exercise action controls; release each without stuck input.
3. Short-tap Menu once and twice; each tap should make one Menu action. Hold for 0.75 seconds: editor opens without Pause.
4. Move/resize a control, adjust movement radius and opacity; check Done, Cancel, confirmed Reset and Undo.
5. Save, force-quit/relaunch and check the saved layout/opacity.
6. Background/resume while holding input and connect/disconnect an external input device; no duplicate controller/menu action or stuck input.

Device validation: **pending**. User-waived old-renderer/performance comparison remains waived. No runtime baseline is advanced by this worker.
