# WO-033 device capture

## Amendment 2 diagnostic candidate

- Fast run: `32742643722`
- Candidate: `fd300ba12351252ece9e7b481c0b2d366228f9e8`
- Artifact: `OpenMW-iOS-fast-54`, ID `9528845874`
- Artifact digest: `sha256:eb8c96d038e8e67a7f22b07b0c58f08e2ef8c4f7898b085c370b4acea153c306`
- IPA SHA-256: `9A5CD26DAAE7FF5C4B56B630EB5BAE148A2A80B120D2466B415BA9C89E87ED5B`
- Executable SHA-256: `05C86BB43574092B1D0AF26E7517DCFF1E576ABAC9AAC1D84B59F255FCED17FB`
- Mach-O UUID: `98B76201-B444-3844-8AB2-E5DF9B61B953`
- Installation/launch: passed; the user reached the representative Seyda Neen chimney-smoke view.
- Visible result: unchanged opaque/blocky smoke, as expected for a diagnostic-only candidate.
- Crash/termination: no crash reported.

## Supplied evidence

- Attachment: `renderer-diagnostic.jsonl`
- Attachment SHA-256: `66F107E61B053DF7CA4A3D2C409081FBC9F9E9205E661DE80BC4C4D3EAE14F5D`
- Attachment size: 143,357 bytes
- Session: `A0DCEE5B-3A9B-4AD0-B205-B7E500BC90CD`
- Records: 438
- Screenshot SHA-256: `9E64E33151053ADF5E0EA40D3F631570644F1C48FD54CBFADE30E51B30ADBDDA`
- Screenshot size: 203,273 bytes

The runtime dynamically identified `textures/tx_smokealpha00a.dds` as target 2 / texture 115. Four representative target draws recorded:

- program 9;
- standard alpha factors `770,771,770,771` (`SRC_ALPHA`, `ONE_MINUS_SRC_ALPHA`);
- depth test enabled and depth writes disabled;
- fragment discard and alpha output present;
- `blend=0` at `glDrawElementsCommon`.

Immediately before those draws, the bounded transition ring repeatedly recorded the same OSG `State` (`0x1140ec000`, context 0) requesting `GL_BLEND=1` while its mode cache reported `valid=1,last=1,issued=0`. The ensuing GL4ES intake, capture, intercept, and common-draw records all used the same thread and `glstate=0x10a301968`, with no active/pending render list and `blend=0` throughout. No retained GL4ES enable ingress or replay transition intervened.

This identifies the first observable invalid boundary as the OSG cache gate: OSG suppresses the requested enable because its cache says blending is already on, while the GL4ES state used by the actual draw says it is off. The trace does not support a factor, target, different-context, or render-list-replay correction.

## Correction qualification

- Fast run: `32771773194`
- Candidate: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`
- Artifact: `OpenMW-iOS-fast-55`, ID `9538962155`
- Artifact digest: `sha256:1af36e00a09f9056bf1bb63eaf0c4c09a35e6ed14155009425913717f9840be7`
- IPA SHA-256: `34EB8106C60138F30DA8B59083CA026FDA013F68870DDC658C1584B6E939AC4E`
- Executable SHA-256: `C759B9D09DF6A2CFFE7657839BD3DB25999A399743E811A7846A406A5826874C`
- Installation/launch: passed.
- Exterior traversal/HUD/landscape: passed; no crash reported.

Correction trace:

- Attachment SHA-256: `6D57F23FEE227608A5285BC52BB0AB386BB4E7ABEE7EB9F9787931E39E8B2C3B`
- Attachment size: 149,924 bytes
- Session: `9504FA5C-CF45-46D9-908E-2F1838B8B0B9`
- Records: 445
- Target: `textures/tx_smokealpha00a.dds`, target 2 / texture 129
- OSG reassertion records: 55
- GL4ES enable-ingress records: 55
- Target records: 4 with `blend=1`; 0 with `blend=0`

Representative samples 265-313 show the corrected chain: OSG records `issued=1,reasserted=1`; GL4ES receives `proxy_glEnable(GL_BLEND)`; intake/capture/intercept/common draw retain `blend=1`; and the target draw uses the intended alpha factors with depth writes disabled.

Visible result: **passed**. The user reported that smoke, spell effects, and foliage transparency were fixed. The eight screenshots below show correct alpha cutouts and blended effects while the existing HUD and full landscape presentation remain intact:

| Screenshot | Size (bytes) | SHA-256 |
|---|---:|---|
| `1-Photo-1.jpg` | 224,490 | `2D97DDB60711A29BDE2031C557CCB0CFED9EDF32FF8682B8B222E6E1D9DE32ED` |
| `2-Photo-2.jpg` | 198,058 | `A2DD5D06B3A81BE1DD6D89AD92DD2771003311FE64D92D2356B26C565E321E77` |
| `3-Photo-3.jpg` | 176,441 | `FA7EB6CE93E30E582CDB25474A5CC86074A0D81F6FD0C92D94D92FB474F9B16A` |
| `4-Photo-4.jpg` | 175,439 | `E4235E45C13E06A387540EF90F979673B367AC3E34E7B61D0530BCB87D629829` |
| `5-Photo-5.jpg` | 244,284 | `2FDBC4D1EA185F84F2AF347E0E824C87C95FD1A8CFE27BC8579FA77F68A6E1CE` |
| `6-Photo-6.jpg` | 170,980 | `CA4EC3D53996399C0E5B2D7FFA94B6A8F4F6A22A9131CF51C31DFF1EE2E6FEEC` |
| `7-Photo-7.jpg` | 199,506 | `A62DA12AF29C727F5F6854A509B16E4766966D9E93EC1CDB136183CF0D244D7D` |
| `8-Photo-8.jpg` | 202,228 | `9D5671A86A43B5837126F2D9126340D45F7E2822C8C71AEDE03FF8964B2B2FB3` |

The distance/horizon defect remains visible and is deferred because it is outside WO-033 scope.
