# OpenMWiOS — Current State

- Project: OpenMWiOS
- Canonical ControlPlane branch: `codex/wo29-ios-crash-isolation`
- Accepted engineering baseline commit: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`
- Active work order: none
- Ready work order: [WO-037 Amendment 2](../WorkOrders/WO-037.md)
- Last completed work order: [WO-036](../WorkOrders/WO-036.md) — **ACCEPTED / CONTROLLED FALSIFICATION; NO PRODUCT CHANGE**
- Last durable decision: [DEC-016](../Decisions/DEC-016.md)
- Current objective: correlate photographed distant defects to exact OSG draw coverage, GL4ES program/state, target-pixel depth/color, sky RTT sampling, and scene clear behavior before correction
- Engineering execution status: **STOPPED; WO-037 Amendment 2 is READY and awaits an explicit orchestrator start directive**
- Last updated: 2026-08-29

## Highest qualified runtime milestone

The qualified OpenMWiOS runtime now combines the WO26/WO27 bootstrap and data-path work, WO29 crash correction, WO30 touch editor, and WO33 blend-state correction:

- OpenMW installs and launches on a physical iPhone.
- Morrowind, Tribunal, and Bloodmoon content loads.
- Full-screen landscape presentation, UI, audio, input, scene transitions, and exterior traversal operate.
- The main menu, New Game, prison-ship sequence, and Seyda Neen exterior have been reached.
- WO27 resolves the default data path from the live iOS Documents directory without manual container-UUID edits.
- WO29 fixed the cached-`UIImage` ownership crash; no comparable crash was reported in the accepted later device sessions.
- WO30 provides a 0.75-second Menu long-press touch editor, movable/resizable controls, movement-radius adjustment, global opacity controls, and versioned safe-area-relative storage.
- WO33 fixes the proven OSG/GL4ES blend-cache desynchronization. Representative smoke draws changed from `blend=0` to `blend=1` while their factors, depth behavior, and shader alpha behavior remained intact.
- Device evidence shows chimney smoke and the sampled spell effect blending correctly. Foliage alpha/cutout presentation also materially improved.
- HUD, overlay, native landscape presentation, exterior traversal, and gameplay remained intact, with no reported crash in the WO33 correction session.

This is a qualified Fast Development runtime baseline, not a Full Qualification result.

WO34, WO35, and WO36 did not advance this milestone. WO34's wider terrain-radius candidate produced no material visual change. WO35 proved sky blending active but left the blue/white cutoff materially present. WO36 proved distant terrain/object paging and `16384` view distance only move the same boundary farther away. None made an accepted product change. The accepted source/artifact baseline remains WO33 commit `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`.

## Accepted candidate

- OpenMW: `f4bec41444214a7903bebd178389ca22ca13f646` (0.51.0)
- SDL: 2.32.10 / `5d249570393f7a37e037abf22cd6012a4cc56a71`
- OSG: `01cc2b585c8456a4ff843066b7e1a8715558289f` (3.6.5)
- GL4ES: `c9895df34cd466c23bc60c2bd3db3d87e98fcbe7` (1.1.6)
- MyGUI: `dae9ac4be5a09e672bec509b1a8552b107c40214`
- Deployment target: iOS 16.3
- Architecture: arm64
- Accepted source commit: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`
- Accepted Fast Development run: `32771773194`
- Artifact: `OpenMW-iOS-fast-55` (ID `9538962155`)
- Artifact digest: `sha256:1af36e00a09f9056bf1bb63eaf0c4c09a35e6ed14155009425913717f9840be7`
- IPA SHA-256: `34EB8106C60138F30DA8B59083CA026FDA013F68870DDC658C1584B6E939AC4E`
- Executable SHA-256: `C759B9D09DF6A2CFFE7657839BD3DB25999A399743E811A7846A406A5826874C`
- Mach-O UUID: `FD8BB9B2-AF3F-3CFD-ACAE-B20D1E5D0664`
- Bundle ID: `org.openmw.ios`
- Executable name: `openmw`

The Mach-O UUID was independently recovered from the accepted artifact during orchestrator review because the worker report did not record it.

## WO33 accepted result

The Amendment 2 diagnostic trace proved the exact invalid transition:

1. OSG requested `GL_BLEND=1` while its cache reported `valid=1,last=1`.
2. OSG suppressed the route call as `issued=0`.
3. The same-thread GL4ES draw path retained `blend=0` with no active/pending render list.
4. The representative smoke draw reached `glDrawElementsCommon` with correct alpha factors and depth/shader behavior but blending disabled.

Correction `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9` reasserts only cache-matching `GL_BLEND` requests through GL4ES on the Apple/manual route, preserves OSG's return semantics, and leaves GL4ES's state comparison authoritative.

The correction trace contains 55 OSG reassertions, 55 GL4ES enable-ingress events, and four representative smoke target records at `blend=1` with none at `blend=0`. Smoke and spell presentation visibly passed. Foliage transparency is accepted as a visible collateral improvement, not as proof that every foliage path shares the same cause.

The diagnostic system is inactive unless `OPENMW_IOS_RENDERER_DIAGNOSTICS=1` and caps output at 256 KiB.

## Current primary engineering boundary

The remaining primary defect is exterior distance/horizon presentation:

- large white or blank regions appear beyond nearby rendered geometry;
- distant silhouettes can appear disconnected or incomplete;
- a sharp blue horizontal horizon/cutoff band remains visible;
- maximum view distance improves coverage but does not eliminate the defect; and
- the relationship among fog consumption, clipping, sky blending, program presentation, and distant geometry remains unproven.

WO34 falsified aspect-unaware terrain radius as the cause: increasing the captured radius from about `8276.89` to `12221.21` left every target symptom materially unchanged. The terrain patch is rejected and absent from the accepted baseline.

WO35 then proved `sky_blending=1` at view/far distance 7168 on the physical device. Ten verified captures still show the sharp blue band and large white/fog-colored cutoff, so sky blending is rejected as their correction. The user retained it locally because some silhouette fading looks preferable; that is device preference, not a product default or qualified fix.

WO36 has now removed the remaining global distance/paging hypothesis. At constant `7168`, enabling distant terrain changed `object_paging` from `0` to `1` without materially changing the target. At `16384`, moderate-distance coverage improved, but the same dark silhouettes, blue band, and pale uncovered region recurred at the farther boundary with a modest observed performance cost. Exact Arm A state was restored; the device remains at `7168`, with no `[Terrain]` override and with the user's retained sky-blending preference.

The next boundary is exact pixel ownership. Existing diagnostics prove camera/fog intent and broad program receipt but cannot tell whether a photographed target pixel was produced by a particular drawable/program or had no world coverage and exposed the clear/sky composition. WO37 will correlate OSG draw bounds and identity through GL4ES program/state to final target-pixel color/depth and sky RTT sampling. Black silhouettes and the blue/white horizon remain distinct until that evidence proves convergence.

## Secondary and deferred boundaries

- Menu/options touch scrolling remains awkward and unqualified.
- WO30 did not independently verify force-quit/relaunch persistence, the complete action-control matrix, or a post-test crash inventory.
- Reset preserves current opacity instead of restoring nominal `0.20`, and only the selected fixed control has the explicit resize ring.
- Reduced render scale `0.58` remains unqualified because of menu corruption.
- A transient blocky red combat effect was previously captured once and remains unclassified.
- Foliage is no longer a primary visible failure in the accepted WO33 session, but it lacks a dedicated causal trace across all foliage assets/paths.
- Full Qualification has not run for the WO33 baseline.
- The WO35 Arm B device configuration retains `sky blending = true` and start `0.8` by explicit user choice. Its reported silhouette improvement lacks fresh Arm A screenshot identities and remains a secondary user observation rather than a canonical product result.

Water appearance improved after enabling OpenMW water shader effects, so the earlier water concern remains configuration-dependent rather than a proven renderer defect.

## ControlPlane and execution status

WO35 is ACCEPTED and closed for controlled falsification value. Evidence commit `0b563307a32688a4aa5feddb6587f329f13c67b0` is not a product baseline. No source/build change was accepted, and the accepted engineering baseline remains `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`.

WO35's start directive was delivered and acknowledged through the user, but the separate canonical ACTIVE bookkeeping commit was missed after direct-delivery timeout. The final review records this discrepancy explicitly. Worker execution was authorized and no canonical files were modified by the worker.

WO36 is ACCEPTED for controlled falsification value. Final evidence commit `4f6cfc62ced645d4465f401520a1dfaca5e65ab7` is evidence-only. Arm A/B/C identities, diagnostic values, and screenshots verify; no build or GitHub Actions run occurred; and exact Arm A configuration was restored. The accepted engineering baseline remains `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`.

The original WO37 execution was explicitly started through the user on 2026-08-26, although the separate canonical READY → ACTIVE bookkeeping update was missed. Worker branch `codex/wo37-distant-pixel-attribution` stopped cleanly at `e6a6a5b5f9b63b985d93068fb16feaacbb5f4737` after Fast run `33002709474` failed compiling changed GL4ES source. No IPA or target attribution exists, so this is not a renderer result and the accepted engineering baseline remains unchanged.

Amendment 1 repaired the exact `LOAD_GLES_FPE(glReadPixels)` compile defect. Fast run `33019021667` passed and produced the qualified diagnostic artifact, but two physical-device sessions recorded `target_request=none` and zero `r3.*` records despite independently verified correct request-file placement. The request is read once at startup, its Foundation error is discarded, and it is the only prerequisite preventing the existing first-exterior arm point. This is a diagnostic-trigger failure, not a renderer result.

WO37 Amendment 2 is READY to preserve valid explicit requests while auto-arming the same bounded capture on the first eligible exterior fog generation when the request cannot be read. It may use the third and final original Fast slot. This reallocates WO37's unused correction slot: any renderer correction proven by the capture requires a separate later work order.

## Latest important evidence

- [READY WO37 Amendment 2](../WorkOrders/WO-037.md)
- [WO37 Amendment 1 runtime review](../Evidence/WO-037/orchestrator-amendment1-runtime-review.md)
- [WO37 original diagnostic compile-failure review](../Evidence/WO-037/orchestrator-compile-failure-review.md)
- [WO37 governing decision](../Decisions/DEC-016.md)
- [Accepted WO36](../WorkOrders/WO-036.md)
- [WO36 final orchestrator review](../Evidence/WO-036/orchestrator-final-review.md)
- [WO36 execution report](../Evidence/WO-036/report.md)
- [WO36 device capture](../Evidence/WO-036/device-capture.md)
- [Accepted WO35](../WorkOrders/WO-035.md)
- [WO35 final orchestrator review](../Evidence/WO-035/orchestrator-final-review.md)
- [WO35 execution report](../Evidence/WO-035/report.md)
- [WO35 configuration A/B](../Evidence/WO-035/configuration-ab.md)
- [Accepted WO34](../WorkOrders/WO-034.md)
- [WO34 final orchestrator review](../Evidence/WO-034/orchestrator-final-review.md)
- [WO34 execution report](../Evidence/WO-034/report.md)
- [WO34 device capture](../Evidence/WO-034/device-capture.md)
- [Accepted WO33](../WorkOrders/WO-033.md)
- [WO33 acceptance decision](../Decisions/DEC-013.md)
- [WO33 final orchestrator review](../Evidence/WO-033/orchestrator-final-review.md)
- [WO33 execution report](../Evidence/WO-033/report.md)
- [WO33 evidence manifest](../Evidence/WO-033/manifest.md)
- [WO33 compact transition capture](../Evidence/WO-033/blend-transition-capture.md)
- [WO33 device capture](../Evidence/WO-033/device-capture.md)
- [WO33 linked-route proof](../Evidence/WO-033/linked-route-proof.md)
- [Accepted WO32](../WorkOrders/WO-032.md)
- [WO32 falsification decision](../Decisions/DEC-012.md)
- [WO32 final orchestrator review](../Evidence/WO-032/orchestrator-amendment2-final-review.md)
- [Accepted WO30](../WorkOrders/WO-030.md)
- [WO30 touch decision](../Decisions/DEC-007.md)
- [Accepted WO29](../WorkOrders/WO-029.md)
- [WO29 crash-correction decision](../Decisions/DEC-005.md)
- [Accepted WO27](../WorkOrders/WO-027.md)
- [WO27 data-path decision](../Decisions/DEC-003.md)
- Historical ledger: [OpenMW iOS — Engineering Handoff Ledger](https://docs.google.com/document/d/1TOyBHA1tSKBIqoU_XFSIaTMbdCBAcNVsaczy29N_b18/edit)

## Recovery path

1. Read this file.
2. Read READY [WO-037 Amendment 2](../WorkOrders/WO-037.md), its [Amendment 1 runtime review](../Evidence/WO-037/orchestrator-amendment1-runtime-review.md), [DEC-016](../Decisions/DEC-016.md), accepted [WO-036](../WorkOrders/WO-036.md), and the [final WO36 review](../Evidence/WO-036/orchestrator-final-review.md).
3. Inspect current Git and CI state before issuing new work.
4. Use Codebase Memory for structural navigation, then verify implementation facts against checked-out source.
5. Use the Google ledger only for unresolved historical context.

Current execution state is STOPPED. WO37 Amendment 2 is READY and requires an explicit orchestrator start directive before worker continuation.
