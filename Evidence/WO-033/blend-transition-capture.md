# WO-033 compact blend-transition capture

Source attachment SHA-256: `66F107E61B053DF7CA4A3D2C409081FBC9F9E9205E661DE80BC4C4D3EAE14F5D`

Session: `A0DCEE5B-3A9B-4AD0-B205-B7E500BC90CD`

The source JSONL contains 438 bounded records. Relevant family counts:

- `r1.blend.transition / osg`: 112
- `r1.blend.transition / gl4es`: 16
- `r1.draw.targeted / gl4es`: 12 total, including four chimney-smoke target draws
- transition-family budget marker: 1 at exhaustion

Representative first retained target sequence:

| Sample | Sequence | Source/site | Decisive state |
|---:|---:|---|---|
| 259–290 | 1617–1648 | OSG `State::applyMode` | `GL_BLEND`, `requested=1`, `valid=1`, `last=1`, `issued=0`, state `0x1140ec000`, context 0 |
| 291 | 1649 | OSG `BlendFunc::apply` | `src_rgb=770`, `dst_rgb=1`, same State/context |
| 292 | 1650 | OSG `State::applyMode` | still `requested=1,last=1,issued=0` |
| 293 | 1651 | OSG `BlendFunc::apply` | `src_rgb=770`, `dst_rgb=771`, same State/context |
| 294–302 | 1652–1660 | OSG `State::applyMode` | still `requested=1,last=1,issued=0` |
| 303 | 1661 | GL4ES `glDrawArrays.intake` | `blend=0`, `glstate=0x10a301968`, no list pending/active |
| 304 | 1662 | GL4ES `glDrawArrays.capture` | `blend=0`, same state/thread |
| 305 | 1663 | GL4ES `glDrawArrays.intercept` | `blend=0`, same state/thread |
| 306 | 1664 | GL4ES `glDrawElementsCommon` | `blend=0`, same state/thread |
| 307 | — | GL4ES target draw | texture 115, program 9, target 2, factors `770,771,770,771`, depth write 0, fragment alpha/discard present |

The sequence repeats at 1665–1680 and again at 2381–2444. No retained `proxy_glEnable(GL_BLEND)` ingress, later disable, different GL4ES state, active list, or replay transition occurs between the OSG request and target draw.

Classification: **OSG cache match suppresses the GL4ES reconciliation call**. This is the first observable invalid boundary and directly explains why the target draw retains `blend=0` despite the requested translucent state and correct blend factors.

The full attachment is referenced rather than committed to avoid duplicating raw diagnostic output.

## Correction comparison

Correction attachment SHA-256: `6D57F23FEE227608A5285BC52BB0AB386BB4E7ABEE7EB9F9787931E39E8B2C3B`

Session: `9504FA5C-CF45-46D9-908E-2F1838B8B0B9`

The correction JSONL contains 445 bounded records. Aggregate results:

- OSG cache-match reassertions: 55
- GL4ES `proxy_glEnable(GL_BLEND)` ingress: 55
- `glDrawArrays.intake`: 3 with `blend=1`, 0 with `blend=0`
- `glDrawArrays.capture`: 3 with `blend=1`, 0 with `blend=0`
- `glDrawArrays.intercept`: 3 with `blend=1`, 0 with `blend=0`
- `glDrawElementsCommon`: 3 with `blend=1`, 0 with `blend=0`
- target 2 records: 4 with `blend=1`, 0 with `blend=0`

Representative corrected sequence:

| Sample | Sequence | Source/site | Decisive state |
|---:|---:|---|---|
| 265 | 2380 | OSG `State::applyMode` | `requested=1,valid=1,last=1,issued=1,reasserted=1`, manual GL4ES route |
| 266 | 2381 | GL4ES `proxy_glEnable(GL_BLEND)` | `previous=1,current=1`, same thread, no active/pending list |
| 309-312 | 2424-2427 | GL4ES intake/capture/intercept/common | `blend=1` throughout on `glstate=0x10a2dd968` |
| 313 | — | GL4ES target draw | texture 129, target 2, program 9, `blend=1`, factors `770,771,770,771`, depth write 0 |

Before correction, the target draw retained `blend=0`; after correction, every target record retained `blend=1`. This is the expected causal transition. The raw attachment remains external and is referenced by hash rather than duplicated.
