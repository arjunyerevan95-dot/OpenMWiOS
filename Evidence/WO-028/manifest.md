# WO-028 Evidence Manifest

- Work order: [WO-028 — Android Touch UI / Action Fidelity](../../WorkOrders/WO-028.md)
- Status: ACTIVE
- Engineering baseline: `6db1c2af5066f810df97c5af39bdbf2a48fb86b5`
- Control-plane baseline: `50a84c34fc213c20e8653e565b90b94da636013c`
- Active branch: `codex/wo28-android-touch-fidelity`

## Starting-state verification

- Both issued baseline commits resolve locally.
- Branch creation point: control-plane commit `50a84c34fc213c20e8653e565b90b94da636013c` atop WO27 engineering commit `6db1c2af5066f810df97c5af39bdbf2a48fb86b5`.
- Local control-plane state was one commit ahead of `origin/codex/wo27-runtime-data-path`; the migration commit had not been pushed.
- Latest successful engineering CI: WO27 Fast run `32480504839` at `6db1c2a`.
- No active CI run existed at WO28 issue time.
- Pre-existing dirty/untracked handoffs, ledger edits, temporary files, and bytecode caches were preserved and are not WO28 changes.

## Qualified evidence carried forward

- [DEC-001](../../Decisions/DEC-001.md): qualified renderer/runtime baseline.
- [DEC-002](../../Decisions/DEC-002.md): movement/look traversal works; Android fidelity is incomplete.
- [DEC-003](../../Decisions/DEC-003.md): current Documents-based default game-data resolution.
- [WO27 manifest](../WO-027/manifest.md): accepted candidate and device evidence.

## Android reference

- Repository: `https://gitlab.com/modding-openmw/openmw-android-docker.git`
- Tag/line: `2.7.4`
- Commit: `5b02e847dc646c9f10cd66001e4d65c5274dde49`
- Touch UI paths: `EngineActivity.kt`, `DynamicButtons.kt`, `DynamicLeftThumbstick.kt`, `DynamicRightThumbstick.kt`, `StateManager.kt`, and `payload/app/ui/UI.cfg` as pinned in `validation/fixtures/android-touch-2.7.4-reference.json`.
- Native bridge: `patches/openmw/androidmain.cpp`; Android forwards relative mouse/button events through SDL internals and provides a virtual-stick bridge.
- OpenMW input authority: pinned `apps/openmw/mwinput/bindingsmanager.cpp` controller defaults and Android `payload/app/ui/input_v3.xml`.

## Android control inventory

[Android/iOS touch-control audit](android-ios-control-audit.md) records every default Android control, ID, source event, bridge/semantic path, mode/hold behavior, normalized location, and WO26/WO28 disposition.

## iOS before/after inventory

[Android/iOS touch-control audit](android-ios-control-audit.md) is the compact before/after inventory. The decisive WO26 gaps were:

- `WRONG ACTION`: Inventory injected keyboard `B`, which is not OpenMW's default Inventory binding.
- `WRONG EVENT TYPE`: action icons generally guessed keyboard events instead of using OpenMW semantic controller bindings.
- `WRONG LAYOUT`: arbitrary right-side 3x3 grid rather than Android `UI.cfg` grouping.
- `PARTIAL`: look worked through an invisible broad region but did not reproduce the Android right-stick target.
- `MISSING`: direct Journal affordance and GUI-mode semantic controls.

## Known starting defect

- Before Inventory dispatch: touch `INV` → keyboard `B` injection → inventory does not open.
- Implemented after dispatch: touch `INV` → virtual-controller `SDL_CONTROLLER_BUTTON_B` press/release → OpenMW `A_Inventory`; if virtual attachment is unavailable, use OpenMW's default right-mouse Inventory path rather than keyboard `B`.

## Implementation and regression evidence

- Action-dispatch architecture: touch-ID-owned control → SDL virtual game controller → pinned OpenMW semantic controller binding. Relative mouse look remains the Android-equivalent public SDL event path. Keyboard/mouse defaults are fallback-only.
- Files changed: `ios/openmw_ios_touch_model.hpp`, `ios/openmw_ios_touch_controls.mm`, `validation/test_ios_touch_controls.py`, `validation/fixtures/android-touch-2.7.4-reference.json`, and WO28 evidence/control-plane records.
- Correction commits: NOT YET RECORDED
- Regression tests: 16 local tests run, 15 passed and one host C++ compile fixture skipped because no local `clang++`/`g++` is installed. CI AppleClang remains the production compilation gate.
- Synthetic wide-iPhone result: passed `956x440`, safe area `0,62,21,62`.
- Synthetic smaller-iPhone result: layout recomputation test passed using a distinct orientation/aspect input.
- Synthetic landscape-iPad result: passed `1366x1024`, safe area `24,0,20,0`.
- Arbitrary-aspect result: passed `1180x820`, safe area `13,37,29,11`.
- Floating-stick status: deferred; fixed Android-derived stick retained for fidelity qualification.

## Build evidence

- Fast Development run: NOT YET RECORDED
- Full Qualification: MUST NOT RUN
- Cache result: NOT YET RECORDED
- Rebuilt components: NOT YET RECORDED
- Build duration: NOT YET RECORDED
- Executable SHA-256: NOT YET RECORDED
- IPA SHA-256: NOT YET RECORDED

## Device evidence

- Logging/preflight: NOT YET RECORDED
- Installation: NOT YET RECORDED
- User launch: NOT YET RECORDED
- Main-menu touch: NOT YET RECORDED
- Movement/look/multitouch: NOT YET RECORDED
- Activate/Attack/Jump: NOT YET RECORDED
- Inventory open/use/close: NOT YET RECORDED
- Journal/menu and weapon/magic: NOT YET RECORDED
- Dialogue and scene transition: NOT YET RECORDED
- Renderer regression: NOT YET RECORDED
- WO27 data-path regression: NOT YET RECORDED
- Crash/jetsam: NOT YET RECORDED
- Incidental performance: NOT YET RECORDED
- Exterior graphics defects: deferred; no WO28 correction authorized

## Outcome

- Stop condition: NOT YET RECORDED
- Strongest conclusion: NOT YET RECORDED
- Recommended next boundary: NOT YET RECORDED
