# WO-038 Amendment 1 — Pause Short-Tap Correction

Status: **LOCAL CORRECTION VALIDATED; AMENDMENT FAST BUILD PASSED; DEVICE CHECK PENDING**

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

## Production build

The single authorized Amendment 1 Fast build completed successfully. Production compilation/linking, bundle validation, packaging, and artifact upload all passed. No replacement build was dispatched.

- Runtime correction commit: `457ab881442302a9bd59435c1878ed4e72f6e52b`
- Fast run: `33306995685`
- Product artifact: `OpenMW-iOS-fast-67`, artifact ID `9730898326`
- Artifact digest: `sha256:41709748e6cad3d8e48b1244ae42ee96a35ea7eb2607b751f8d6f834b69c315b`
- IPA SHA-256: `9312ea3b1ad757e9cee8a22785907f93ad9c68a33e02d845210ff5f733660593`
- Executable SHA-256: `26a73e55775a15bfdb60cc6c05861e1f790f60dfc920a5ef7b4087f7822ed912`
- Job duration: 731 seconds; run duration: 758 seconds
- Cache result: source-download and vcpkg caches were exact hits; qualified incremental state restored through the authorized fallback key (`build_state_cache_hit=false` for an exact-key match).

## Pending physical contract

Device checks remain pending. Required checks are short-tap Pause, long-press editor without Pause leakage, moved/cancelled touch suppression, and nearby movement/look/action regression. A successful Pause check then permits prepared-save creation and continuation of the existing target attribution with this same IPA.
