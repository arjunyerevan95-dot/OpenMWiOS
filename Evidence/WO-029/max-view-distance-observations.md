# WO-029 Additional Maximum-View-Distance Observations

## Context

During orchestrator review on 2026-08-22, the user reported setting OpenMW view distance to maximum before capturing three additional Seyda Neen exterior screenshots. The user observed some improvement but described distant rendering as still severely abnormal.

This is renderer evidence discovered during WO29 validation. It is not evidence against the accepted touch-icon crash correction and does not authorize graphics work under WO29.

Attachment directory, external to Git:

`C:\Users\arjun\.codex\codex-remote-attachments\01a02593-1ac3-76f1-9978-0a877bdc0484\B606150E-AFC5-4AFF-8B6F-1CB69CA21423`

| Screenshot | Dimensions | SHA-256 | Conservative observation |
|---|---:|---|---|
| `1-Photo-1.jpg` | `1280x589` | `29371C240396B3B5B00E17C088E1F1EF36B560FF2ED5E2D055A03B341950156D` | Dense foliage planes render as dark/opaque cards; broad white distance area and a sharp blue horizontal band remain behind nearby terrain and trees. |
| `2-Photo-2.jpg` | `1280x589` | `318399925B06F643306736F48111F59C142D5BCBE2BF1DACA58B4785E043E4C8` | Near terrain, buildings, and water render, while foliage cards, disconnected silhouettes, a large white background region, and a blue cutoff band remain. |
| `3-Photo-3.jpg` | `1280x589` | `CFE9F270B6FB319DA6130C8DAC4F1D44F07383BED2E50EE90D83B6CD630DBC0B` | Opaque foliage/moss cards persist around otherwise rendered near terrain; distant white gaps and a blue sliver/cutoff remain visible. |

## Evidence-backed finding

- Maximum view distance improves scene coverage somewhat but does not resolve the exterior defects.
- A low view-distance setting is therefore not a complete explanation.
- Foliage alpha/cutout presentation and distant scene/fog/horizon presentation may be distinct defects.
- The screenshots show output symptoms only. They do not identify the responsible OpenMW, OSG, GL4ES, shader, culling/paging, clipping, clear-color, or configuration boundary.
- The overlay icons remain visually dominant, consistent with previously recorded UX feedback; no UX change is authorized here.

## Deferred boundary

Future renderer work should separately trace:

1. foliage alpha test/blend/cutout state and texture-alpha propagation;
2. distance fog enablement and parameters;
3. scene paging/culling and far-plane behavior;
4. the sharp blue horizon/cutoff band and white/blank background regions.

Do not merge these paths until direct source/runtime evidence shows convergence.
