# WO-031 R1 — alpha and particle evidence

## Outcome

The Amendment 1 replacement candidate reached the exterior and captured 22 later OpenMW records, but zero GL4ES records. It recorded 21 `r1.state` entries and one `r1.asset` entry for the non-translucent control texture `textures/_land_default.dds`. It did not capture a representative defective foliage, hanging-moss, spell-fire, or chimney-smoke draw correlated through GL4ES.

The following established physical symptoms remain unresolved and unchanged as project evidence:

- opaque foliage and hanging-moss cards;
- blocky rectangular spell-fire layers;
- blocky chimney-smoke particles.

The supplied screenshots visibly reproduce opaque foliage cards. The shared alpha/blend-path hypothesis remains a hypothesis. WO-031 did not establish the applied GL4ES blend/alpha-test state or earliest invalid R1 boundary on device. No R1 renderer correction was made.

See [diagnostic-channel.md](diagnostic-channel.md) for the diagnostic lifecycle regression and [report.md](report.md) for the stop result.

## Amendment 2 result

The device file now identifies real defective-family assets and their GL texture object IDs, including smoke texture 115, fire texture 148, foliage texture 118, and multiple moss/fern/kelp textures. This disproves the earlier concern that OpenMW-side asset registration could not reach the OSG/GL identity boundary.

It does not complete the representative draw chain. The 96 `r1.draw` records all have `category=-1` and exhaust at sample 199. The first defective `r1.bound` record occurs at sample 210. Consequently no captured GL4ES draw can be assigned to a defective foliage or particle asset, and its blend/alpha-test state cannot be used as causal evidence.

R1 earliest invalid boundary remains **unknown**. Opaque cards and rectangular particle layers remain visible. No R1 correction was selected.
