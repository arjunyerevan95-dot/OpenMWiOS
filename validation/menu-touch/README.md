# Native touch menu scrolling

Menu touches are now captured by the UIKit overlay after visible overlay controls.
A tap sends absolute mouse position then paired left-down/up **only on release**.
A quick drag over 8pt never sends mouse down: it locks its dominant axis and generates
precise wheel input while anchoring hover to the initial widget. Moving a finger
up or left scrolls content naturally. OpenMW's `ItemView::onMouseWheelMoved`
already translates wheel into horizontal inventory offset (120 * 0.3 = 36px).
Vertical MyGUI lists use the same wheel convention. No synthetic click is sent
for cancellation, GUI/game transitions, backgrounding, or a second simultaneous
menu finger. Existing Pause editor and visible inventory controls retain priority.
Coordinates scale from UIKit points to SDL logical window size before OpenMW's
existing drawable/UI-scale conversion. No profile/save/content changes.

Host test covers tap, drift, scrolling both axes and directions, axis lock,
retained widget focus, cancellation and second-finger rejection. It is executed
by the standard touch-contract CI script. Native build and actual iPhone list,
item selection, horizontal inventory, dialogue and menu tests remain required.
Hold stationary for at least 0.4 seconds before moving to use ordinary left-button
dragging for map panning, sliders, scrollbar thumbs and desktop-style item drag.
Drag motion carries SDL_BUTTON_LMASK, and release/cancellation/mode switch sends
mouse-up. A quick scroll stays a scroll even if the gesture later exceeds 0.4s. No kinetic inertia in this first
bounded change, to avoid unwanted list motion during selection.
