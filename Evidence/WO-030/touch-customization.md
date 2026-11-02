# WO-030 touch customization execution note

## Implemented interaction contract

- Entry gesture: long-press the current saved Menu/Pause bounds for **0.75 seconds**.
- A Menu touch is held pending during arbitration. Release before the threshold emits one Pause press/release; crossing the threshold enters edit mode and emits no Pause event.
- Edit mode captures the overlay and suppresses SDL/OpenMW movement, look, mouse, and action dispatch.
- Dragging a control body moves it. Dragging near its edge resizes it.
- All twelve fixed controls, including Menu, are editable. Menu is clamped to the safe area with a 24-point minimum radius; other controls use an 18-point minimum.
- The movement control exposes an adjustable radius without changing its normal floating-origin ownership model.
- The toolbar provides `OPACITY -`, `OPACITY +`, `DONE`, `RESET`/`RESET?`/`UNDO`, and `CANCEL`.
- `Done` saves; `Cancel` restores the complete entry snapshot; Reset requires a second tap and can be undone before leaving.

## Persistence model

- Store: app-local `NSUserDefaults`, key `OpenMWIOSTouchProfileV1`.
- Schema version: `1`.
- Centers are normalized to the current safe-area rectangle.
- Radii and movement radius are normalized to the safe-area short side.
- Loading validates version and control count, then clamps sizes and all bounds to the current safe area.
- No sandbox UUID or absolute path is stored.

## Opacity

- Default idle alpha: **0.20**.
- Editable range: **0.05–0.85**, step **0.05**.
- Pressed alpha: `min(0.92, idle + 0.42)`.
- The diagnostic candidate incorrectly forced edit-mode preview alpha to `0.82`, so `OPACITY -/+` changed the model without visibly changing the editor preview.
- Final candidate `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27` removes that override and draws with the current profile alpha in edit mode and normal mode.

## Local validation

- `python -m unittest validation.test_ios_touch_controls validation.test_wo30_renderer_diagnostics`
- Result before diagnostic CI: 27 tests run, 26 passed, 1 skipped because no local C++ compiler was available.
- Covered contracts include long-press arbitration, persistence markers, edit-mode input suppression, opacity bounds, Menu safety, and normalized application to an iPad-like layout.
- Final aggregate validation: 59 tests run; 55 passed; 4 environment/compiler-dependent skips; 0 failures.
- Production Objective-C++ compilation, linking, packaging, and bundle validation passed in Fast run `32573611821`.

## Device validation

- Diagnostic candidate: user reported that touch-screen configuration worked except opacity preview.
- Final candidate: user reported, "That's a pass opacity is fixed and plus and minus visibly changes it."
- Final screenshot SHA-256: `2605641B92C3696C569ED39E94E2121EAEE969B98C7EA07C2237290C658B41B4`.
- The screenshot visibly shows the controls at low opacity over the live exterior scene.
- The user did not provide an independent force-quit/relaunch persistence assertion in the final message. Persistence remains source/test-backed rather than separately device-observed in this matrix.
- No crash, renderer regression caused by the touch editor, or WO27 data-path regression was reported during this check.

## Preserved invariants

- Existing action mappings and icon assets are unchanged.
- Existing floating movement origin, free-drag look, ownership model, GUI passthrough outside visible controls, and non-ARC retained icon cache are not replaced.
- WO27 data-path logic and all renderer/presentation code remain unchanged by the touch implementation.

## Touch-track outcome

**DEVICE-ACCEPTED with the stated validation limits.** Long-press editor functionality was accepted on the diagnostic candidate, and the only reported defect—hardcoded edit-preview opacity—was corrected and visibly accepted on the final candidate.
