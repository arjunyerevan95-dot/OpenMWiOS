# WO-030 R2 — distance/fog/horizon investigation

## Symptom baseline

At multiple user-selected view distances, WO29 device screenshots retain large white/blank exterior regions, disconnected silhouettes, and a sharp blue horizontal band. Increasing view distance changes coverage but does not remove the defect (DEC-006).

## Source path verified before runtime diagnostics

1. OpenMW `FogManager` computes fog start, end, and color from weather/view-distance state.
2. `RenderingManager` passes those values to `StateUpdater` and updates the scene fog state.
3. The pinned OSG build has fixed-function support enabled; `osg::Fog::apply` therefore reaches the GL fog entry points. The hypothesis that fog application was compiled out is eliminated.
4. Work Order 14's qualified routing sends those GL entry points through GL4ES.
5. GL4ES stores the received fog state and its fixed-program uniform path uploads the built-in fog start/end/color values consumed by converted compatibility shaders.

The intended end-to-end path exists in source. Actual device values are required to locate the first divergence; a compile-time fog omission is not the cause.

## Diagnostic contract

Candidate `d1d5182b344f77aa2cdee1169c30d3e2ee0dd955` records, with fixed budgets:

- OpenMW's intended start/end/far/color values (up to 16 changed samples);
- GL4ES fog entry-point values (up to 32 relevant calls);
- GL4ES built-in fog uniform start/end/scale/color values (up to 24 program realizations).

No fog enable, distance setting, camera, clear color, GL state, shader logic, or presentation state is changed.

## Current causal status

**UNPROVEN after the diagnostic device run.** The user-shared log records OpenMW's intended exterior fog as start `2007.04`, end/far `7168`, and color `0.960784,0.921569,0.878431`. It does not contain the corresponding GL4ES received-state or built-in-uniform records because those probes wrote to `stderr`. The first divergence therefore remains unlocalized. Terrain paging/culling remains a separate candidate until correlated with the same viewpoint and view-distance settings. See [shared-log-analysis.md](shared-log-analysis.md).

## Device observation and offline-log boundary

The user reported no visible change to the foliage sheets, white distance regions, or blue horizon while exercising the diagnostic candidate. This is expected from an observation-only build and does not select a correction.

The OpenMW intended-fog samples use `Log(Debug::Info)` and should be available in `Documents/OpenMW/openmw.log` for user sharing without usbmux. The received GL4ES fog calls and built-in fog-uniform samples were emitted to `stderr`; they are not currently mirrored into an app-owned file. Without those GL4ES-side records, the first state divergence remains unlocalized.
