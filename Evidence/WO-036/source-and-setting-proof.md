# WO-036 Source and Setting Proof

## Isolation

- Execution branch was created directly from accepted engineering baseline `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`.
- Accepted WO33 blend-cache reconciliation is present in `ios/patches/osg-route-gl-entry-points-through-gl4es.patch` and its deterministic validation.
- The rejected WO34 file `patches/openmw/0016-ios-cover-perspective-frustum-terrain.patch` is absent.
- The accepted ordered OpenMW patch stack currently ends at `0015-ios-renderer-diagnostics-targeted-boundaries.patch`.
- Pinned OpenMW checkout reports revision `f4bec41444214a7903bebd178389ca22ca13f646`.

## Pinned source behavior

Codebase Memory navigation followed by direct source inspection established:

1. `RenderingManager::getWorldspaceChunkMgr` reads `Settings::terrain().mDistantTerrain`.
2. When distant terrain or groundcover is enabled it constructs `Terrain::QuadTreeWorld`.
3. In that route, the default-true `mObjectPaging` setting constructs `ObjectPaging` and attaches it to the quadtree.
4. Otherwise it constructs `Terrain::TerrainGrid`, which is the loaded-cell terrain route.
5. `RenderingManager::updateProjectionMatrix` uses the selected view distance for camera projection, shared far uniform, screen resolution, and terrain view distance.
6. `files/settings-default.cfg` defines `viewing distance = 7168.0`, `distant terrain = false`, and `object paging = true`.
7. `SettingsWindow` hides `RenderingDistanceSlider` when distant terrain is enabled and hides `LargeRenderingDistanceSlider` when it is disabled. The layout defines maxima of 7168 and 81920 respectively.

## Preserved configuration identity

The previously supplied pre-WO35 `settings.cfg` remains available only as historical evidence:

- Bytes: 724
- SHA-256: `EE80D8B9EFD9076070EFDF26902D4D5B881A0B54FE47626CE5C79DC4703743BA`
- `[Camera] viewing distance = 7168`
- no `[Terrain]` section
- no `[Fog]` section

The device later retained explicit `[Fog] sky blending = true` and `sky blending start = 0.8` by user choice. WO-036 therefore requires a fresh device copy before constructing Arm B; the historical 724-byte file is not silently treated as current device state.
