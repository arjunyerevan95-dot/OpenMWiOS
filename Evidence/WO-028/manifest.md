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
- Initial semantic-dispatch correction: `96d753f91a37626b75c2f825a92e1fc0fb889d22`.
- Amended Android icon/layout, floating movement, and free-look correction: `111da2ba97ca0078e7f96f7d8966191a9d8db101`.
- Initial regression tests: 16 local tests run, 15 passed and one host C++ compile fixture skipped because no local `clang++`/`g++` is installed.
- Amended regression tests: 19 local touch tests run, 18 passed and one compiler-only fixture skipped; aggregate iOS validation ran 55 tests, 53 passed and two compiler-only fixtures skipped. All 12 embedded Android PNGs decode and report `128x128`; CI AppleClang remains the production compilation gate.
- Synthetic wide-iPhone result: passed `956x440`, safe area `0,62,21,62`.
- Synthetic smaller-iPhone result: layout recomputation test passed using a distinct orientation/aspect input.
- Synthetic landscape-iPad result: passed `1366x1024`, safe area `24,0,20,0`.
- Arbitrary-aspect result: passed `1180x820`, safe area `13,37,29,11`.
- Floating-stick status: implemented by device-test amendment. The movement origin is the first owned touch in the left movement region; no fixed idle movement circle remains.
- Look status: fixed right stick removed after the first device pass falsified it; the invisible broad free-drag relative-look region is restored.
- Icon provenance: eight GPL-3.0 gameplay PNGs from Android `2.7.4` commit `5b02e847dc646c9f10cd66001e4d65c5274dde49` plus the exact archived GPL-3.0 `third_person`, `save`, `journal`, and `wait` PNGs from `xyzz/openmw-android` commit `bfd613230ebe57170cbe4966aa8938d54afa6efa` are embedded in `ios/openmw_ios_touch_icons.hpp`; layout provenance is the same archived commit's `Osc.kt`.

## Build evidence

- First Fast Development run: `32494194803`, successful.
- First correction source commit: `96d753f91a37626b75c2f825a92e1fc0fb889d22`; control/evidence commit in the tested PR state: `d49779a0957c0cd2b2dd94659e7df589a7e9a280`.
- Full Qualification: did not run.
- Cache result: MISS; reported cache-hit/key outputs were empty. Cache ABI `ios-fast-v4-xcode16.4-ios16.3-arm64-edd5fbcd7e18a5d33a4de616e039704d860dd513c9140bfb34ccbee5f1003987`. No redesign or benchmark was started.
- Rebuilt components: dependency/configure path plus OpenMW production compile/link/package; GL4ES/OSG were not changed by WO28 source.
- Build duration: approximately `1h09m47s` (`2026-08-21T14:49:11Z` to `15:58:58Z`).
- First executable SHA-256: `E6BB8BEA0D9E3A4E5275E9919AD49716F28C4BB42277E623B2A5BF1316EF4D97`.
- First IPA SHA-256: `8184D02236A95CB399F80E176343DD540ECA686F108F14F3601F60335D8ACD06`; artifact `OpenMW-iOS-fast-28`, artifact ID `9453201466`.
- Amended corrective Fast run: NOT YET RECORDED.

## Device evidence

- Logging/preflight: NOT YET RECORDED
- Installation: first WO28 IPA installed successfully through the established route.
- User launch: completed; exact timestamp NOT RECORDED.
- Main-menu touch: NOT YET RECORDED
- Movement/look/multitouch: movement and look were sufficient to reach and traverse Seyda Neen. The visible fixed right-look stick was a user-reported regression; visual/layout fidelity failed.
- Activate/Attack/Jump: NOT YET RECORDED
- Inventory open/use/close: NOT YET RECORDED
- Journal/menu and weapon/magic: NOT YET RECORDED
- Dialogue and scene transition: NOT YET RECORDED
- Renderer regression: no low-level/fullscreen regression. Water visibly improved after the user enabled water shader effects; this is a settings observation, not a WO28 code correction.
- WO27 data-path regression: none observed; the game loaded without a UUID/manual-path intervention.
- Crash/jetsam: no user-observed crash or jetsam.
- Incidental performance: exterior traversal remained operational; not qualified.
- Exterior graphics defects: deferred. Nine screenshots show foliage alpha/cutout sheets and missing distance fog/white or empty regions beyond the selected draw distance. Water is no longer classified as a renderer defect because enabling its shader effects materially corrected its appearance. No WO28 graphics correction is authorized.
- First-pass screenshot evidence (user attachment directory `1CB41284-C970-4FD6-A145-D5E98D3616DE`): `1-Photo-1.jpg` SHA-256 `783290B6B501631B41FB083DEF8E6949AD1A10082BC21428A3958C2085C59EE7` is the Android acceptance reference; iOS screenshots 2â€“9 have SHA-256 values `553F04BF581F2FED1486556FDA6600D9DC9833E1E9E2BFE685C3365E7D0B9667`, `C3D279F75A29960C21B9F205A425D2ADCA21CD182E5426292442F0E47F3D7481`, `CECCCFBA175FA522492E8F3E2E051E461B3A88005B09FB8377331535009143BA`, `35C4C00DD1BCD6DB99932084501220A7D5A2BD4EB442450CBA0F93D68765B0F5`, `2598A60E98DD0226032D0F6A32004C7189919EB9294B51C335B10240F2CFB5F9`, `B18578B3BD2EEEFE09F6963942BB403C7CD22026FBC9B8895F1A279CF145AA64`, `2589040A6857A4B2B89053E011B50897FCB7D4E33F4699D4E5C35365DE8B508F`, and `C42C87637D0A4975F589BC62D3AB69F6E7FE96894F98749276DFFB41C3DF11FC`.

## Outcome

- Stop condition: NOT YET RECORDED
- Strongest conclusion: NOT YET RECORDED
- Recommended next boundary: NOT YET RECORDED
