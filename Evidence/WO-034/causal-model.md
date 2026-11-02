# WO-034 causal model

## Source-proven candidate chain

```text
runtime perspective uses vertical FOV + wide physical aspect
    -> visible far plane extends horizontally and vertically
terrain traversal uses a radial camera-to-AABB distance gate
    -> radial coverage must enclose the far-frustum corners
existing multiplier encloses only the vertical far-plane edge
    -> wide-frustum terrain nodes can be stopped while still visible
fog-colored clear/sky remains exposed where terrain coverage ends
    -> large blank regions and a sharp horizon/cutoff become visible
```

## Issue classification before device correction test

| Candidate | Classification | Evidence |
|---|---|---|
| Aspect-unaware radial terrain coverage | Proven source deficiency and primary candidate | Exact projection and quadtree distance math; captured runtime radius equals deficient formula |
| Active-grid/cell coverage | Independent/unproven | Loaded cells and active grid are recorded, but no source/runtime proof makes them the first invalid boundary |
| OSG projection mismatch | Falsified for captured dimensions | OSG projection uses the accepted `2868x1320`, aspect `2.17272727`, and 60-degree vertical FOV |
| Fog program consumption | Not the first boundary | OpenMW, OSG, and GL4ES fog values agree in accepted R2 evidence |
| Sky/clear exposure | Dependent symptom | Clear color equals fog color and is visible where geometry is absent |
| Depth/clear ordering | Unproven/non-primary | No accepted evidence of divergent ordering or state |

## Falsifiable device prediction

With camera far distance and fog unchanged, the corrected terrain radius should materially fill the prior terrain gaps in matching maximum-view-distance views. If the terrain gaps close but a distinct blue band remains, the terrain correction is a valid partial result and the band is a separate boundary. If the scene is unchanged despite the corrected radius reaching the native product, this model is insufficient and WO-034 must stop without widening scope.

## Device falsification result

The exact correction reached a successfully built and installed production IPA, but the maximum-view-distance device comparison showed no material change in:

- the fog-colored/white terrain gaps;
- the sharp blue cutoff band; or
- the pre-existing pure-black distant silhouettes that the user had included in the original "distance weirdness" report.

Therefore the source-level undercoverage calculation was real, but it was not the cause of the observed exterior presentation defects in this test. The downstream steps in the proposed chain are not established. WO34 stops without selecting or modifying another subsystem.
