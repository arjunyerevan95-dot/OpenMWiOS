# WO-032 R1 targeted renderer evidence

## Question

What alpha/blend/depth/program state is actually applied to one defective foliage draw and one defective chimney-smoke draw, compared with a correct opaque control draw?

## Diagnostic contract

For each target, correlate:

`OpenMW image identity/hash -> OSG GL texture name -> GL4ES applied draw`

The applied record contains program and texture IDs, target/category, blend enable/functions, alpha-test function/reference, depth-test/write/function, fog values, FPE/default-fragment flags, and whether the native fragment source contains discard or an alpha write.

OpenMW's targeted shader-state record includes finalized alpha function/reference, alpha blend/additive/soft-particle intent, render bin/hint, alpha-to-coverage, and coverage adjustment.

## Required device observations

- Defective foliage/hanging-moss visible.
- Defective chimney smoke visible (mandatory; spell fire is optional).
- Correct opaque exterior control visible in the same session.
- Share the bounded `Documents/OpenMW/renderer-diagnostic.jsonl`.

## Result

Reached by replacement diagnostic Fast run `32627872506` and the device capture summarized in [device-capture-analysis.md](device-capture-analysis.md).

- Foliage target: hit, texture 292 / program 21.
- Chimney-smoke target: hit, texture 129 / program 9.
- Opaque control: hit, texture 134 / program 12.
- Chimney smoke is a DXT5 translucent asset. Its shader writes alpha and contains discard; OSG's selected semantics produce standard alpha factors and disabled depth writes. The applied GL4ES draw nevertheless reports `blend=0`.
- The diagnostic executable defines `gl4es_glEnable`, `gl4es_glDisable`, `gl4es_glBlendFunc`, and `gl4es_glDrawElements`, while importing native `_glEnable`, `_glDisable`, and `_glBlendFunc` as undefined symbols.

The first proven smoke/particle divergence is split state ownership: pinned OSG's direct core state calls bypass the existing GL4ES-resolved entry-point path, so GL4ES submits a draw without observing OSG's blend enable. Correction commit `1625713b949ddb0cde5471feead75f29fedadfaa` routes those OSG core mode/blend calls through GL4ES only for Apple manual-init builds.

The first correction Fast run `32634038454` missed both the vcpkg and qualified incremental caches, rebuilt GL4ES, and was terminated at GitHub's two-hour limit during dependency preparation. Production OpenMW compilation never started and that run produced no corrected IPA.

Amendment 2 authorized only a Fast-job timeout increase from 120 to 180 minutes and one replacement build of the byte-for-byte unchanged correction. Run `32649331052` succeeded and produced the exact device candidate recorded in [amendment2-device-capture.md](amendment2-device-capture.md). The fresh device capture again dynamically correlated chimney smoke, now as texture 115 / program 9. Four representative draws all retained `blend=0` with factors `770,771,770,771`, depth writes disabled, and fragment discard/alpha output present. The supplied matching screenshot shows no visible smoke improvement.

The candidate correction therefore did not alter the invalid applied blend state and is not qualified. WO-032 stops at the Amendment 2 falsification boundary; further renderer correction is not authorized here.

The captured foliage target is already opaque at the OpenMW/OSG/shader boundary. Its distinct root cause remains unresolved and is not corrected by inference.
