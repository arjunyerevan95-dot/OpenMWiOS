# OpenMWiOS — Current State

- Project: OpenMWiOS
- Active branch: `codex/wo29-ios-crash-isolation`
- Current engineering baseline commit: `45c1d8c696fb328d977893b79efc78689a3f4d08`
- Control-plane baseline commit: `765deec93d0b7e4ff0ccebd24483f704ee925c0a`
- Active work order: none
- Ready work order: [WO-030](../WorkOrders/WO-030.md)
- Last completed work order: [WO-029](../WorkOrders/WO-029.md)
- Last reviewed work order: [WO-029](../WorkOrders/WO-029.md) — **ACCEPTED with explicit validation limits**
- Current objective: correct the exterior renderer defects and deliver persistent, user-customizable, substantially less opaque iOS touch controls under WO30
- Engineering execution status: **STOPPED; WO-030 is READY and awaits a separate explicit orchestrator start directive**
- Current accepted correction: `45c1d8c696fb328d977893b79efc78689a3f4d08` owns the process-lifetime touch icon cache under non-ARC and removes the proven WO28 launch/`New Game`/overlay crash mechanism
- Last updated: 2026-08-22

## Qualified state

The highest qualified runtime gate combines the completed WO26 and WO27 results with the accepted WO29 crash correction:

- OpenMW installs and launches on a physical iPhone.
- Morrowind, Tribunal, and Bloodmoon content loads.
- Full-screen landscape rendering, UI, audio, input, and scene transitions remain intact.
- The main menu, New Game, the prison-ship sequence, and Seyda Neen exterior traversal have been reached.
- Touch movement and look permit ship traversal and exterior access.
- WO27 resolves the default base-game path from the current iOS Documents directory at runtime. The accepted device launch required no manual `openmw.cfg` edit and no externally supplied container UUID/path.
- No native crash or jetsam was observed in the accepted WO27 device run.
- Thirteen reports from the rejected WO28 candidate match its executable UUID and converge at one dangling cached-`UIImage` fault in `OpenMWTouchOverlay drawRect:`.
- WO29 corrects that ownership defect without changing touch mappings, layout, renderer, data path, dependencies, cache architecture, or workflow behavior.
- The corrected artifact booted normally and supported controls, indoor play, Seyda Neen exterior traversal, HUD/overlay rendering, weapon/combat, and scene changes without a user-observed crash during the supplied session.

This is a qualified crash correction and sustained device pass, not a complete mobile-control qualification. The formal ten-launch, three-`New Game`, and per-control attempt counts were not recorded, and no independent post-test crash inventory was available. Those missing counts are not invented or used to broaden the accepted result.

## Versions and accepted candidate

- OpenMW: `f4bec41444214a7903bebd178389ca22ca13f646` (0.51.0)
- SDL: 2.32.10
- OSG: `01cc2b585c8456a4ff843066b7e1a8715558289f` (3.6.5)
- GL4ES: `c9895df34cd466c23bc60c2bd3db3d87e98fcbe7` (1.1.6)
- Deployment target: iOS 16.3
- Architecture: arm64
- Accepted Fast Development run: `32548876888`
- Accepted source commit: `45c1d8c696fb328d977893b79efc78689a3f4d08`
- Artifact: `OpenMW-iOS-fast-31` (ID `9470501854`)
- Executable SHA-256: `6FF52E861FF44D4C4449E1A82481EE7F52B515932A56279EB5C057F9E740F0C2`
- IPA SHA-256: `E295561EE9BF1F52A7337C6AACFE7777F530E9E394462F3C143DEB98E14BDD63`
- Mach-O UUID: `52739477-31F4-3693-9D6F-30366E3D640D`

See [WO29 evidence](../Evidence/WO-029/manifest.md) for the crash classification, correction, CI, artifact, and device references. WO27 remains the accepted data-path baseline carried forward by WO29.

## Current blockers and unresolved boundary

Primary engineering boundary: exterior renderer correctness. The accepted WO29 device session and later screenshots taken with view distance set to maximum show persistent foliage alpha/cutout failure, large white/blank distance regions, disconnected distant silhouettes, and a sharp blue horizon/cutoff band. Maximum view distance improved coverage somewhat but did not resolve the defects, so a low view-distance setting is not a complete explanation.

The exact renderer cause remains unproven. Foliage alpha handling and distant fog/culling/paging/clipping presentation must remain separate hypotheses until source/runtime evidence establishes convergence.

Current unresolved renderer boundary exposed by exterior traversal:

- foliage alpha/transparency is incorrect, producing opaque leaf cards;
- distant scenery contains missing/white regions and a horizontal band;
- water appearance improved after the user enabled OpenMW water shader effects, so the prior water concern is currently configuration-dependent rather than a proven renderer defect;
- distance fog appears absent at the configured draw boundary, leaving white/empty regions beyond rendered geometry; its relationship to the foliage-alpha defect is unknown;
- reduced render scale 0.58 still has menu corruption and is not qualified;
- `ColorMaski` warning activity remains noisy but was not proven to block rendering.
- a transient blocky red combat effect was captured once and absent in the next screenshot; it remains unclassified.

WO30 is the canonical READY order for the renderer boundary. It preserves foliage alpha/cutout and distance/fog/culling/paging/clipping as separate causal paths unless evidence establishes convergence.

WO30 also authorizes the requested touch UX work as an independently reviewable track: persistent on-device repositioning/resizing, movement-radius and opacity adjustment, reset behavior, and a nominal 20% default idle opacity. It does not authorize action remapping or replacement of the qualified touch foundation.

These are observations or unresolved hypotheses, not established root causes. They must not be folded into the completed data-path correction.

## Data-path status

The permanent default-data-path correction is completed in WO27. The stable logical location is `Documents/OpenMW/Morrowind/Data Files`; the current sandbox prefix is obtained at runtime. Existing recognized legacy generated UUID entries are migrated narrowly, while unrelated user and mod paths remain preserved.

The accepted physical test did **not** record the post-install container UUID because the diagnostic transport was unavailable. Therefore it establishes automatic discovery without manual UUID input, but does not independently prove that SideStore changed the UUID in that exact install.

## Latest important evidence

- [READY WO30](../WorkOrders/WO-030.md)
- [Accepted WO29](../WorkOrders/WO-029.md)
- [WO29 evidence manifest](../Evidence/WO-029/manifest.md)
- [WO29 execution report](../Evidence/WO-029/report.md)
- [Maximum-view-distance observations](../Evidence/WO-029/max-view-distance-observations.md)
- [Reviewed WO28](../WorkOrders/WO-028.md)
- [WO28 evidence manifest](../Evidence/WO-028/manifest.md)
- [WO28 execution completion record](../Evidence/WO-028/completion.md)
- [Canonical WO26 state](../WorkOrders/WO-026.md)
- [Canonical WO27 state](../WorkOrders/WO-027.md)
- [WO27 evidence manifest](../Evidence/WO-027/manifest.md)
- [Qualified renderer baseline decision](../Decisions/DEC-001.md)
- [Touch qualification decision](../Decisions/DEC-002.md)
- [Runtime data-path decision](../Decisions/DEC-003.md)
- [WO28 rejection and crash-path separation decision](../Decisions/DEC-004.md)
- [WO29 crash-correction decision](../Decisions/DEC-005.md)
- [Maximum view distance does not resolve exterior rendering decision](../Decisions/DEC-006.md)
- Living historical ledger: [OpenMW iOS — Engineering Handoff Ledger](https://docs.google.com/document/d/1TOyBHA1tSKBIqoU_XFSIaTMbdCBAcNVsaczy29N_b18/edit)

## Future orchestrator/worker recovery

1. Read `Documentation/CURRENT_STATE.md`.
2. Read the accepted `WorkOrders/WO-029.md`, DEC-005, DEC-006, and their directly referenced evidence; read WO28/WO27 only as needed.
3. Read only the `Decisions/` and `Evidence/` records referenced by that work order.
4. Inspect current Git state and active/recent CI before changing anything.
5. Use the Google Docs ledger only when deeper historical context is required.

WO30 engineering changes are not yet authorized to begin. Execution requires the separate explicit orchestrator start directive; at that point WO30 transitions from READY to ACTIVE.
