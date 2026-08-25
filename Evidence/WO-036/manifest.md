# WO-036 Evidence Manifest

- Status: COMPLETE — VALID FALSIFICATION / STOP CONDITION C
- Execution branch: `codex/wo36-distant-terrain-qualification`
- Accepted engineering baseline: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`
- Canonical ControlPlane commit read: `ec0c5ced15862e5b0af993995a8fd1fdf7995ee8`
- Start directive received: 2026-08-25 (thread-local explicit directive)
- Product/source changes: NONE
- CI/builds started: NONE
- Canonical ControlPlane files changed by worker: NONE

## Records

- [Execution report](report.md)
- [Source and setting proof](source-and-setting-proof.md)
- [Configuration arms](configuration-arms.md)
- [Device capture](device-capture.md)

## Arm A identities

- Settings: 776 bytes; SHA-256 `744A7C89510C5E9BFD649CBD93739721905589F5C815D8F6430D99BA08A9EC10`
- Diagnostic: 162,195 bytes; SHA-256 `18B330E70143CCD7C267E6F869FEC41DB1645EAF044ED32B42F25712164C053D`
- Session: `D32D7DD0-7F4B-4568-A68D-AE8983B67DE9`
- Six physical screenshots: identities recorded in `device-capture.md`

Arm A proves view distance 7168 and `object_paging=0`. Arm B applies only the authorized terrain-selection change and proves `object_paging=1` at the same distance; the visual target remains unchanged.

## Arm B configuration identity

- Settings: 810 bytes; SHA-256 `CF9D0B05CCCDFCAA925BD40A0A1A94F80EF0C41D492CB5E94178EE59B6736C53`
- Delivery URL: `https://files.catbox.moe/etltwd.cfg`
- Semantic delta: append `[Terrain]` / `distant terrain = true`; all 776 Arm A bytes remain identical.
- Litterbox API returned HTTP 403 from the worker network; Catbox delivered the identical hashed file.

## Arm B device identities

- Diagnostic: 148,642 bytes; SHA-256 `52993834ACF2BE7FC5D72B7F64E7320A387BAD8D258B1D06AF906092B8DFAE09`
- Session: `0ED5F557-168A-4264-8D66-0B533DB76017`
- Proof: `selected=7168`, `camera_far=7168`, `object_paging=1`
- Eight physical screenshots: identities recorded in `device-capture.md`
- Result: blue band, white gap, and distant silhouettes remain; Route B / Stop Condition C selected.

## Restoration

- Exact Arm A restore file: 776 bytes; SHA-256 `744A7C89510C5E9BFD649CBD93739721905589F5C815D8F6430D99BA08A9EC10`
- Verified URL: `https://files.catbox.moe/uizp88.cfg`
- Confirmation: COMPLETE; exact Arm A settings restored and user reported `Launched normal`
