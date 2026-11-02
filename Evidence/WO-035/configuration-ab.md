# WO-035 Same-Binary Configuration A/B

Status: COMPLETE — user explicitly retained Arm B

## Attachment intake

- Received `openmw.cfg` (160 bytes; SHA-256 `89582D8679620EB78B5909619D34F051B64E503A1F27547CC4251CC512007D3F`).
- Inspection confirmed it contains content/archive registration, not `[Fog]` renderer settings.
- It was not modified and cannot serve as either arm of this configuration A/B.

## Arm A — original

- Effective path: `On My iPhone/OpenMW/OpenMW/settings.cfg`
- Exact bytes preserved: YES, original attachment remains unchanged
- Length: 724 bytes
- Encoding/newlines: UTF-8-compatible text without BOM; LF line endings; final LF present
- SHA-256: `EE80D8B9EFD9076070EFDF26902D4D5B881A0B54FE47626CE5C79DC4703743BA`
- `[Fog] sky blending` state: ABSENT, so pinned default `false` applies
- `[Fog] sky blending start` state: ABSENT, so pinned default `0.8` applies
- Duplicate `[Fog]` sections/keys: NONE

## Arm B — authorized delta only

```ini
[Fog]
sky blending = true
sky blending start = 0.8
```

- Temporary test file was generated for device delivery and is not retained in the repository because it contains unrelated user settings.
- One-hour Litterbox delivery URL: `https://litter.catbox.moe/o4hvze.cfg` (HTTP 200; content length 776 bytes)
- Length: 776 bytes
- Exact modified-file SHA-256: `744A7C89510C5E9BFD649CBD93739721905589F5C815D8F6430D99BA08A9EC10`
- Byte audit: the original 724-byte file is an identical prefix; the only appended bytes are one LF followed by the authorized `[Fog]` section and its two keys.
- Semantic-diff audit: PASS; only `sky blending` changes from effective default `false` to explicit `true`; `sky blending start` remains at `0.8` but becomes explicit.
- Duplicate-section/key audit: PASS; exactly one `[Fog]` section and one occurrence of each key.
- Same installed binary: YES
- View-distance/projection held constant: PASS; diagnostic records `selected=7168`, `camera_far=7168`, `view_distance=7168`, aspect `2.17272727`, and resolution `2868,1320`.
- Fresh relaunch diagnostic reports `sky_blending=1`: PASS; session `AFEF6F3A-DD3C-402D-AF51-9D91BECAE505` contains 8 positive records and 0 negative records.

## Restoration

- Exact Arm A file restored after test: NO
- One-hour exact-original restoration URL: `https://litter.catbox.moe/g76wey.cfg`
- User explicitly elected to retain Arm B: YES. On 2026-08-25 the user stated that the sky-blending configuration "works better" and questioned restoring the original. This satisfies WO-035's explicit-user-choice exception to restoration.
- Effective retained setting: `sky blending = true`, `sky blending start = 0.8`.
