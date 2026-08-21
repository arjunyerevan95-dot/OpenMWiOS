# OpenMWiOS — Current State

- Project: OpenMWiOS
- Active branch: `codex/wo27-runtime-data-path`
- Current engineering baseline commit: `6db1c2af5066f810df97c5af39bdbf2a48fb86b5`
- Last completed work order: [WO-027](../WorkOrders/WO-027.md)
- Already-issued next engineering work order: none
- Engineering execution status: **frozen for control-plane migration and orchestrator review**
- Last updated: 2026-08-21

## Qualified state

The highest qualified runtime gate combines the completed WO26 and WO27 results:

- OpenMW installs and launches on a physical iPhone.
- Morrowind, Tribunal, and Bloodmoon content loads.
- Full-screen landscape rendering, UI, audio, input, and scene transitions remain intact.
- The main menu, New Game, the prison-ship sequence, and Seyda Neen exterior traversal have been reached.
- Touch movement and look permit ship traversal and exterior access.
- WO27 resolves the default base-game path from the current iOS Documents directory at runtime. The accepted device launch required no manual `openmw.cfg` edit and no externally supplied container UUID/path.
- No native crash or jetsam was observed in the accepted WO27 device run.

This is a partial touch qualification, not a complete mobile-control qualification. The control overlay is not yet faithful to the recent Android layout/action behavior, and at least the Inventory action is nonfunctional through the current keyboard-style injection path.

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

Primary blocker: Android control-layout and action fidelity. Movement and look work, but the iOS overlay/action bridge is incomplete; Inventory is a demonstrated example.

Current unresolved renderer boundary exposed by exterior traversal:

- foliage alpha/transparency is incorrect, producing opaque leaf cards;
- distant scenery contains missing/white regions and a horizontal band;
- water appearance is not classified because the active OpenMW water settings may be low;
- reduced render scale 0.58 still has menu corruption and is not qualified;
- `ColorMaski` warning activity remains noisy but was not proven to block rendering.

These are observations or unresolved hypotheses, not established root causes. They must not be folded into the completed data-path correction.

## Data-path status

The permanent default-data-path correction is completed in WO27. The stable logical location is `Documents/OpenMW/Morrowind/Data Files`; the current sandbox prefix is obtained at runtime. Existing recognized legacy generated UUID entries are migrated narrowly, while unrelated user and mod paths remain preserved.

The accepted physical test did **not** record the post-install container UUID because the diagnostic transport was unavailable. Therefore it establishes automatic discovery without manual UUID input, but does not independently prove that SideStore changed the UUID in that exact install.

## Migration consistency note

The control-plane migration order described WO26 as the last completed work order and the permanent data-path correction as the frozen next task. Stronger direct evidence disagrees: Git commit `6db1c2a`, Fast run `32480504839`, the completed local WO27 handoff, the device observation, and the read-only Google ledger all show WO27 completed. This repository-backed state therefore records WO27 as completed. No WO28 has been formally issued or invented.

The tracked repository ledger at `docs/ios-port-ledger.md` was locally modified and lagged the completed WO27 evidence at migration time. It was preserved untouched.

## Latest important evidence

- [Canonical WO26 state](../WorkOrders/WO-026.md)
- [Canonical WO27 state](../WorkOrders/WO-027.md)
- [WO27 evidence manifest](../Evidence/WO-027/manifest.md)
- [Qualified renderer baseline decision](../Decisions/DEC-001.md)
- [Touch qualification decision](../Decisions/DEC-002.md)
- [Runtime data-path decision](../Decisions/DEC-003.md)
- Living historical ledger: [OpenMW iOS — Engineering Handoff Ledger](https://docs.google.com/document/d/1TOyBHA1tSKBIqoU_XFSIaTMbdCBAcNVsaczy29N_b18/edit)

## Future orchestrator/worker recovery

1. Read `Documentation/CURRENT_STATE.md`.
2. Read the canonical current `WorkOrders/WO-027.md` and its stated successor status.
3. Read only the `Decisions/` and `Evidence/` records referenced by that work order.
4. Inspect current Git state and active/recent CI before changing anything.
5. Use the Google Docs ledger only when deeper historical context is required.

Do not resume engineering until the control-plane migration passes orchestrator review and a new engineering work order is formally issued or an existing one is explicitly resumed.
