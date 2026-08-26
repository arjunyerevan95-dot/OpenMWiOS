# WO-036 Configuration Arms

## Constants

- Same installed binary: WO34 IPA expected, SHA-256 `EE9631158A008A2304A3CA766F2DDD9BFBDA2DD9ED6A9775297DE9FC3DEDB043` where independently verifiable.
- Retained Fog keys must remain unchanged: `sky blending = true`, `sky blending start = 0.8`.
- No fog, FOV, near-plane, water, depth, shader, render-scale, active-grid, LOD, or composite-map changes are authorized.

## Arm A — 7168, distant terrain absent/false

- Status: COMPLETE / TRUSTWORTHY
- Exact settings bytes: 776
- Exact settings SHA-256: `744A7C89510C5E9BFD649CBD93739721905589F5C815D8F6430D99BA08A9EC10`
- `[Camera] viewing distance`: 7168
- `[Terrain]` section/keys: ABSENT; pinned default `distant terrain = false` applies
- Retained Fog keys: `sky blending = true`, `sky blending start = 0.8`
- Diagnostic bytes: 162,195
- Diagnostic SHA-256: `18B330E70143CCD7C267E6F869FEC41DB1645EAF044ED32B42F25712164C053D`
- Session: `D32D7DD0-7F4B-4568-A68D-AE8983B67DE9`
- Projection: `selected=7168`, `camera_far=7168`, `terrain_cull=12221.2`, resolution `2868x1320`
- Content: `active_grid=-3,-10,0,-7;object_paging=0`
- Matching screenshots: six supplied and hashed in `device-capture.md`

## Arm B — 7168, distant terrain true

- Status: COMPLETE / TRUSTWORTHY / TARGET UNCHANGED
- Exact settings bytes: 810
- Exact settings SHA-256: `CF9D0B05CCCDFCAA925BD40A0A1A94F80EF0C41D492CB5E94178EE59B6736C53`
- Delivery URL: `https://files.catbox.moe/etltwd.cfg`
- Litterbox delivery note: its API returned HTTP 403 from the worker network; the identical file was delivered through Catbox instead.
- Sole intended semantic change: `[Terrain] distant terrain = true`
- Byte proof: the first 776 bytes are identical to Arm A; the appended 34 bytes add only the Terrain section/key.
- Diagnostic bytes: 148,642
- Diagnostic SHA-256: `52993834ACF2BE7FC5D72B7F64E7320A387BAD8D258B1D06AF906092B8DFAE09`
- Session: `0ED5F557-168A-4264-8D66-0B533DB76017`
- Projection: `selected=7168`, `camera_far=7168`, `terrain_cull=12221.2`, resolution `2868x1320`
- Content: `active_grid=-3,-10,0,-7;object_paging=1`, later `active_grid=-3,-9,0,-6;object_paging=1`
- Large slider beyond 7168: not separately photographed; pinned UI route establishes it is selected when distant terrain is enabled
- Visual target: UNCHANGED

## Arm C — 16384, paging active

- Status: COMPLETE / TRUSTWORTHY / BOUNDARY DISPLACED, NOT FIXED
- Exact settings bytes: 811
- Exact settings SHA-256: `E3EEE648AD561F3EC5B950AB63645442256DB62FDEBFD863DF8316AE762A3829`
- Verified delivery URL: `https://files.catbox.moe/2gi5xw.cfg`
- Relative to exact Arm A, only `viewing distance = 7168` becomes `viewing distance = 16384` and `[Terrain] distant terrain = true` is added.
- Retained Fog keys: `sky blending = true`, `sky blending start = 0.8`
- Diagnostic bytes: 163,291
- Diagnostic SHA-256: `360A209BD9D751493E5C6215E5F369730CE13E09CF16A4A00D9037B92DF8A92C`
- Session: `644CF060-AAD4-42AC-9026-9C8713EE78F8`
- Projection: `selected=16384`, `camera_far=16384`, `terrain_cull=27934.2`, resolution `2868x1320`
- Content: `object_paging=1`
- Fog/view receipt: `start=4587.52`, `end=16384`, `view_distance=16384`
- Device result: moderate-distance terrain/objects meaningfully improved; blue/white cutoff and dark silhouettes persist at the farther fade boundary
- Performance observation: modest dip while looking across long vistas; no crash/jetsam reported

## Arm D — 32768, paging active

- Status: NOT RUN; optional and unnecessary after Arm C decisively showed boundary displacement with added performance cost

## Restoration

- Exact pre-WO36 Arm A file: 776 bytes; SHA-256 `744A7C89510C5E9BFD649CBD93739721905589F5C815D8F6430D99BA08A9EC10`
- Verified download: `https://files.catbox.moe/uizp88.cfg`
- Post-Arm-B restoration: COMPLETE; user reported `Launched normal`
- Final post-Arm-C restoration: COMPLETE; user confirmed `Done`
