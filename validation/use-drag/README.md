# Touch Use / LuaPhysics adapter (staged)

Baseline: combined Parry/multitouch commit183ee337bf. No physics engine fork.
LuaPhysics source inspected at4f6b36bc8bf3dfc0be1471c4899195432134b161.

UI USE is Activate/A, not Lua's `Use` action (weapon attack, which LuaPhysics uses to throw).
A short gameplay USE tap emits A on release. A stationary or moving hold >=350ms
emits reserved controller Misc1 while held. Normal GUI A stays immediate.
Hold release, touch cancellation, menu/gameplay changes, editing, background and shutdown
release grab. A slow frame cannot turn a completed hold into a pickup.
Movement and separate look finger remain independently owned. No new visible button.

Install companion folder as separate mod, `content=OpenMWTouchPhysics.omwscripts`
after `content=LuaPhysicsEngine.omwscripts`. It adds Misc1 to registered
GrabPhysicsObject without replacing a user's existing Drag Object binding.
This app change must be paired with the companion and LuaPhysics: without them,
long USE is consumed without effect. Preserve original configs/saves before activation.
Do not map Misc1 to another game action in custom controller settings.

Native app and companion integration is staged, not device-tested. Verify in LiveContainer:
short tap picks up/opens once; long hold drags without pickup; release drops; Attack throws;
Parry, jump, movement and swipe remain independent; background/menu cannot leave a grab held.
No device modifications or build triggered by this patch alone.
