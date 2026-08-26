# WO-037 Source and Attribution Model

## Directly verified seams

| Layer | Pinned boundary | Evidence available |
|---|---|---|
| OpenMW | exterior fog arm and compatibility fog shader | fog start/end/color/view distance; shader source indicates fog and sky sampling |
| OSG | `osgUtil::RenderLeaf::render` | drawable, nearest parent, camera/order, render bin, object bounds, model-view/projection, eye depth |
| GL4ES | `glDrawElementsCommon` immediately around the native draw | cross-layer draw ID, realized program/FBO/viewport/textures and relevant fixed-function compatibility state; center color before/after |
| SDL/UIKit presentation | immediately after `gl4es_pre_swap` | native presented framebuffer/viewport and center RGBA |

## Correlation model

1. The OSG render leaf projects the drawable bounding box into NDC.
2. Only a bounding box spanning target NDC `(0,0)` becomes a candidate.
3. A thread-local draw ID survives the immediate OSG drawable call into GL4ES.
4. GL4ES reads one center pixel immediately before and after that direct native draw.
5. A changed center pixel identifies a draw that actually affected the sampled target; unchanged candidates remain non-winning candidates.
6. Native presentation reads one center pixel after the existing pre-swap mapping and emits the bounded classification summary.

Render-list replay does not carry the OSG thread-local ID and is deliberately classified as unattributed rather than guessed.

## Possible classifications

- `drawn-pixel-candidate`: one or more correlated direct draws changed the sampled center pixel.
- `coverage-composition-candidate-no-osg-center-coverage`: no OSG projected candidate covered the center before presentation.
- `ambiguous-candidates-no-color-change`: projected candidates existed, but none changed the sampled center.

These labels are diagnostic candidates, not final durable conclusions. Bounding-box coverage is conservative; only the color-changing draw correlation can identify a direct winner. GLES2 depth readback and sky-RTT color readback are explicitly reported as unavailable/not observed rather than fabricated. Existing bounded records retain the scene fog/clear evidence needed for comparison.

## Safety boundary

The diagnostic performs no GL state mutation. It does not enable/disable fog, blending, alpha, depth, cull, textures, programs, draws, paging, terrain, or sky behavior. It reads exactly one RGBA pixel per candidate before and after the direct draw and one RGBA pixel after pre-swap presentation.
