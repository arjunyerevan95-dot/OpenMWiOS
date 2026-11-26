Deckwind is vendored from modding-openmw/deckwind at
ca1c6f19bf292f38393b2ef78dd9334578694f95 under MIT No Attribution.
The upstream license is in Deckwind-LICENSE.txt.

The port uses Deckwind's original Lua menus and its inventory, magic, barter,
and container logic. The iOS changes add touch navigation and constrain item
counts to the viewport. Icon references use resources already available in
OpenMW or the player's installed game. Deckwind's paper maps and third-party
icon collection are excluded.

Enable Deckwind in Settings > Scripts and restart OpenMW. Disable it there
and restart to return to the stock menus. The bundled manifest remains
registered either way so the content list stays the same across the toggle.
