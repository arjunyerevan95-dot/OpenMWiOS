# OpenMWiOS — Current State

- Project: OpenMWiOS
- Active branch: `codex/wo29-ios-crash-isolation` (canonical ControlPlane); planned WO31 execution branch: `codex/wo31-exterior-renderer-correction`
- Current engineering baseline commit: `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27`
- Control-plane issued baseline commit: `dfe9e1e875c7020658aa59d22121a7cc0061ac69`
- Active work order: none
- Ready work order: [WO-031](../WorkOrders/WO-031.md)
- Last completed work order: [WO-030](../WorkOrders/WO-030.md) — **ACCEPTED / PARTIAL ACCEPT**
- Last reviewed work order: [WO-030](../WorkOrders/WO-030.md) — **touch baseline accepted with limits; renderer unresolved**
- Current objective: correct the exterior foliage/particle alpha defects and distance/fog/horizon defects without mixing in touch UX work
- Engineering execution status: **STOPPED at READY; WO-031 has not received a start directive**
- Current accepted correction: WO29's non-ARC icon ownership fix plus WO30's practical on-device touch editor and reduced-opacity controls
- Last updated: 2026-08-22

## Qualified state

The highest qualified runtime gate combines WO26/WO27, the accepted WO29 crash correction, and the qualified WO30 touch baseline:

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
- WO30 adds a practical on-device touch editor entered by a 0.75-second Menu long-press, movable/resizable fixed controls, movement-radius adjustment, live global opacity controls, and versioned safe-area-relative profile storage.
- The WO30 final candidate uses nominal `0.20` idle opacity and the device-observed plus/minus controls visibly change opacity.
- The user considers the touch result practically satisfactory apart from menu/options scrolling.
- WO30 made no renderer correction; the exterior defects remain visible and causally unresolved.

This remains a qualified runtime and touch baseline, not complete mobile-control qualification. WO30 did not independently verify force-quit/relaunch persistence, a post-test crash inventory, or the full action-control matrix. Reset currently preserves opacity instead of restoring nominal `0.20`, and only the selected fixed control shows the explicit resize ring. These limits are recorded without scheduling touch cleanup inside the renderer order.

## Versions and accepted candidate

- OpenMW: `f4bec41444214a7903bebd178389ca22ca13f646` (0.51.0)
- SDL: 2.32.10
- OSG: `01cc2b585c8456a4ff843066b7e1a8715558289f` (3.6.5)
- GL4ES: `c9895df34cd466c23bc60c2bd3db3d87e98fcbe7` (1.1.6)
- Deployment target: iOS 16.3
- Architecture: arm64
- Accepted Fast Development run: `32573611821`
- Accepted source commit: `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27`
- Artifact: `OpenMW-iOS-fast-34` (ID `9476386162`)
- Executable SHA-256: `5ABD1BC40F5FDFF67747E329FE56D2593D2FCDCE9847139BBFF3C97749A85D66`
- IPA SHA-256: `7ADADF613AC36DED1F63B2848B6622654231AF8243643B0791CC682536C426E6`
- Mach-O UUID: `0BA296A8-24AC-364C-A804-F4601A399F99`

See [WO30 evidence](../Evidence/WO-030/manifest.md) for the current touch candidate, CI, artifact, and device limits. [WO29 evidence](../Evidence/WO-029/manifest.md) remains authoritative for the crash correction, and WO27 remains the accepted data-path baseline.

## Current blockers and unresolved boundary

Primary engineering boundary: exterior renderer correctness. The accepted WO29 device session and later screenshots taken with view distance set to maximum show persistent foliage alpha/cutout failure, large white/blank distance regions, disconnected distant silhouettes, and a sharp blue horizon/cutoff band. Maximum view distance improved coverage somewhat but did not resolve the defects, so a low view-distance setting is not a complete explanation.

WO30 did not localize the earliest invalid renderer boundary. Its bounded OpenMW-side probes recorded intended fog state, but representative foliage state and GL4ES received-state records were not available in the user-shareable log. Foliage/particle alpha handling and distant fog/culling/paging/clipping presentation remain separate hypotheses until runtime evidence establishes convergence.

Current unresolved renderer boundary exposed by exterior traversal:

- foliage alpha/transparency is incorrect, producing opaque leaf cards;
- distant scenery contains missing/white regions and a horizontal band;
- water appearance improved after the user enabled OpenMW water shader effects, so the prior water concern is currently configuration-dependent rather than a proven renderer defect;
- distance fog appears absent at the configured draw boundary, leaving white/empty regions beyond rendered geometry; its relationship to the foliage-alpha defect is unknown;
- reduced render scale 0.58 still has menu corruption and is not qualified;
- `ColorMaski` warning activity remains noisy but was not proven to block rendering.
- a transient blocky red combat effect was captured once and absent in the next screenshot; it remains unclassified.

WO31 is the canonical READY renderer-only order. It first establishes a bounded app-owned GL4ES/OpenMW diagnostic channel, then conditionally corrects the earliest proven R1 and/or R2 invalid boundary. It preserves the paths as separate unless evidence establishes convergence.

Secondary/deferred boundaries: menu/options touch scrolling; WO30 Reset-opacity and all-control-affordance gaps; reduced render scale `0.58`; the transient red effect; and warning-flood cleanup except where narrowly necessary to collect bounded renderer evidence. WO31 prohibits touch-control changes.

These are observations or unresolved hypotheses, not established root causes. They must not be folded into the completed data-path correction.

## Data-path status

The permanent default-data-path correction is completed in WO27. The stable logical location is `Documents/OpenMW/Morrowind/Data Files`; the current sandbox prefix is obtained at runtime. Existing recognized legacy generated UUID entries are migrated narrowly, while unrelated user and mod paths remain preserved.

The accepted physical test did **not** record the post-install container UUID because the diagnostic transport was unavailable. Therefore it establishes automatic discovery without manual UUID input, but does not independently prove that SideStore changed the UUID in that exact install.

## Latest important evidence

- [READY WO31](../WorkOrders/WO-031.md)
- [Accepted WO30](../WorkOrders/WO-030.md)
- [WO30 evidence manifest](../Evidence/WO-030/manifest.md)
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
- [WO30 qualified touch acceptance and unresolved renderer decision](../Decisions/DEC-007.md)
- Living historical ledger: [OpenMW iOS — Engineering Handoff Ledger](https://docs.google.com/document/d/1TOyBHA1tSKBIqoU_XFSIaTMbdCBAcNVsaczy29N_b18/edit)

## Future orchestrator/worker recovery

1. Read `Documentation/CURRENT_STATE.md`.
2. Read accepted `WorkOrders/WO-030.md`, READY `WorkOrders/WO-031.md`, DEC-006, DEC-007, and only their directly referenced evidence.
3. Read only the `Decisions/` and `Evidence/` records referenced by that work order.
4. Inspect current Git state and active/recent CI before changing anything.
5. Use the Google Docs ledger only when deeper historical context is required.

WO31 is READY and has not started. Do not infer ACTIVE from file access. Execution requires the existing worker to receive a separate explicit orchestrator start directive.
