# OpenMWiOS — Current State

- Project: OpenMWiOS
- Active branch: `codex/wo28-android-touch-fidelity`
- Current engineering baseline commit: `6db1c2af5066f810df97c5af39bdbf2a48fb86b5`
- Control-plane baseline commit: `88bce1f0bdf709661d2c45644b6eef26c021c87b`
- Active work order: none
- Ready work order: [WO-029](../WorkOrders/WO-029.md)
- Last completed work order: [WO-027](../WorkOrders/WO-027.md)
- Last reviewed work order: [WO-028](../WorkOrders/WO-028.md) — execution **REJECTED**, status **SUPERSEDED**
- Current objective: capture, classify, and symbolicate the rejected WO28 candidate's launch-time, `New Game`, and overlay-action crash paths; apply only a proven bounded correction
- Engineering execution status: **WO-029 READY; execution has not started**
- Current unqualified WO28 implementation: candidate `1dc819cea447f8ac40c878e1a6d7f4d478e94063` built and packaged successfully, but failed device acceptance after user-observed launch-time, `New Game`, and overlay-action hard crashes
- Last updated: 2026-08-22

## Qualified state

The highest qualified runtime gate combines the completed WO26 and WO27 results:

- OpenMW installs and launches on a physical iPhone.
- Morrowind, Tribunal, and Bloodmoon content loads.
- Full-screen landscape rendering, UI, audio, input, and scene transitions remain intact.
- The main menu, New Game, the prison-ship sequence, and Seyda Neen exterior traversal have been reached.
- Touch movement and look permit ship traversal and exterior access.
- WO27 resolves the default base-game path from the current iOS Documents directory at runtime. The accepted device launch required no manual `openmw.cfg` edit and no externally supplied container UUID/path.
- No native crash or jetsam was observed in the accepted WO27 device run.

This is a partial touch qualification, not a complete mobile-control qualification. WO28's first production/device pass preserved movement, look, exterior traversal, rendering, and WO27 data discovery, but failed visual/layout fidelity. Its amended candidate rendered the main menu and Android-derived icons, then failed runtime acceptance. The user reported intermittent immediate launch-time crashes, immediate hard crashes from every tested overlay button after reaching the menu, and an immediate hard crash from `New Game`. These are three distinct investigative paths until crash evidence shows that they converge. WO28 did not qualify any replacement touch implementation.

## Versions and accepted candidate

- OpenMW: `f4bec41444214a7903bebd178389ca22ca13f646` (0.51.0)
- SDL: 2.32.10
- OSG: `01cc2b585c8456a4ff843066b7e1a8715558289f` (3.6.5)
- GL4ES: `c9895df34cd466c23bc60c2bd3db3d87e98fcbe7` (1.1.6)
- Deployment target: iOS 16.3
- Architecture: arm64
- Accepted Fast Development run: `32480504839`
- Executable SHA-256: `88EA697FFD7BBD7F5294058C82F8B2DF876B8BB5461CEAF24715A29D2DDFAA54`
- IPA SHA-256: `9CA825C1B4635EE7C12FCA2A5BBB437471BD73E0EF43ECBEA651998D723441F9`

See [WO27 evidence](../Evidence/WO-027/manifest.md) for the candidate, CI, test, and device references.

## Current blockers and unresolved boundary

Primary engineering boundary: native crash capture and root-cause isolation for the rejected WO28 candidate. The intermittent launch-time crash, `New Game` crash, and overlay-action crash must remain separate hypotheses until symbolicated crash/termination evidence establishes a common cause. The installed candidate identity was not independently read back from the device.

The user reported that SideStore's own certificate was no longer valid before this WO28 IPA was sideloaded, then re-signed SideStore and sideloaded OpenMW. This is environmental evidence only. No signing, entitlement, dyld, provisioning, or installation-state evidence currently connects it to any crash.

Current unresolved renderer boundary exposed by exterior traversal:

- foliage alpha/transparency is incorrect, producing opaque leaf cards;
- distant scenery contains missing/white regions and a horizontal band;
- water appearance improved after the user enabled OpenMW water shader effects, so the prior water concern is currently configuration-dependent rather than a proven renderer defect;
- distance fog appears absent at the configured draw boundary, leaving white/empty regions beyond rendered geometry; its relationship to the foliage-alpha defect is unknown;
- reduced render scale 0.58 still has menu corruption and is not qualified;
- `ColorMaski` warning activity remains noisy but was not proven to block rendering.

These are observations or unresolved hypotheses, not established root causes. They must not be folded into the completed data-path correction.

## Data-path status

The permanent default-data-path correction is completed in WO27. The stable logical location is `Documents/OpenMW/Morrowind/Data Files`; the current sandbox prefix is obtained at runtime. Existing recognized legacy generated UUID entries are migrated narrowly, while unrelated user and mod paths remain preserved.

The accepted physical test did **not** record the post-install container UUID because the diagnostic transport was unavailable. Therefore it establishes automatic discovery without manual UUID input, but does not independently prove that SideStore changed the UUID in that exact install.

## Latest important evidence

- [Ready WO29](../WorkOrders/WO-029.md)
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
- Living historical ledger: [OpenMW iOS — Engineering Handoff Ledger](https://docs.google.com/document/d/1TOyBHA1tSKBIqoU_XFSIaTMbdCBAcNVsaczy29N_b18/edit)

## Future orchestrator/worker recovery

1. Read `Documentation/CURRENT_STATE.md`.
2. Read the canonical READY `WorkOrders/WO-029.md`, then its referenced WO28/WO27 records only as needed.
3. Read only the `Decisions/` and `Evidence/` records referenced by that work order.
4. Inspect current Git state and active/recent CI before changing anything.
5. Use the Google Docs ledger only when deeper historical context is required.

WO29 is canonically READY but has not started. Engineering execution requires a separate explicit orchestrator start directive; merely reading the work order does not make it ACTIVE.
