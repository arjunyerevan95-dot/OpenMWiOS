# WO-031 R2 — distance, fog, and horizon evidence

## Outcome

The Amendment 1 replacement candidate reached the exterior, but the retrieved file contained zero R2 records and zero GL4ES records. No intended/applied fog correlation or two-distance comparison was captured.

The established OpenMW intended exterior values from WO30 remain evidence, not newly qualified WO31 results:

- fog start: `2007.04`;
- fog end/far: `7168`;
- fog color: approximately `0.960784,0.921569,0.878431`;
- underwater: `0`.

The supplied screenshots visibly reproduce the large white/blank regions and sharp blue horizon band. WO-031 did not establish what GL4ES received or applied, and did not localize the missing distance/fog presentation. No R2 renderer correction was made.

See [diagnostic-channel.md](diagnostic-channel.md) for the diagnostic lifecycle regression and [report.md](report.md) for the stop result.

## Amendment 2 result

The device file proves this partial chain:

`OpenMW exterior intent → OSG Fog apply → GL4ES fog receipt`

The values agree: linear mode `9729`, start `2007.04`, end `7168`, and color `0.960784,0.921569,0.878431,1`. This falsifies the hypothesis that exterior fog values never reach GL4ES at all.

The required applied-program link remains absent. All 32 `r2.applied` records exhaust by sample 41 and describe only program 1 before exterior receipt (`has_builtin_fog=0`, `received_count=0`, default start/end/color). Exterior fog receipt begins at sample 324. No representative exterior shader/program consumption was captured. The run also contains only one repeated view-distance intent rather than two materially different settings.

R2 earliest invalid boundary is narrowed to **after GL4ES receipt but before or within representative exterior-program consumption/presentation**, but it is not proven more precisely. The white regions and blue band remain visible. No R2 correction was selected.
