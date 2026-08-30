# WO-030 user-shared log analysis

## Supplied evidence

- `openmw.zip`: SHA-256 `CB05CD146F6367378267C62F2AF6D943EE976042EB96CF3507CE0917697660FE`
  - archive entry `openmw.log`: 914,535,996 bytes
  - compressed size: 5,263,658 bytes
  - extracted log SHA-256: `688236CBD46BD390F72E78BFE087CDC8AC17A008F9628CFC2A4757887F7E8324`
- `shaders.yaml`: SHA-256 `243A12042EC196DE01A5AF784904EC4B69AA32D774A1CCF8ECA990965DCD7E15`
  - content: `config: ~`; no user shader override is expressed by this file.
- `MyGUI.log`: 18,113 bytes; SHA-256 `AA08E68055952B950CC58B7F0230479BAEBEB5DDEAC9506B408D066FDE1537DB`
  - 88 lines; the notable warnings are the existing unknown `ReadOnly` properties in `openmw_controllerbuttons.layout`, not an exterior renderer diagnostic.

The user retrieved and shared these app-owned files without usbmux.

## Why `openmw.log` reached 914 MB

The log spans approximately `17:58:13.764` through `18:04:51.697` (about 397.9 seconds) and contains 8,960,913 lines.

| Record class | Count | Approximate share |
|---|---:|---:|
| `ColorMaski::apply(..) failed, glColorMaski is not support by OpenGL driver.` | 8,864,974 | 98.93% |
| OpenGL `invalid operation` | 67,563 | 0.75% |
| OpenGL `invalid enumerant` | 28,115 | 0.31% |
| All remaining lines | 261 | <0.01% |

The three repeated GL warning classes account for 8,960,652 of 8,960,913 lines. The `ColorMaski` warning alone averaged roughly 22,300 records per second over the captured interval. The 914 MB size is therefore a warning flood, not an unexpectedly large volume from the bounded WO-030 probes.

Representative error locations in the supplied log:

- `invalid operation` after `RenderBin::draw(..)`
- `invalid enumerant` after `TransparentDepthBinCallback::drawImplementation`
- repeated unsupported `ColorMaski::apply(..)` records interleaved with both

This proves the source of the log bloat. The temporal association with transparent-depth rendering is relevant to the visible foliage/particle symptoms, but the log alone does **not** prove that `ColorMaski`, either GL error class, or their combination is the earliest cause of the exterior misrendering.

## WO-030 diagnostic yield

- `WO30 R1 dds`: 96 records.
- `WO30 R1 alpha-state`: 0 records.
- `WO30 R2 intended fog`: 1 record:
  - start `2007.04`
  - end/far `7168`
  - color `0.960784,0.921569,0.878431`
  - underwater `0`
- `WO23 fragment program`: 7 records.

The 96-record DDS budget was consumed during startup by UI, cursor, water, and other early textures before a representative exterior foliage sample was identified. No NIF alpha-state sample was present in the file. The fog record proves OpenMW intended a nonzero fog interval and a near-white fog color for the loaded exterior, but there is no matching GL4ES received-state/uniform record in this file.

The GL4ES-side WO-030 probes wrote to `stderr`; they were not mirrored into `openmw.log`. Therefore this share proves the app-owned file workflow works, but it cannot complete the intended OpenMW-to-GL4ES comparison.

## Evidence-bounded conclusions

1. The suspicious file size is explained: unbounded existing GL warnings, overwhelmingly `ColorMaski`, flooded the log.
2. The bounded WO-030 diagnostic records are not responsible for the size.
3. The current R1 capture did not obtain the representative exterior alpha-state/texture pair required to localize the foliage/particle defect.
4. The current R2 capture obtained OpenMW's intended fog values but not the corresponding GL4ES values.
5. A future explicitly authorized diagnostic should rate-limit/deduplicate the existing GL warning flood and write bounded GL4ES state into an app-owned shareable file. No such runtime change was made while analyzing this evidence.
