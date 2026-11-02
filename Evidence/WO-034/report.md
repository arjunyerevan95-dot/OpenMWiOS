# WO-034 execution report

## Status

- Outcome: completed as a controlled falsification; the Route A source correction built and ran, but produced no material device-visible change.
- Stop condition: **C — aspect/terrain hypothesis falsified**. The one-build budget is also exhausted; no follow-on change is authorized.
- Execution branch: `codex/wo34-distance-horizon-coverage`.
- Accepted engineering baseline: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`.
- Evidence execution base: `49f5f0bd80e83ef87eaebd3f69c07072796738aa`.
- Correction commit: `398a91759b1b327b464cf81e41320b8e5f312c9b`.

## Proven boundary

OpenMW's projection exposes a rectangular far plane, while terrain traversal uses a radial camera-to-AABB distance gate. The previous multiplier `1/cos(verticalFov/2)` enclosed only the far plane's vertical edge and ignored both aspect and the full corner.

For the accepted `7168`, 60-degree, `2868x1320` projection:

- previous terrain radius: `8276.893459`;
- required horizontal-edge radius: `11499.181797`;
- required full-frustum-corner radius: `12221.207932`.

The full corner is the general bound because terrain culling operates on arbitrary 3D node AABBs after camera transformation. See [source-and-math-proof.md](source-and-math-proof.md).

## Correction

`0016-ios-cover-perspective-frustum-terrain.patch` introduces one shared calculation:

```text
viewDistance * sqrt(1 + tan(verticalFov/2)^2 * (1 + aspect^2))
```

It uses runtime aspect and effective vertical FOV, retains the existing 140-degree cap, and is called by both the existing-world projection update and new-world initialization paths. It changes only terrain coverage; camera/fog/projection/active-grid/renderer state is unchanged.

## Validation

- Five focused regressions passed for portrait, square, ordinary landscape, captured 2.1727 landscape, exact corner geometry, monotonicity, finiteness, FOV cap, both call paths, and prohibited-state absence.
- Ordered OpenMW, OSG, and GL4ES patches reconstructed successfully from pristine pinned inputs with production Git patch parsing.
- Full local Python discovery had no WO34 failure; two unrelated Windows-host execution errors remain for direct `.sh` invocation.
- CI source bootstrap, aggregate validation, production compilation/link, bundle/resource validation, packaging, and artifact upload passed in Fast run `32854124142`.
- Run head: `398a91759b1b327b464cf81e41320b8e5f312c9b`; result `success`; total job duration approximately `83m16s`.
- IPA SHA-256: `EE9631158A008A2304A3CA766F2DDD9BFBDA2DD9ED6A9775297DE9FC3DEDB043`.
- Executable SHA-256: `CA6F0BDDA065C64E933B8912474C83ADD97E9532481EF4661A8382BE9AE79AC4`.
- Mach-O UUID: `55DF5E1E-3ED9-399F-A083-A191DCD52B3B`.

## Device result

The user installed and tested the exact WO34 IPA with maximum view distance and supplied seven exterior screenshots.

- Large fog-colored/white terrain gaps: unchanged.
- Sharp blue horizon/cutoff band: unchanged.
- Pure-black distant silhouettes: unchanged. The user clarified that these silhouettes were always present and were part of the original reported "weirdness in the distance," not a new regression.
- Nearby terrain, buildings, water, sky, HUD, touch overlay, and corrected foliage remain visibly present.
- Crash/jetsam: none reported during the captured exterior session.
- Smoke/spell effects: not specifically requalified in this capture.

The exact correction therefore reached production semantics but failed its mandatory visible prediction. See [device-capture.md](device-capture.md).

## Strongest causal conclusion

The old terrain-radius formula is mathematically aspect-blind and does not enclose the full wide perspective frustum. Correcting that source deficiency to the exact full-corner bound did **not**, however, materially change any of the reported exterior distance defects on the physical device. The aspect/terrain-radius model is therefore insufficient as the cause of the white gaps, blue band, or distant black silhouettes.

No alternative renderer subsystem was changed or promoted to a root cause. Further work requires orchestrator review and a separately authorized bounded investigation.

## Scope and budgets

- One Fast Development run dispatched and completed: `32854124142`.
- Full Qualification did not run.
- No second build will be launched.
- Canonical `Documentation/CURRENT_STATE.md`, `WorkOrders/`, and `Decisions/` were not modified.
