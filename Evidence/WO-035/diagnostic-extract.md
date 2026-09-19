# WO-035 Bounded Diagnostic Extract

Raw device diagnostic is referenced by hash and is not duplicated in the repository.

## Identity

- Attachment: `renderer-diagnostic.jsonl`
- Length: 163,586 bytes
- SHA-256: `09649219B1A7AEC907EBB6386B0563AACF859D2C206FFECF0AB50F18D1DD0927`
- Schema: `openmw-ios-renderer-diagnostic-v1`
- Session: `AFEF6F3A-DD3C-402D-AF51-9D91BECAE505`
- Rows: 487 (`sample` 0 through 486)
- Distinct sessions: 1

## Activation proof

- `sky_blending=1` records: 8
- `sky_blending=0` records: 0

First decisive record:

```text
family=r2.clear
clear_color=0.960784,0.921569,0.878431,1
clear_mask=17664
clear_depth=1
sky_blending=1
```

## Held-constant projection

The fresh session records:

```text
selected=7168
camera_near=1
camera_far=7168
terrain_cull=12221.2
fov=60
aspect=2.17272727
resolution=2868,1320
reversed_z=0
```

All captured `r2.arm` generations retain `view_distance=7168` and `end=7168`.

The `terrain_cull=12221.2` value belongs to the already-installed WO-034 binary and is held constant across both same-binary A/B arms. WO-034 had already shown that correction to be visually inert; it is absent from the WO-035 execution branch.

## Runtime health

- Diagnostic families matching error/crash/fatal/jetsam: 0
- User reported no crash during the exterior capture.
