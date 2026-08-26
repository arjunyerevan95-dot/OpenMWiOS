# WO-036 Execution Report

- Status: COMPLETE — VALID FALSIFICATION
- Route: B — PAGING/HIGHER DISTANCE ONLY MOVES THE BOUNDARY
- Stop condition: C — DISTANT-TERRAIN AND HIGHER-DISTANCE HYPOTHESIS FALSIFIED
- Execution branch: `codex/wo36-distant-terrain-qualification`
- Starting HEAD: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`
- Product/source changes: NONE
- Build/CI/artifact: NONE

## Result

The same installed WO34 binary was exercised across three bounded configuration arms. Arm A session `D32D7DD0-7F4B-4568-A68D-AE8983B67DE9` proves `selected=7168`, `camera_far=7168`, and `object_paging=0`. Arm B session `0ED5F557-168A-4264-8D66-0B533DB76017` proves `selected=7168`, `camera_far=7168`, and `object_paging=1` after the sole terrain-selection change `distant terrain = true`.

Interim orchestrator review required Arm C because Arm B proved paging active and usable. Arm C session `644CF060-AAD4-42AC-9026-9C8713EE78F8` proves `selected=16384`, `camera_far=16384`, `view_distance=16384`, fog end `16384`, `terrain_cull=27934.2`, and `object_paging=1`. Six physical captures and the user's direct observation establish that moderate-distance coverage meaningfully improved, but the same dark silhouette/fade behavior persists farther away wherever draw distance fades out. The blue band and white/fog-colored missing region likewise remain visible at the displaced far boundary. The user also observed a modest performance dip when viewing long vistas.

This is the precise Route B result: terrain paging is active and a larger camera distance expands the rendered radius, but it does not correct the defective boundary. Arm D is optional under the canonical order and is not needed because Arm C is already causally decisive; extending to 32768 would only move the same target farther while increasing cost.

No product/source change was made. No build or workflow was started. The exact Arm A restoration file remains available at `https://files.catbox.moe/uizp88.cfg`, 776 bytes, SHA-256 `744A7C89510C5E9BFD649CBD93739721905589F5C815D8F6430D99BA08A9EC10`. The user restored it after Arm C and confirmed completion.

The GitHub Actions API was unreachable during the duplicate-run query. Local history and branch state contain no WO-036 build or workflow dispatch.

## Completion boundary

Arm A/B/Arm C now distinguish the boundary cleanly:

1. `object_paging 0 -> 1` at constant 7168 does not remove the target.
2. Increasing camera/fog/view distance to 16384 with paging active improves moderate-distance coverage.
3. The same dark silhouettes and blue/white cutoff recur at the new farther fade boundary.

The higher-distance hypothesis therefore changes where the failure occurs rather than fixing it. Exact Arm A restoration is reconfirmed, and WO-036 stops at Route B / Stop Condition C for orchestrator review.
