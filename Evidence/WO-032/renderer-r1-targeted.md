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

Not reached. Fast run `32623652029` stopped in cheap Python validation before production compilation. The ordered GL4ES/OpenMW patch-stack checks passed, but no IPA or device JSONL exists. R1 remains unlocalized; no renderer correction was made.
