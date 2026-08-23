# OpenMWiOS — Current State

- Project: OpenMWiOS
- Active branch: `codex/wo29-ios-crash-isolation` (canonical ControlPlane); active WO32 execution branch: `codex/wo32-targeted-renderer-boundary`
- Current engineering baseline commit: `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27`
- Control-plane issued baseline commit: `bbd7ce4fd5c82520c630f49fb768e0b1a284d940`
- Active work order: [WO-032 Amendment 2](../WorkOrders/WO-032.md)
- Ready work order: none
- Last completed work order: [WO-031](../WorkOrders/WO-031.md) — **ACCEPTED / PARTIAL ACCEPT; diagnostic localization only**
- Last reviewed work order: [WO-032](../WorkOrders/WO-032.md) — **PARTIAL ACCEPT / AMENDMENT REQUIRED; R1 smoke cause proven, correction unbuilt**
- Current objective: compile and device-qualify the unchanged R1 smoke/particle blend-state correction through one timeout-bounded replacement Fast build; do not infer or begin foliage/R2 correction
- Engineering execution status: **ACTIVE; WO-032 Amendment 2 start directive was relayed to the existing worker on 2026-08-23**
- Current accepted correction: WO29's non-ARC icon ownership fix plus WO30's practical on-device touch editor and reduced-opacity controls
- Last updated: 2026-08-23

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
- WO32's targeted diagnostic artifact proves that OSG direct core blend-state calls bypass GL4ES tracking for the representative chimney-smoke draw. A narrow correction exists but has not compiled or produced a device artifact, so the accepted runtime baseline is unchanged.

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

The original WO31 run stopped after its diagnostic candidate introduced a launch-time crash. The user-supplied IPS exactly matches the candidate Mach-O UUID and records a main-thread `EXC_BAD_ACCESS` in `openmw_ios_renderer_diag_record` while constructing the first later shader record. Direct source inspection proves that the non-ARC bridge persisted autoreleased path/session strings across the startup autorelease-pool boundary. Candidate `50aa047c3010be5380393a81c452bcfae206407d` is rejected; accepted engineering baseline `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27` is unchanged.

WO31 Amendment 1 repaired the ownership defect and its exact artifact reached Seyda Neen without the former crash. The supplied 7,028-byte JSONL is valid and contains 23 records: one iOS startup record and 22 OpenMW R1 records. It contains zero GL4ES records and zero R2 records. Sharing the file was correct and sufficient to prove partial operation plus diagnostic insufficiency, but it cannot localize the renderer defect because it lacks the intended/applied lower-renderer half.

The user also observed short-tap Menu failing while long-press editor entry still worked. No touch source changed. This remains an unclassified candidate regression and must be rechecked, but it does not authorize touch work or displace the user's renderer priority.

WO31 Amendment 2 proved the app/GL4ES bridge, identified defective assets and GL texture bindings, and established that OpenMW, OSG, and GL4ES agree on exterior fog receipt. Its broad budgets expired before representative exterior draw/program application. R1 is narrowed to the applied draw/program boundary after OSG binding; R2 is narrowed to exterior program consumption or later content/cull/sky/clear/depth presentation after correct GL4ES receipt. No renderer correction was attempted or accepted.

The user did not deliberately cast a fire spell during the WO31 device run. Visible blocky chimney smoke is the qualified particle reproduction and is sufficient for targeted R1 work. Cast-fire behavior remains optional.

The original WO32 run prepared target-gated late-session sampling but failed during regression validation before compilation. All ordered production patches applied; two test-only patch parsers mishandled whitespace-cleaned blank context lines. No IPA, device evidence, renderer correction, or new accepted runtime state resulted. The redundant evidence-triggered run was cancelled immediately without an artifact.

WO32 Amendment 1 repaired the two test-helper parsers and produced successful diagnostic run `32627872506`, artifact `OpenMW-iOS-fast-47`. The matching 317-record device JSONL captured foliage, chimney smoke, and an opaque control. It proves a split state-owner boundary for smoke/particles: pinned OSG calls native core `glEnable`/`glDisable`/`glBlendFunc` directly while GL4ES owns the converted program and draw, leaving the representative smoke draw with `blend=0` despite correct alpha factors, depth-write state, and shader alpha behavior.

Correction candidate `1625713b949ddb0cde5471feead75f29fedadfaa` routes only the relevant Apple manual-init OSG mode/blend calls through GL4ES. Its Fast run `32634038454` passed bootstrap and patch application but missed both dependency caches and was cancelled at the two-hour limit during dependency preparation. OpenMW compile/link, package, upload, and device validation were skipped; no artifact exists. The correction is not accepted and the runtime baseline remains `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27`.

Foliage is a distinct unresolved path: the captured `tx_bc_moss.dds` draw is already opaque before raster output. R2 is also unresolved: only one stable maximum-distance generation exists, so the white distance region and blue horizon boundary remain unlocalized. Neither may be inferred fixed by the smoke correction.

WO32 Amendment 2 is ACTIVE. It authorizes only a Fast job timeout change from 120 to 180 minutes, one replacement build containing the unchanged R1 correction, and exact-artifact smoke/particle device qualification. It prohibits any foliage, R2, touch, cache-design, dependency, or further renderer-source change.

Secondary/deferred boundaries: menu/options touch scrolling; WO30 Reset-opacity and all-control-affordance gaps; reduced render scale `0.58`; the transient red effect; and warning-flood cleanup except where narrowly necessary to collect bounded renderer evidence. WO32 prohibits touch-control changes.

These are observations or unresolved hypotheses, not established root causes. They must not be folded into the completed data-path correction.

## Data-path status

The permanent default-data-path correction is completed in WO27. The stable logical location is `Documents/OpenMW/Morrowind/Data Files`; the current sandbox prefix is obtained at runtime. Existing recognized legacy generated UUID entries are migrated narrowly, while unrelated user and mod paths remain preserved.

The accepted physical test did **not** record the post-install container UUID because the diagnostic transport was unavailable. Therefore it establishes automatic discovery without manual UUID input, but does not independently prove that SideStore changed the UUID in that exact install.

## Latest important evidence

- [READY WO32 Amendment 2](../WorkOrders/WO-032.md)
- [WO32 correction-timeout orchestrator review](../Evidence/WO-032/orchestrator-correction-timeout-review.md)
- [WO32 R1 partial-acceptance decision](../Decisions/DEC-011.md)
- [WO32 final worker report](../Evidence/WO-032/report.md)
- [WO32 replacement-diagnostic device capture](../Evidence/WO-032/device-capture-analysis.md)
- [WO32 evidence manifest](../Evidence/WO-032/manifest.md)
- [WO32 pre-build failure orchestrator review](../Evidence/WO-032/orchestrator-prebuild-failure-review.md)
- [Accepted partial WO31](../WorkOrders/WO-031.md)
- [WO31 execution report](../Evidence/WO-031/report.md)
- [WO31 Amendment 2 orchestrator review](../Evidence/WO-031/orchestrator-amendment2-review.md)
- [WO31 Amendment 2 diagnostic](../Evidence/WO-031/device-renderer-diagnostic-amendment2.jsonl)
- [WO31 user coverage clarification](../Evidence/WO-031/user-amendment2-coverage.md)
- [WO31 partial-acceptance and WO32 direction decision](../Decisions/DEC-010.md)
- [WO31 Amendment 1 orchestrator review](../Evidence/WO-031/orchestrator-amendment1-review.md)
- [WO31 supplied renderer diagnostic](../Evidence/WO-031/device-renderer-diagnostic-amendment1.jsonl)
- [WO31 diagnostic observability decision](../Decisions/DEC-009.md)
- [WO31 orchestrator crash review](../Evidence/WO-031/orchestrator-crash-review.md)
- [WO31 diagnostic-candidate rejection decision](../Decisions/DEC-008.md)
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
2. Read accepted `WorkOrders/WO-031.md`, READY `WorkOrders/WO-032.md` Amendment 2, DEC-010, DEC-011, and only their directly referenced evidence.
3. Read only the `Decisions/` and `Evidence/` records referenced by that work order.
4. Inspect current Git state and active/recent CI before changing anything.
5. Use the Google Docs ledger only when deeper historical context is required.

WO32 Amendment 2 is ACTIVE with the existing worker. The exact next action is to allow that execution to reach its natural completion, blocker, CI-wait, or device-evidence boundary. Do not resend the start directive, create another worker, or duplicate the authorized build.
