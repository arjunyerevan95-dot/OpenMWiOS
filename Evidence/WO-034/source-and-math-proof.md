# WO-034 source and geometric proof

## Exact source boundary

Pinned OpenMW source: `f4bec41444214a7903bebd178389ca22ca13f646` plus the ordered iOS patch stack through `0015-ios-renderer-diagnostics-targeted-boundaries.patch`.

`MWRender::RenderingManager::updateProjectionMatrix` builds a symmetric perspective projection from the vertical field of view, runtime output aspect, near plane, and user-selected view distance. It then gives terrain a radial coverage distance of:

```text
viewDistance / cos(verticalFov / 2)
```

`MWRender::RenderingManager::getWorldspaceChunkMgr` independently repeats that same aspect-unaware calculation when a terrain world is created.

`Terrain::distance` is Euclidean camera-to-AABB distance. `Terrain::DefaultLodCallback::isSufficientDetail` stops traversal for a non-active-grid node when that radial distance exceeds the configured terrain view distance. Therefore the terrain gate is a sphere while the camera's visible far boundary is a rectangle.

## Perspective derivation

Let:

- `D` be the camera far/view distance;
- `v` be the vertical field of view;
- `a` be the positive width/height aspect ratio; and
- `t = tan(v / 2)`.

At the camera-space far plane:

```text
z = D
halfHeight = D * t
halfWidth  = D * a * t
```

The Euclidean distances from the eye are:

```text
vertical edge   = D * sqrt(1 + t^2)
horizontal edge = D * sqrt(1 + (a*t)^2)
full corner     = D * sqrt(1 + t^2 + (a*t)^2)
```

The existing `1/cos(v/2)` multiplier equals `sqrt(1+t^2)`: it reaches only the vertical far-plane edge. It does not cover the horizontal edge when `a > 1`, and it never covers the full corner.

The full corner is the required general bound for the actual quadtree semantics. The cull test operates on arbitrary 3D terrain-node AABBs after the camera transform, not on a fixed ground-plane ray. A sufficiently small AABB intersecting a far corner can have its closest point arbitrarily close to that corner. Camera pitch can also rotate a far corner toward terrain. Thus neither the vertical edge nor the horizontal edge alone guarantees that every terrain AABB intersecting the view frustum survives the radial gate. The far corner is the exact maximum Euclidean distance within the symmetric perspective frustum.

This correction does not change `D`, the projection, fog, clear state, active-grid policy, or cell loading. It only makes the radial terrain coverage sphere enclose the existing visible frustum.

## Captured iPhone comparison

Accepted WO33 R2 projection evidence:

```text
D = 7168
v = 60 degrees
a = 2868 / 1320 = 2.17272727272727
t = 0.577350269189626
```

Computed bounds:

| Coverage | Multiplier | Distance |
|---|---:|---:|
| Existing vertical-only | 1.154700538 | 8276.893459 |
| Horizontal edge | 1.604238532 | 11499.181797 |
| Full corner | 1.704967624 | 12221.207932 |

The accepted runtime value `8276.89` matches the vertical-only formula exactly and undercovers the horizontal far edge by about `3222.29` units and the full far corner by about `3944.31` units.

## Required implementation contract

- Use runtime vertical FOV and runtime output aspect.
- Preserve the existing 140-degree FOV safety cap.
- Use the same helper for both `updateProjectionMatrix` and `getWorldspaceChunkMgr`.
- Keep camera far distance, fog parameters, projection, active grid, and renderer state unchanged.
- Do not hard-code any device dimensions or aspect ratio.

## Alternative classifications

- Active-grid insufficiency remains possible for content outside terrain paging, but it cannot explain why the terrain gate is mathematically smaller than the visible frustum.
- The OSG projection values match the runtime drawable and are not themselves divergent.
- Fog intent, OSG receipt, GL4ES receipt, and clear color agree in accepted evidence.
- Fog-colored clear/sky exposure is a downstream symptom expected when terrain traversal stops before the visible far boundary.
- Depth/clear ordering has no accepted evidence of divergence.

The exact source geometry therefore authorizes WO-034 Route A.
