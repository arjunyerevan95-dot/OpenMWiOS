# WO-038 Amendment 1 — Pause Short-Tap Correction

Status: **LOCAL CORRECTION VALIDATED; AMENDMENT FAST BUILD PENDING**

## Exact cause

The iOS Pause/Menu short-tap path deferred action dispatch until `finishTouches`, then wrote virtual controller START pressed and released in the same UIKit callback. Pinned SDL's `SDL_JoystickSetVirtualButtonInner` stores only the latest virtual-button value. `VIRTUAL_JoystickUpdate` emits the transition later. The back-to-back writes could therefore collapse to released before SDL/OpenMW observed the pressed edge.

Ordinary buttons did not have this defect because their press in `touchesBegan` and release in `finishTouches` span separate callbacks and input updates.

## Bounded correction

- `ios/openmw_ios_touch_model.hpp`: `dispatchPauseShortTap` encodes the exact press / observe / release contract and suppresses cancellation or long-press consumption.
- `ios/openmw_ios_touch_controls.mm`: the completed, unmoved short-tap path now writes START pressed, invokes one `SDL_JoystickUpdate()` observation opportunity, then writes START released.
- The release remains stored for the next normal SDL joystick update, while the forced update has already queued the pressed transition. No second forced update or input-loop redesign was added.

The 0.75-second long-press threshold, editor path, movement cancellation, ownership, layout/profile, opacity, persistence, mappings, and all non-Pause actions are unchanged. SDL and OpenMW input semantics are unchanged.

## Deterministic validation

`validation/test_wo38_pause_short_tap.py` compiles and runs a C++17 fixture against the production helper. It proves:

- a valid tap emits exactly `press -> observation -> release`;
- observation occurs while the action is pressed;
- exactly one press, one observation, and one release occur per valid tap;
- cancellation emits nothing;
- a long-press consumed by the editor emits nothing; and
- a subsequent tap starts cleanly and cannot inherit a stuck pressed state.

The fixture passed under MSVC 19.44. The adapter integration assertion also proves the obsolete same-callback immediate pair is absent and the SDL observation is present.

Focused iOS touch / WO37 / WO38 validation ran 43 tests with 42 passing, one inherited CRLF-sensitive pristine-OSG patch-application failure, and two skips. Aggregate validation ran 165 tests with the same two inherited CRLF-sensitive OSG patch failures, two inherited Windows executable-format errors, and nine skips. No new Amendment 1 test failed. Python syntax and `git diff --check` passed.

## Pending physical contract

The single authorized Amendment 1 Fast build and device checks remain pending. Required device checks are short-tap Pause, long-press editor without Pause leakage, moved/cancelled touch suppression, and nearby movement/look/action regression.
