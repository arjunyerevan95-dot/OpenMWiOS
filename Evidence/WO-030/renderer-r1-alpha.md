# WO-030 R1 — foliage alpha/cutout investigation

## Symptom baseline

The accepted WO29 device screenshots show Seyda Neen foliage and hanging-moss polygons as opaque rectangular/sheet-like cards. UI transparency remains functional, so this is not evidence of a global blending or presentation failure.

## Source path verified before runtime diagnostics

1. OpenMW's DDS reader invokes `dds_dxt1_detect_rgba`; DXT1 one-bit-alpha detection is therefore present before OSG image creation.
2. `components/nifosg/nifloader.cpp` translates NIF alpha properties into an `osg::AlphaFunc` with the NIF threshold.
3. OpenMW's shader visitor supplies the alpha-test definition/reference used by the compatibility object fragment shader.
4. The compatibility shader performs the cutout with `alphaTest(..., alphaRef)`/`discard` semantics.
5. GL4ES decompresses DXT content and exposes `transparent0`, `simpleAlpha`, and `complexAlpha` decisions in `src/gl/texture_compressed.c`.

This proves the intended cutout path exists. It does **not** establish where the representative exterior draw first diverges.

## Diagnostic contract

Candidate `d1d5182b344f77aa2cdee1169c30d3e2ee0dd955` adds bounded, observation-only records for:

- representative NIF alpha function/reference and texture identity (up to 64 samples);
- DDS path, pixel format, compression/translucency and dimensions (up to 96 samples);
- GL4ES DXT upload format and detected alpha class (up to 96 level-zero uploads).

No alpha state, texture pixels, shader defines, or render-bin behavior is modified by the diagnostic patch.

## Current causal status

**UNPROVEN after the diagnostic device run.** Opaque appearance alone is insufficient to choose between asset alpha classification, NIF/OSG state, shader uniform/define propagation, or GL4ES decompression semantics. The user-shared log contains 96 startup DDS records but no `WO30 R1 alpha-state` record; the DDS budget was consumed before a representative exterior foliage sample was isolated. See [shared-log-analysis.md](shared-log-analysis.md).

## Device observation and offline-log boundary

The user installed and exercised the diagnostic candidate without usbmux logging. The foliage sheets remained unchanged. Additional screenshots showed rectangular/blocky spell-fire layers and blocky chimney-smoke particles. This broadens the observed symptom family and strengthens a shared alpha/blending-path hypothesis, but it does not identify the earliest invalid renderer boundary and is not causal proof.

The candidate's OpenMW-side DDS and NIF alpha-state records should be written to `Documents/OpenMW/openmw.log` and can be shared without live device logging. Its GL4ES DXT alpha-classification records were emitted to `stderr`, so they are absent from the shareable OpenMW log unless captured through a console transport. A future file-backed GL4ES diagnostic sink would remove that transport dependency; it was not implemented in WO-030.
