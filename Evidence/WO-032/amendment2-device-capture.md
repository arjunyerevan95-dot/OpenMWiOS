# WO-032 Amendment 2 device capture

## Candidate identity

- Correction source commit: `1625713b949ddb0cde5471feead75f29fedadfaa`.
- Timeout-only build commit: `c9161e579ff1814cc7fc5c86fb63a9ef177502f3`.
- Fast run: `32649331052`.
- Artifact: `OpenMW-iOS-fast-51`, ID `9496797285`, digest `sha256:4c358ee09b35270cdc3d39b1d5887ca5e6331c0a9bd140ef728cbdf3461101b4`.
- IPA SHA-256: `57B4A011E29C9116E451877169351B0A6A5D5B063AE843605CE0C0B4D4D031B7`.
- Executable SHA-256: `FC4A34EB321633BBEE4DD47F8AB3E8E0E3C3347091EA4B56CC415C2C6BB4CE95`.
- Mach-O UUID: `FAC81B2E-2852-37AF-A602-DED71C652E56`.

## Capture identity

- Device JSONL SHA-256: `E0289184EEE32FCA9DF38C66239EF71B061713F182F94646CE1032AA8ACA0AAE`.
- JSONL size/records: 97,681 bytes / 309 records.
- Session: `5ED135B0-B449-4845-8A83-2251FF810A03`.
- Screenshot SHA-256: `F0CCBDC60A0F44D4FDE01F3788D5D5FDCE70E417727518EE8D198CACF596D15B`.
- External attachment source: `A58D18DC-EEC3-48AF-9274-CA553B1ABD6D` in the Codex remote-attachment store.

The screenshot reproduces the mandatory Seyda Neen chimney-smoke view. The smoke cards remain visibly blocky/opaque against the sky. OpenMW reached the exterior with HUD, native landscape presentation, and the diagnostic channel functioning; no launch crash was reported. Separate indoor, water, touch-action, and short-tap Menu regression observations were not supplied in this capture and are therefore **NOT RECORDED**.

## Representative smoke draw

The fresh run dynamically identified `textures/tx_smokealpha00a.dds` as texture 115 and program 9. Samples 259, 262, 276, and 277 all report the same applied state:

```text
generation=1;program=9;texture=115;category=2;target=2;count=276;blend=0;blend_func=770,771,770,771;alpha_test=0;alpha_func=516;alpha_ref=0;depth_test=1;depth_write=0;depth_func=515;fog=1;fog_start=2007.04;fog_end=7168;fog_color=0.960784,0.921569,0.878431,1;has_fpe=0;default_fragment=0;fragment_has_discard=1;fragment_writes_alpha=1
```

The target-hit summary is:

```text
target=2;status=hit;texture=115;program=9;generation=1
```

## Result

The Amendment 2 acceptance prediction is falsified:

- the exact correction compiled, linked, packaged, installed, and ran;
- GL4ES still observed `blend=0` for every captured representative smoke draw;
- the intended standard alpha factors remained present;
- depth writes remained disabled and the fragment program still contained discard and alpha output;
- the visible smoke remained blocky.

The prepared OSG routing correction is therefore **not device-qualified** and must not be accepted into the product baseline on this evidence. Amendment 2 requires an immediate stop when GL4ES still records disabled blending or the visible smoke does not improve. No second build or follow-on renderer change is authorized.
