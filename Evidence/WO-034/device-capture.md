# WO-034 device capture

## Candidate identity

- Correction commit: `398a91759b1b327b464cf81e41320b8e5f312c9b`.
- Fast Development run: `32854124142`.
- IPA SHA-256: `EE9631158A008A2304A3CA766F2DDD9BFBDA2DD9ED6A9775297DE9FC3DEDB043`.
- Executable SHA-256: `CA6F0BDDA065C64E933B8912474C83ADD97E9532481EF4661A8382BE9AE79AC4`.
- Mach-O UUID: `55DF5E1E-3ED9-399F-A083-A191DCD52B3B`.
- Setting: maximum view distance.

## User observation

The user reported that the correction fixed neither of the two explicitly tested presentation defects:

- the large fog-colored/white terrain gaps remained; and
- the sharp blue horizontal horizon/cutoff band remained.

The user also clarified that the pure-black silhouettes shown on distant terrain/objects were not new in this build. They were always present and were part of what the user had previously called the distracting "weirdness in the distance." They must therefore be treated as a pre-existing symptom, not a WO34 regression.

Nearby terrain, buildings, water, sky, HUD, touch overlay, and the previously corrected foliage presentation are visibly present in the supplied captures. The application sustained an exterior session long enough to produce seven views, and the user did not report a crash or jetsam. Chimney smoke and spell effects were not specifically requalified in this WO34 capture and are not claimed here.

No renderer JSONL or deep live-device logging was required or supplied for this visual falsification result.

## Screenshot identities

External attachment directory (local traceability only):

`C:\Users\arjun\.codex\codex-remote-attachments\019ffd24-a544-7153-9790-108f7079471e\07E8F79A-82A8-459F-89A4-7547E9F3C90E`

| File | Bytes | SHA-256 |
|---|---:|---|
| `1-Photo-1.jpg` | 183624 | `E9EB14F1518B55C8E0AF78B2DEE58E89E634FEDC3C74D5EF8AE281326BFEBA72` |
| `2-Photo-2.jpg` | 199998 | `87393F87540B6C79EC76523015CE2A8C4CA1A32AF43E04E077D9B072B7DF066A` |
| `3-Photo-3.jpg` | 186211 | `2DDB55B6F4EBAB1BDA53E91B34EB460DA41685C03007B389167D62537173F33F` |
| `4-Photo-4.jpg` | 191831 | `D271488D1EAFD92643B0950CCAB85D4D0C663C7EE5DF48D66BC2CB3117E408E8` |
| `5-Photo-5.jpg` | 194696 | `DD6C3CF4E670FCF49C603515DE629E401C6EC8719BEB79936A5C01C821989905` |
| `6-Photo-6.jpg` | 174431 | `EE536BE53CC6DA1BC9AF6D7F59ABBBB445137A4A4BCC9EB152B6F77428B4E516` |
| `7-Photo-7.jpg` | 181126 | `31D36AD3D24E25AA1A49CC29005C2E79AFFBFE90B6195741DCF10741F41AE921` |

## Before/after classification

| Symptom | WO34 result |
|---|---|
| Fog-colored/white distance gaps | No material change |
| Sharp blue horizon/cutoff band | No material change |
| Distant pure-black silhouettes | No material change; pre-existing symptom |
| Nearby world/HUD/touch presentation | Still operational in supplied captures |
| Crash/jetsam | None reported |

The user-visible prediction in `causal-model.md` was therefore falsified: increasing terrain's radial coverage to enclose the full perspective frustum did not materially affect the reported exterior defects.
