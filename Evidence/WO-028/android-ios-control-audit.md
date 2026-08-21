# WO-028 Android/iOS Touch-Control Audit

## Pinned Android reference

- Repository: `https://gitlab.com/modding-openmw/openmw-android-docker.git`
- Tag: `2.7.4`
- Commit: `5b02e847dc646c9f10cd66001e4d65c5274dde49`
- Overlay composition: `payload/app/src/main/java/org/openmw/EngineActivity.kt`
- Default layout: `payload/app/ui/UI.cfg`
- Button dispatch: `payload/app/src/main/java/org/openmw/ui/controls/DynamicButtons.kt`
- Left stick: `payload/app/src/main/java/org/openmw/ui/controls/DynamicLeftThumbstick.kt`
- Right stick: `payload/app/src/main/java/org/openmw/ui/controls/DynamicRightThumbstick.kt`
- Layout persistence: `payload/app/src/main/java/org/openmw/ui/controls/StateManager.kt`
- Native bridge: `patches/openmw/androidmain.cpp`
- OpenMW semantic defaults: `apps/openmw/mwinput/bindingsmanager.cpp` in the pinned OpenMW source.

Android uses normalized top-left positions from `UI.cfg`, persistent pointer ownership in separate Compose controls, relative mouse motion for look, and both keyboard and GUI-specific mouse behavior for its default button overlay. OpenMW itself provides stable controller-level semantic bindings, which are the iOS dispatch target because they remain correct in gameplay and GUI modes.

## Android control/action inventory and iOS disposition

| Visible function | Android ID / source event | Android behavior | OpenMW semantic binding | WO26 iOS | WO28 iOS |
|---|---|---|---|---|---|
| Movement | `99`; virtual left stick | Analog normalized X/Y; optional WASD fallback | `LEFTX` / `LEFTY` | MATCHES behavior; wrong layout grouping | Preserved analog controller axes; Android normalized placement |
| Look | `98`; right stick/relative mouse | Relative mouse or right-stick path | Relative mouse / `RIGHTX` / `RIGHTY` | PARTIAL: invisible broad right region | Visible fixed Android-position look target; relative mouse preserved |
| Activate / Use | `6`; Android key 62 (`SPACE`) | Press/release | controller `A`; keyboard `SPACE` fallback | keyboard `SPACE` | virtual-controller `A` |
| Attack / Use weapon | `2`; Android key 54 (`Z`), GUI mouse-left special case | Hold press/release | right-trigger axis; mouse-left fallback | keyboard `Z` | virtual right trigger |
| Jump | `4`; Android key 33 (`E`) | Hold press/release | left-trigger axis; keyboard `E` fallback | keyboard `E` | virtual left trigger |
| Ready weapon | `7`; Android key 34 (`F`) | Press/release | controller `X`; keyboard `F` fallback | keyboard `F` | virtual-controller `X` |
| Ready magic | `8`; Android key 46 (`R`) | Press/release | controller `Y`; keyboard `R` fallback | keyboard `R` | virtual-controller `Y` |
| Inventory | `3`; Android key 30 (`B`), GUI mouse-right special case | Pulse plus GUI right-click behavior | controller `B`; mouse-right fallback | **WRONG ACTION:** keyboard `B` | virtual-controller `B`; right-mouse fallback only if virtual controller is unavailable |
| Pause / menu | `1`; Android key 111 (`ESC`) | Press/release | controller `START`; keyboard `ESC` fallback | keyboard `ESC` | virtual-controller `START` |
| Sneak | `9`; Android key 113 (`LCTRL`) | Hold press/release | controller left-stick; keyboard `LCTRL` fallback | keyboard `LCTRL` | virtual-controller left-stick |
| Journal | Android menu/utility affordance; not one of the eight default `UI.cfg` action circles | Controller/menu integration | controller left shoulder; keyboard `J` fallback | MISSING | Direct `JRN` companion target using virtual-controller left shoulder |

All virtual actions emit both press and release. Attack and Jump use trigger-axis maximum for press and zero for release. Touch IDs remain sticky to Movement, Look, or one Button until end/cancel.

Android's broader Compose overlay also contains `AutoMouseModeComposable`/`MouseIcon`, a virtual keyboard, quick-slot `HiddenMenu`, an editable radial/expandable utility menu, scroll-wheel indicator, and the control-layout editor/grid. These are not additional fixed default gameplay actions in `UI.cfg`. Their WO28 dispositions are:

| Android overlay facility | iOS disposition | Reason |
|---|---|---|
| GUI mouse mode/icon | `NOT APPLICABLE` | iOS sends ordinary GUI touches to the underlying SDL/UIKit view; semantic Inventory/Menu/Journal controls remain available separately. |
| Android virtual keyboard | `ADAPT TO IOS` (existing path preserved) | UIKit/SDL native text input is already qualified; Android keyboard plumbing is platform-specific. |
| Quick-slot hidden menu | `MISSING / DEFERRED` | Not required for the ordinary early-game action baseline and has no direct fixed `UI.cfg` action. |
| Editable radial/utility menu | `MISSING / DEFERRED` | Android launcher/customization product layer, not required for semantic action qualification. |
| Scroll-wheel indicator | `NOT APPLICABLE` for baseline | Direct GUI touch remains available; no evidence it blocks early-game use. |
| Layout editor/grid and launcher preferences | `DO NOT PORT` in WO28 | Android-specific customization and persistence layer is outside functional-fidelity scope. |

## Layout comparison

WO26 generated an arbitrary three-by-three action grid on the right and treated most of the right half as an invisible look region. It copied Android default keycode names into a provenance fixture, but did not port `UI.cfg` positions, the right-stick control, Android visibility behavior, or GUI-specific action semantics. This explains both the visibly sparse/different overlay and the broken Inventory button.

WO28 uses the normalized Android 2.7.4 positions as safe-area-relative anchors. Button radii still derive from the runtime short side, and all centers are clamped to the current safe area. No iPhone model, physical pixel resolution, Retina scale, or fixed notch dimensions are embedded. The direct Journal target is the one deliberate functional extension required by WO-028; Android exposes Journal through its broader menu/utility layer.

## Gameplay / GUI mode contract

- Gameplay: movement, look, and all actions are visible and independently own touches.
- GUI: Movement and Look are suppressed. Inventory, Journal, and Menu remain visible and actionable through controller semantics; all other coordinates pass through to the underlying SDL/UIKit view.
- Mode transition: all held virtual axes/buttons and touch ownership are released before the new mode is used.
- Text entry: non-control coordinates pass through in GUI mode, preserving UIKit/SDL text input.

## Durable limitations

- Android artwork and the Nexus icon pack are not ported; functional circles/labels remain.
- Android launcher customization and per-user control editing are intentionally unported.
- The left stick remains fixed for the Android-fidelity qualification. Floating-stick behavior remains the first recommended UX refinement after qualification.

## Device-test amendment: first WO28 interpretation falsified

The first WO28 IPA from Fast run `32494194803` reached Seyda Neen with the renderer, water-shader option, WO27 data discovery, movement, and free gameplay progression intact. It did **not** qualify Android UI fidelity. The user's direct comparison against the Android interface established:

- the fixed visible right stick was a regression; the previously qualified broad, invisible relative-look region was the correct iOS behavior;
- the fixed visible movement stick was not the requested iOS UX; movement must acquire a floating origin from the first touch in the left movement region and need not remain visible while idle;
- text labels in circular placeholders did not reproduce Android iconography;
- projecting only the newer editable `UI.cfg` subset did not reproduce the complete Android OSC grouping visible in the user's reference.

The exact screenshot layout was then traced to the archived Android OSC lineage rather than guessed from pixels:

- Repository: `https://github.com/xyzz/openmw-android`
- Commit: `bfd613230ebe57170cbe4966aa8938d54afa6efa`
- Source: `app/src/main/java/ui/controls/Osc.kt`
- Virtual layout: `1024x768`
- Core default positions: `pause=(940,0)`, `inventory=(940,95)`, `sneak=(850,0)`, `magic=(940,450)`, `weapon=(940,560)`, `attack=(800,315,size=120)`, `use=(330,630)`, and `jump=(624,630)`.
- Top utility actions used by the corrected iOS baseline: third-person `(90,0)`, quick save `(180,0)`, journal `(270,0)`, and wait `(360,0)`.

The amended iOS design retains the already-proven semantic virtual-controller dispatch, but supersedes the first-pass presentation/ownership model:

| Area | First WO28 IPA | Amended WO28 correction |
|---|---|---|
| Movement | Fixed visible circle | Floating touch origin anywhere in the left movement region; indicator appears only while owned |
| Look | Fixed visible circle | Invisible broad right-side free-drag region; relative mouse deltas preserved |
| Core and top-row actions | Text circles | Pinned GPL-3.0 Android gameplay and utility icons |
| Placement | Newer `UI.cfg` subset | Archived OSC `1024x768` virtual coordinates projected through current safe area |
| Utilities | Journal only | Third-person, quick save, journal, and wait at OSC top-row positions |

This addendum supersedes only the earlier layout/look/artwork conclusions. The controller-level semantic action findings, especially Inventory controller `B`, remain supported and unchanged.
