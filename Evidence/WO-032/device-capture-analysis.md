# WO-032 replacement-diagnostic device capture

## Capture identity

- Diagnostic implementation: `79231c0fbf9293388f8f47456f8c2a2696291633`.
- Fast run: `32627872506`.
- IPA SHA-256: `90C6AA65BBAADE4FF0D13D2BC7E124E1EBD119D2A91C513E80FA39C802A942`.
- Executable SHA-256: `BA7E32C8A3E5BBBFF0D38DBE89606D0D009C562E323F4F9B206C8BEE6513F316`.
- Device JSONL SHA-256: `F2D73B5C697E326EDA889244366281AB9A40752E3FD6C8EE7D5C14D779FB3B02` (100,514 bytes, 317 records).
- Session: `39288F15-DB13-4C3D-AFC8-DCE9DF45E5C1`.

Screenshot SHA-256 values:

| Capture | SHA-256 | Observation |
|---|---|---|
| `1-Photo-1.jpg` | `F743327D64B13159296B4DC743DFB84CD18E0A835398A07863A29A5C30EAB739` | Opaque foliage cards |
| `2-Photo-2.jpg` | `D63E3B69D9FF243ADACC269DEA400FB2FDAAC819155B9AFBB70675C116EE2522` | Blocky chimney smoke |
| `3-Photo-3.jpg` | `A9BE8F4487BA12A6EBD3D59A3E0D1114F46883673630F9BBABBE145AB08B7BC0` | White distance region and blue horizon band |
| `4-Photo-4.jpg` | `7BDFD4589E5EBC90190B41A29BD773BD45EED9E36A7214CA96622D3CD3DB29F7` | Opaque blue spell-effect cards |
| `5-Photo-5.jpg` | `F67B20ED3DEEE121F1FB76FE6D3DE81B0953B193D1F0E349979825B0A7D2ED6D` | Opaque orange spell/fire cards |

## R1 decisive samples

Chimney smoke was dynamically correlated as `textures/tx_smokealpha00a.dds`, GL texture 129, DXT5/compressed-RGBA (`pixel_format=33778`), and `translucent=1`. Its applied draw was:

```text
generation=1;program=9;texture=129;category=2;target=2;count=276;blend=0;blend_func=770,771,770,771;alpha_test=0;alpha_func=516;alpha_ref=0;depth_test=1;depth_write=0;depth_func=515;fog=1;fog_start=2007.04;fog_end=7168;fog_color=0.960784,0.921569,0.878431,1;has_fpe=0;default_fragment=0;fragment_has_discard=1;fragment_writes_alpha=1
```

The transparent asset, standard `SRC_ALPHA` / `ONE_MINUS_SRC_ALPHA` factors, disabled depth writes, and alpha-producing/discarding fragment shader all reached the draw. GL4ES nevertheless recorded `blend=0`. This is the earliest invalid R1 boundary for smoke/particles.

The foliage target captured `textures/tx_bc_moss.dds`, GL texture 292, DXT1/RGB (`pixel_format=33776`), `translucent=0`, with program 21. Its draw had `blend=0`, `alpha_test=0`, depth writes enabled, and a fragment shader with neither discard nor alpha output. This proves the captured foliage draw is opaque before raster output, but it does not yet prove whether its first incorrect boundary is asset format/classification, OpenMW state, or shader generation.

The opaque control target used GL texture 134 / program 12 with depth testing and depth writes enabled. It remained a valid comparison draw.

## State-owner proof

Pinned OSG 3.6.5 applies core modes through direct inline `glEnable` / `glDisable` calls in `include/osg/State`, and its ordinary `BlendFunc::apply` path calls direct `glBlendFunc`. The existing iOS routing patch redirected dynamically resolved OSG entry points through `gl4es_GetProcAddress`, but did not redirect these direct core calls.

The exact diagnostic executable's Mach-O symbol table proves the resulting split:

```text
_gl4es_glBlendFunc    type=0x1e sect=1 desc=0x0000
_gl4es_glDrawElements type=0x1e sect=1 desc=0x0000
_gl4es_glEnable      type=0x1e sect=1 desc=0x0000
_gl4es_glDisable     type=0x1e sect=1 desc=0x0000
_glBlendFunc         type=0x01 sect=0 desc=0x0200
_glDisable           type=0x01 sect=0 desc=0x0200
_glEnable            type=0x01 sect=0 desc=0x0200
```

The GL4ES wrapper symbols are defined in the executable (`N_SECT`); the unprefixed core symbols are undefined imports (`N_UNDF`). OSG therefore mutated native GLES state directly while GL4ES owned program conversion and draw submission. The smoke draw's blend enable was invisible to GL4ES.

## R2 coverage limit

The file contains one effective exterior fog generation only. Projection sampling began at selected/far 7168 and then recorded adjacent slider-transition values before its bounded budget exhausted. Fog intent, OSG application, GL4ES receipt, and eight of nine sampled live program consumers agree on start 2007.04, end 7168, scale 0.000193762404, and color `0.960784,0.921569,0.878431,1`. Program 81 has no builtin fog locations, but its render purpose is not established by this capture.

Because no second materially different effective view-distance generation exists, R2 does not authorize a distance/fog/content/cull/clear/depth correction.

## Correction-build disposition

The proven smoke/particle split-state boundary produced narrow correction commit `1625713b949ddb0cde5471feead75f29fedadfaa`. Its only authorized Fast run, `32634038454`, passed source/bootstrap and ordered patch application but missed the vcpkg and qualified incremental caches. GitHub terminated the job at the two-hour limit during dependency preparation, before production OpenMW compilation. No corrected IPA or device comparison exists.
