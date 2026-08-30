# WO-029 Crash Classification

## Identity match

The rejected WO28 unsigned executable has Mach-O UUID:

`FD8A7812-C514-3995-BB1C-08F921EBCD7B`

Every August 22 crash report below records slice UUID:

`fd8a7812-c514-3995-bb1c-08f921ebcd7b`

The installed SideStore-signed application was independently queried as:

- bundle identifier: `org.openmw.ios.7CP756AU4P`
- original/alternate bundle identifier: `org.openmw.ios`
- version/build: `0.1` / `1`
- executable: `openmw`
- installed bundle path: `/private/var/containers/Bundle/Application/1DEB5798-B8A2-4E70-BFE8-B8E8E7FFBE0F/App.app`
- signer team identifier: `7CP756AU4P`
- `get-task-allow`: `true`
- profile validation: `true`

Code signing changed the installed bundle identifier but did not change the executable UUID. The reports therefore match the exact rejected CI executable.

## Report inventory

Thirteen matching reports were pulled read-only from the device. Full reports remain in the local execution workspace at `.tmp/wo29/device/pre/`; the table retains their durable incident and SHA-256 identities without committing the large raw reports.

| Report | Incident | Runtime phase from stack | Signal | SHA-256 |
|---|---|---|---|---|
| `openmw-2026-08-22-000925.ips` | `25AFE41B-D3D7-470E-AD46-3E7256E28F05` | launch / `prepareEngine` | SIGSEGV | `D41BB8AE094833C2DEB9F7F54DDEF983373AEB78968934BC57FBE00A2D9F124E` |
| `openmw-2026-08-22-000937.ips` | `73B43BC4-7331-405B-8B60-F027868C9930` | `New Game` transition | SIGSEGV | `7A8EC8160BB97E9332441A0B440AB4DD2454371DF00D6175D4695C312844A129` |
| `openmw-2026-08-22-000947.ips` | `6E69AD3A-2BFF-4633-9E69-B3B0BA9AB99F` | `New Game` transition | SIGSEGV | `6CFB888272E8841F2CDA4D2C39B70430C7D2AA1EBEE1F59AA26696A3692D05D6` |
| `openmw-2026-08-22-001018.ips` | `C8F04EC2-43ED-4FCE-8289-78E675C9F0E3` | menu/overlay frame | SIGSEGV | `85DA366E859025AF9D9A5C7D0052C0892E9977B689C37B0834733E1B7E5A6826` |
| `openmw-2026-08-22-001019.ips` | `73688B18-FF0C-4BE3-9218-10488EBF97D6` | launch / `prepareEngine` | SIGABRT | `432AC5DCDC6DC9CE9C640F4C5E1A1F3E5DC14F9DB8EF446DBFFB92C73237BF2E` |
| `openmw-2026-08-22-001023.ips` | `F654EB55-A56A-4464-9AE5-ACE99AC90F52` | menu/overlay frame | SIGSEGV | `1610B6F79995855684F2038CCCD43F6E80FDED25BA389D51170824845A1F165B` |
| `openmw-2026-08-22-001028.ips` | `67DB4F50-373B-421D-AC83-A1B6BAB2F1DA` | menu/overlay frame | SIGABRT | `F7767303E3B40505F9BB48A77D217C4F5F887361BD9300BEEB8FD33BF6B2790A` |
| `openmw-2026-08-22-001841.ips` | `F99742D1-BFB8-4CE1-A7F6-EF76E2CEDCB1` | menu/overlay frame | SIGABRT | `893FD1994D19B8B07B4016B3FD3050F49420029E33D32622820C02DDAA5D2AD0` |
| `openmw-2026-08-22-001843.ips` | `C097BD4C-E4AB-4A29-8167-C08D3BAD2409` | launch / `prepareEngine` | SIGSEGV | `E2220851661D4ADB0F81C2787BDF6882EB916B5C6C70422E3C77FCD32C27CA8D` |
| `openmw-2026-08-22-001844.ips` | `7D8AEDD9-43DE-4280-AD09-EFF7E610BD4D` | launch / `prepareEngine` | SIGSEGV | `03E519AC5B4388F4ACEB2B6E169B33918DDB9A6439136118BA9873F9E1A0F08B` |
| `openmw-2026-08-22-001900.ips` | `20A530B0-2751-495C-B1D1-E2E66431F2CF` | overlay action/redraw | SIGABRT | `777522AD21F5F26C0163632A7EAA44E7E24008C2FBBB429940678CEE685FD450` |
| `openmw-2026-08-22-001904.ips` | `363257C0-C294-42A4-B0D6-63453D0070D5` | launch / `prepareEngine` | SIGSEGV | `203FBEED4025A2F5EC4A3CF7D16319C164C393573214F37637C7739BA3E4E73F` |
| `openmw-2026-08-22-001908.ips` | `92AE88B0-C944-41E9-B280-45EE84C8CF40` | `New Game` transition | SIGSEGV | `4914097A28826317B81A7363CAD178539164262641F25B968F10073079B1F921` |

Counts: 13 total; 9 `EXC_BAD_ACCESS`/SIGSEGV; 4 Objective-C exception/SIGABRT; 5 launch, 3 explicit `New Game`, and 5 menu/overlay-frame reports.

Reports from August 21 with UUID `6BE13745-...` are an older GL4ES crash boundary and are excluded from the WO28 candidate classification. August 16 reports are likewise older candidates.

## Common fault signature

All thirteen matching reports have the same application fault site:

`-[OpenMWTouchOverlay drawRect:] + 0x35c`

The nine SIGSEGV reports fault in `objc_msgSend` immediately above that frame. The four SIGABRT reports contain an Objective-C `NSInvalidArgumentException` at the same application instruction. Representative exception reasons are:

`-[OS_dispatch_mach imageWithTintColor:renderingMode:]: unrecognized selector sent to instance ...`

and:

`-[IOGPUMetalDeviceShmem imageWithTintColor:renderingMode:]: unrecognized selector sent to instance ...`

The expected receiver of `imageWithTintColor:renderingMode:` is the cached `UIImage* icon` in `drawRect:`. Seeing unrelated dispatch/Metal objects as the receiver is direct evidence that the cached pointer outlived its original object and its address was reused.

## Path correlation

- **Launch path:** five reports show `drawRect:` below `LoadingScreen::draw` and `OMW::Engine::prepareEngine`.
- **New Game path:** three reports show `drawRect:` while the same main thread is executing `MWGui::MainMenu::onButtonClicked`, `MWState::StateManager::newGame`, and the initial cell transition.
- **Overlay-action path:** `startup.jsonl` records `action=MENU;pressed=yes;path=virtual-controller` at `2026-08-21 18:48:59 +0000`; report `openmw-2026-08-22-001900.ips` follows at `00:19:00 +0530` (the same instant plus one second) with the common `drawRect:` unrecognized-selector signature. Other menu-frame crashes share the signature.

Pairwise classification:

| Pair | Result | Basis |
|---|---|---|
| Launch vs New Game | `CONVERGED` | exact UUID and same `drawRect:+0x35c` fault; distinct surrounding lifecycle stacks |
| Launch vs overlay action | `CONVERGED` | exact UUID and same fault; action timestamp correlates to report `001900` |
| New Game vs overlay action | `CONVERGED` | exact UUID and same fault; New Game and action-specific contexts differ only below asynchronous overlay redraw |

## Proven source mechanism

The rejected source's `imageForAction` cache used:

```objective-c
NSData* data = [[NSData alloc] initWithBase64EncodedString:string options:0];
return [UIImage imageWithData:data];
```

The exact WO28 CI compile command for `openmw_ios_touch_controls.mm` contains no `-fobjc-arc`; its compiler warning about a missing `[super dealloc]` call independently confirms manual reference counting. `+[UIImage imageWithData:]` returns an autoreleased image. Storing that pointer in a C++ `std::array<UIImage*>` does not retain it under this build. After the autorelease pool drains, later overlay redraws message a dangling address. Depending on reuse state, this produces either invalid-address `objc_msgSend` or an unrecognized selector on a new object occupying the address.

Earliest proven invalid state: the process-lifetime icon cache accepts an autoreleased image without acquiring ownership.

## Bounded correction

The cache now constructs each image with `[[UIImage alloc] initWithData:data]`, giving the process-lifetime cache ownership under manual reference counting, and releases the temporary `NSData`. No action mapping, layout, renderer, data path, SDL/OSG/GL4ES behavior, or icon opacity was changed.
