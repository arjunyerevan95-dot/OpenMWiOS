Built from ca361f758df7c396f89fb0eebcfab92eba90d040 (delivered pinch editor).

Menu touches travel in the SDL queue to MouseManager. Only the engine thread reads MyGUI:
it uses the actual mouse-focus widget after MyGUI clipping, modal and overlapping-window
filtering. Exact map/marker event receivers opt into direct dragging. Other menu widgets
retain deferred taps, natural dominant-axis scrolling and the existing hold-to-drag path.
Pans release capture without a click, so a pan cannot add/edit a marker. Ordinary taps
still use MyGUI press/release and its double-click detection. Mode/loading generations,
geometry changes, widget removal and cancellation discard the active gesture.

HUD hit targets are normalized value snapshots of the visible named stats, equipped-weapon
and MouseEmulationCursor widgets, computed on the engine thread. UIKit never reads widgets.
Stats tap opens Journal; a stationary one-second hold pulses Wait and haptic feedback.
Weapon tap pulses Ready Weapon; its hold pulses Ready Magic and haptic feedback. The native
mouse widget taps Inventory. Other saved overlay controls win overlaps. Redundant overlay
icons are hidden while replacement HUD targets exist; fallback controls remain when a
widget is hidden. The overlay Ready Magic icon is replaced by holding Ready Weapon.
All editor controls and the original saved-profile format/coordinates remain available.

Run validation/current-frame/run_menu_tests.py. It exercises production MenuInput through
a small MyGUI seam, the menu recognizer and HUD tap/hold/ownership models. It is not a
phone UI test. No renderer/performance or unrelated native regression suite is run.

Phone acceptance: local/world map quick pan on background/door/custom/global markers;
tap/double-tap add/edit note; list and horizontal inventory natural scrolling; release,
cancellation/backgrounding and menu/modal transitions; HUD taps, one-second holds and
exactly one haptic; custom overlay overlaps and edit/pinch/save/cancel. Confirm the user's
lower-right mouse icon is the native MouseEmulationCursor widget (source default location
is dynamic); if it is a mod-provided different element, a screenshot plus widget identity
is needed before binding it. The fallback Inventory control stays available in that case.
