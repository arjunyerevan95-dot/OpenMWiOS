# Touch integration

Foundation is joedemo42/OpenMW 2931be63bd2147e437a2b077ed6c97f563648a0a. The four controls/header/model/icons files were read with git show from accepted project commit 93f892dd0cf9834259b4cad2045ddb2ef9c53ed9 and placed under apps/openmw/ios. This ports the accepted WO30 practical behavior, including its WO29 owned UIImage cache; it does not import the old bootstrap or any renderer code. Pause press/observe/release semantics derive selectively from WO38 candidate 457ab881442302a9bd59435c1878ed4e72f6e52b, extended to observe the release before another rapid tap.

## File-level changes and ownership

| File | Change |
|---|---|
| apps/openmw/ios/openmw_ios_touch_controls.{h,mm} | UIKit adapter, exact SDL window attachment, lifecycle, profile parsing and editor |
| apps/openmw/ios/openmw_ios_touch_model.hpp | Exact accepted geometry/action/ownership model |
| apps/openmw/ios/openmw_ios_touch_icons.hpp | Exact accepted icon data/attribution |
| apps/openmw/ios/openmw_ios_touch_state.hpp | Executable menu arbitration, profile validation/editor state, device policy |
| apps/openmw/ios/platform.mm | Replace only GC virtual controller/two-finger input with overlay policy; all renderer/audio/memory initialization preserved |
| apps/openmw/mwinput/inputmanagerimp.cpp | iOS-only install, explicit game/GUI transition, shutdown hooks |
| apps/openmw/CMakeLists.txt | Compile adapter in existing static app target with explicit MRC |
| ios/build.sh | Add credential-free --unsigned build option and packaging of an already unsigned app |
| .github/workflows/push.yml | Exclude candidate from inherited general builds |
| .github/workflows/wo40-ios.yml | Exact-branch/path/intent-guarded unsigned integrated device build |
| validation/wo40/* | Executable host contract, wiring/preservation guards, artifact validation/manifest |

InputManager installs after its SDL callbacks exist. Installation resolves its exact SDL_Window ID through SDL_GetWindowWMInfo to the UIKit root view, without key-window guessing. UIKit mutations execute directly on the main thread or are queued there. The display link and notifications run on that thread; InputManager teardown stops the link, releases held input, removes observers, detaches the virtual joystick by current instance/index and releases the owned view. Cached images retain the accepted alloc/init MRC ownership. No asynchronous delayed Menu block can fire against a reused touch address.

Game/GUI mode comes from InputManager::changeInputMode, not SDL cursor visibility. The overlay receives gameplay touches and leaves ordinary GUI touches to the SDL view, retaining only Inventory/Journal/Menu hit regions. No GCVirtualController or two-finger Menu action remains. Physical GC keyboard, non-CoreDevice mouse, or controller suppresses the overlay and releases/detaches its virtual joystick. Physical controllers retain controller menus; touch and keyboard/mouse use pointer menus. The SDL virtual joystick is not a native GCController and cannot suppress itself.

Mappings preserved: A=Activate, B=Inventory, X=Weapon, Y=Magic, START=Menu, L3=Sneak, L1=Journal, right trigger=Attack, left trigger=Jump; POV/Quicksave/Wait use Tab/F5/T and look uses relative mouse motion. Trigger storage releases to SDL_JOYSTICK_AXIS_MIN (logical unpressed), movement to zero. SDL updates observe button/trigger edges. Fallback keyboard/mouse events remain available when virtual attachment fails.

Menu arbitration uses the current monotonic 0.75-second deadline, cancels on movement beyond 14 points, rejects a second finger on Menu, and consumes long-press release. A slow display-link frame is also handled at touchesEnded. Cancellation, editor entry, GUI transitions, relayout, backgrounding and device takeover clear ownership/held input. Editor consumes its touches without generating gameplay actions.

Profiles remain V1 and safe-area relative under NSUserDefaults key OpenMWIOSTouchProfileV1, scoped to the distinct candidate bundle. Numeric types, count, version, finiteness and ranges are validated before assigning any loaded profile; otherwise defaults remain intact. Done saves, Cancel restores the snapshot; Reset is confirmed then can be undone and preserves chosen opacity, matching the accepted practical donor behavior. The explicit resize ring is still on the selected control. Nominal default opacity is 0.20. Historical device-persistence/complete-action-matrix qualification is not claimed.

## Build boundary

The original dependency recipes and graphics patches are byte-for-byte unchanged. The build invokes the donor dependency/engine/app flow, changing only the app signing policy for --unsigned. It neither uses old GL4ES CI nor requests signing credentials. Imported release workflow is tags-only; macos/windows workflows are reusable only; general push workflow excludes this branch. Candidate workflow requires this branch, a relevant path and [wo40-build] in the head message. Evidence-only commits use [skip ci]. No main/canonical workflow changes.

The documented [xcode-27 runner](https://github.com/actions/runner-images/blob/main/images/macos/xcode-27-arm64-Readme.md) lists Xcode 27.1 at /Applications/Xcode_27.1.app and iOS 27.1 SDK (inventory inspected 2026-10-31). CI selects that path and verifies arm64/version before using pinned donor recipes; timeout is 180 minutes. It installs only their host build tools, including the bison@3.8 explicitly required by Mesa's recipe. Generated artifact manifest verifies architecture, distinct identity, unsigned status, hashes, UUID, source/workflow revision and dependency archive hashes.
