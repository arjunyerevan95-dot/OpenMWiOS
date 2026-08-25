# WO-036 Execution Report

- Status: COMPLETE — VALID FALSIFICATION
- Route: B — PAGING HYPOTHESIS FALSIFIED AT CONSTANT DISTANCE
- Stop condition: C — DISTANT-TERRAIN HYPOTHESIS FALSIFIED
- Execution branch: `codex/wo36-distant-terrain-qualification`
- Starting HEAD: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`
- Product/source changes: NONE
- Build/CI/artifact: NONE

## Result

The same installed WO34 binary was exercised at the same 7168 view distance. Arm A session `D32D7DD0-7F4B-4568-A68D-AE8983B67DE9` proves `object_paging=0`. Arm B session `0ED5F557-168A-4264-8D66-0B533DB76017` proves `selected=7168`, `camera_far=7168`, and `object_paging=1` after the sole configuration change `distant terrain = true`.

Eight Arm B physical captures still show the sharp blue horizontal band, broad white/fog-colored missing region, and dark distant silhouettes. Object paging changed the terrain implementation and loaded additional exterior cells, but did not materially correct the target. This selects Route B and Stop Condition C. Arms C/D are not authorized because the same-distance paging test already falsified the causal target; moving the boundary with a larger camera distance would not be accepted as a renderer correction.

No product/source change was made. No build or workflow was started. The exact Arm A restoration file is available at `https://files.catbox.moe/uizp88.cfg`, 776 bytes, SHA-256 `744A7C89510C5E9BFD649CBD93739721905589F5C815D8F6430D99BA08A9EC10`. The user restored it, force-quit/relaunched, and reported: `Launched normal`.

The GitHub Actions API was unreachable during the duplicate-run query. Local history and branch state contain no WO-036 build or workflow dispatch.

## Completion boundary

The pre-WO36 configuration is restored and normal launch is confirmed. WO-036 stops at orchestrator review. No further experiment, source change, build, or canonical ControlPlane update was performed.
