# Weapon-ready right-side Parry gesture

User-authorized replacement of the standalone Parry button. The old 13-control
profile slot stays serializable but is not drawn or hit-tested, including editor.
No data/profile reset. Existing Attack, held-Attack drag, jump and Use/hold-Use
buttons retain independent ownership.

Only empty right-side Look touches are eligible. Engine DrawState::Weapon is
sampled every engine input update into an atomic native readiness flag; this is
exactly the state exposed by Actor.getStance to N'Garde. Sheathed and Spell states
have ordinary look. N'Garde independently gates guard on Weapon and lowers on
stance change. Existing NGardeIOS DPadDown bridge remains compatible.

A short tap sends a 120ms guard pulse. A stationary 90ms hold guards until release.
Movement of 8 UIKit points selects Look, releasing guard if already held; the
first swipe delta includes all accumulated motion so none is lost. This small
arbitration delay is intentional to avoid parry on every swipe. A very slow swipe
can briefly begin guarding before crossing slop; tune only after phone testing.
No gesture uses the Attack or Activate actions. Swipe on Attack stays immediate.

Cancellation, background, editor, GUI transitions, sheathing/casting release guard.
C++ model exercises taps, holds, swipe arbitration, cancellation and weapon loss.
Device timing, actual combat and gesture feel remain unverified until IPA testing.

## Startup regression guard
The first gesture build queried World::getPlayerPtr unconditionally from
InputManager::update. LoadingScreen::draw pumps update(0,true,true) while
Morrowind.esm is loading, before World::setupPlayer. getPlayerPtr dereferences
mPlayer, so checking Ptr::isEmpty afterward cannot protect startup.
The corrected path queries the player only when controls/events are enabled,
State_Running is set, and no GUI is active. Executable tests verify the callback
is never touched for loading, initial menu, disabled events or modal screens.
Phone log599b5430 stopped at Morrowind.esm loading; runtime retest still required.
