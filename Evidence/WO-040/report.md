# WO40 execution report

Status: implementation and local contract validation ready; integrated build not yet dispatched at this commit.

The selected Zink source is pinned and the customizable touch port is isolated on codex/wo40-zink-touch. See [manifest](manifest.md), [integration](integration.md) and [validation](validation.md). Graphics/dependency pins and patches are unchanged. Existing repositories/artifacts and canonical files remain intact.

Build results and artifact identity will be appended after the authorized integrated run. Budget currently consumed: 0 of maximum 2 macOS runs.

Touch-only device checklist after successful artifact delivery:

1. Sideload the distinct OpenMW Zink Touch candidate; launch and load with the donor's normal data flow.
2. Move/look and exercise action controls; release each without stuck input.
3. Short-tap Menu once and twice; each tap should make one Menu action. Hold for 0.75 seconds: editor opens without Pause.
4. Move/resize a control, adjust movement radius and opacity; check Done, Cancel, confirmed Reset and Undo.
5. Save, force-quit/relaunch and check the saved layout/opacity.
6. Background/resume while holding input and connect/disconnect an external input device; no duplicate controller/menu action or stuck input.

Device validation: **pending**. User-waived old-renderer/performance comparison remains waived. No runtime baseline is advanced by this worker.
