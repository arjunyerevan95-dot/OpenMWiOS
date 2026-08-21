# WO-027 Evidence Manifest

- Work order: [WO-027 — Permanent iOS Game-Data Path Resolution](../../WorkOrders/WO-027.md)
- Engineering baseline: `5c60db4c4f1ca5c135a0bea754496b7a2f1af3f1`
- Accepted correction: `6db1c2af5066f810df97c5af39bdbf2a48fb86b5`
- Evidence status: accepted with one explicitly recorded physical-identity limitation

## Source and patch evidence

- Git commit `6db1c2af5066f810df97c5af39bdbf2a48fb86b5` — `Fix iOS sandbox-independent game data path`.
- Detailed workspace handoff inspected during migration: `WORK-ORDER-27-HANDOFF.md`.
- Previous touch baseline: [WO-026](../../WorkOrders/WO-026.md), ending at `5c60db4c4f1ca5c135a0bea754496b7a2f1af3f1`.
- Decision record: [DEC-003](../../Decisions/DEC-003.md).

The detailed handoff was workspace-local and untracked at migration time. The canonical repo-backed current-state references are this manifest and `WorkOrders/WO-027.md`; the handoff remains preserved and was not rewritten.

## Regression evidence

- Focused tests: 15 passed.
- Covered current Documents resolution, stable relative-path construction, simulated container A/B changes, recognized stale-entry migration, unrelated data/mod/settings preservation, missing-data behavior, base file discovery, and repeated-launch idempotence.
- No renderer, GL4ES, OSG, SDL, or touch behavior was intentionally changed by WO27.

## CI and artifact evidence

- Workflow: `iOS Fast Development`.
- Run ID: `32480504839`.
- Result: completed / success.
- Head SHA: `6db1c2af5066f810df97c5af39bdbf2a48fb86b5`.
- Full Qualification: did not run.
- Artifact ID: `9447925963`.
- Artifact name: `OpenMW-iOS-fast-27`.
- GitHub artifact wrapper digest: `sha256:58d3b463869204286665d13dd10cbbb40a06d748f67fbec358886db817bf8139`.
- Executable SHA-256: `88EA697FFD7BBD7F5294058C82F8B2DF876B8BB5461CEAF24715A29D2DDFAA54`.
- IPA SHA-256: `9CA825C1B4635EE7C12FCA2A5BBB437471BD73E0EF43ECBEA651998D723441F9`.
- Recorded duration: 1h12m37s; qualified dependency caches missed on this run. No cache redesign was performed.

## Device evidence

- The exact WO27 IPA was installed through the established route.
- No manual `openmw.cfg` edit was performed for the accepted launch.
- No external tool supplied a sandbox UUID or absolute data path.
- OpenMW automatically found the base game data and reached the full-screen, textured, lit Jiub scene with the touch overlay present.
- No user-observed native crash or jetsam occurred.
- Accepted screenshot SHA-256: `426C1A3401A0D01C9FA291038DBCC0500F06598D1C1197856EC34C1524C590B1`.
- Screenshot source was a user-provided conversation attachment; it is referenced, not duplicated in this repository.

## Evidence limitation

`POST_INSTALL_CONTAINER_IDENTITY=NOT RECORDED` because usbmux diagnostics were unavailable. The physical result establishes automatic path discovery with no UUID/config intervention. It does not establish that the SideStore operation changed the container UUID in that exact test.

## Authoritative narrative references

- Google Doc: [OpenMW iOS — Engineering Handoff Ledger](https://docs.google.com/document/d/1TOyBHA1tSKBIqoU_XFSIaTMbdCBAcNVsaczy29N_b18/edit), WO27 section and Current Project State.
- Google ledger was read-only during this migration and was not modified.
- The tracked `docs/ios-port-ledger.md` was locally modified and stale relative to the WO27 Git/CI/device evidence; it was preserved untouched.

## Current transition

WO27 is completed. No WO28 has been formally issued. All normal engineering remains frozen pending control-plane migration review.
