# WO-032 Amendment 2 final orchestrator review

- Review date: 2026-08-24
- Disposition: **ACCEPT EVIDENCE / REJECT CORRECTION / CLOSE WO32**
- Worker evidence commit: `164abe4ba2becf46ea043811963ac28195d29bcd`
- Built correction commit: `c9161e579ff1814cc7fc5c86fb63a9ef177502f3`
- Rejected correction source: `1625713b949ddb0cde5471feead75f29fedadfaa`
- Accepted engineering baseline: `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27` — unchanged

## CI and artifact verification

GitHub independently reports run `32649331052` as completed/success at exact head `c9161e579ff1814cc7fc5c86fb63a9ef177502f3`. Dependency preparation, production OpenMW compile/link, bundle/resource validation, package, and upload all passed.

Artifact inventory independently confirms:

- `OpenMW-iOS-fast-51`, ID `9496797285`;
- digest `sha256:4c358ee09b35270cdc3d39b1d5887ca5e6331c0a9bd140ef728cbdf3461101b4`;
- IPA SHA-256 `57B4A011E29C9116E451877169351B0A6A5D5B063AE843605CE0C0B4D4D031B7`;
- executable SHA-256 `FC4A34EB321633BBEE4DD47F8AB3E8E0E3C3347091EA4B56CC415C2C6BB4CE95`;
- Mach-O UUID `FAC81B2E-2852-37AF-A602-DED71C652E56`.

There is no active or queued WO32 run. The evidence-only completion commit triggered no additional CI.

## Source identity verification

The OSG routing patch blob and focused test blob at the built commit are byte-for-byte identical to correction commit `1625713b949ddb0cde5471feead75f29fedadfaa`. The only authorized Amendment 2 implementation delta was `.github/workflows/ios-fast.yml` job `timeout-minutes: 120` to `180`.

This rules out a stale or wrong-source artifact explanation. It does not by itself prove that the patched conditional branch was exercised at runtime.

## Device falsification

The exact IPA reached the Seyda Neen exterior and dynamically correlated `textures/tx_smokealpha00a.dds` as texture 115/program 9. Device file identity is SHA-256 `E0289184EEE32FCA9DF38C66239EF71B061713F182F94646CE1032AA8ACA0AAE`, 97,681 bytes, 309 records, session `5ED135B0-B449-4845-8A83-2251FF810A03`.

Samples 259, 262, 276, and 277 all record:

```text
blend=0;blend_func=770,771,770,771;alpha_test=0;depth_test=1;depth_write=0;fragment_has_discard=1;fragment_writes_alpha=1
```

The matching screenshot remains visibly blocky. The correction's acceptance prediction is therefore falsified.

## Architectural review

Codebase Memory located the pinned OSG mode/BlendFunc paths and GL4ES enable/draw paths. Direct source verification establishes:

- GL4ES `gl4es_glEnable`/`gl4es_glDisable` funnel through `proxy_glEnable`;
- for `GL_BLEND`, that function mutates `glstate->enable.blend` only when the value changes;
- the target diagnostic samples that exact field at `glDrawElementsCommon`, immediately on the real draw path;
- GL4ES may batch/intercept draws through render lists before reaching the common draw function;
- OpenMW's top-level CMake option adds `OPENMW_GL4ES_MANUAL_INIT` as a compile definition, but source/patch presence is not proof of a particular runtime call sequence.

The next evidence must distinguish route-not-exercised, enable-then-disable, context mismatch, and render-list/state-replay behavior. No reindexing was needed or performed.

## Final disposition

Accept the WO32 evidence and disciplined stop. Reject the OSG routing correction as a product candidate. Close WO32 as ACCEPTED for partial diagnostic/falsification value only. Preserve foliage and R2 as separate unresolved boundaries.

Issue [WO-033](../../WorkOrders/WO-033.md) as READY. It must trace the bounded blend-state event sequence before applying any new correction.
