# WO-032 bounded sampling model

## Purpose

WO-031 proved that broad startup-biased budgets expire before the defective exterior draw boundaries. WO-032 therefore uses late target gates rather than increasing log volume.

## R1 gate

Targets are armed only after OpenMW loads and OSG binds a texture whose normalized identity is one of:

- target 1: foliage/hanging-moss (`moss`, `fern`, `leaf`, `flora`, or `tree`) in the existing alpha-card category;
- target 2: chimney smoke (`smoke`) in the existing particle category;
- target 3: an opaque control in the existing `_land_default` / `tx_wood` / `tx_stone` control category.

The app bridge maps image hash to GL texture name. GL4ES records at most four applied draws per target, and only after the current fog values match an armed OpenMW exterior generation. Unregistered and broad `category=-1` uploads cannot consume the targeted draw budget.

Each target emits an explicit `summary` miss marker when armed (`status=miss-until-first-applied-draw`) and a hit marker on its first applied draw. This makes both a hit and a bounded absence reviewable.

## R2 gate

OpenMW arms a generation only when exterior fog start/end/color or selected view distance changes. GL4ES records a program only when:

1. mode, start, end, and color have all been received;
2. the applied values match the currently armed exterior generation; and
3. that program/generation pair has not already been recorded.

The device plan requires two materially different selected view distances. OpenMW additionally records the corresponding projection, terrain-cull distance, active grid/cell activity, camera clear state, clear depth, and sky-blending state.

## Bounds

- File ceiling remains 256 KiB.
- R1 target draws: at most four records per target.
- R2 applied programs: at most 64 unique program/generation pairs.
- Arm/projection/clear records are state-change-driven, not per-frame.
- Cell/grid records use the existing bounded family budget.
- Diagnostics are observational and contain no renderer-state mutation.

## Local proof

`validation/test_wo32_targeted_renderer_diagnostics.py` statically checks the gates and includes a C fixture for CI/platform environments with a C compiler. The fixture proves that pre-arm and untargeted draws do not record, each named target can record, the per-target cap holds, and two exterior generations produce distinct applied-program records.
