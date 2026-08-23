# WO-032 R2 targeted renderer evidence

## Question

After the accepted GL4ES exterior fog receipt, does each live exterior program consume the matching fog state, and do projection/cull/content/clear boundaries remain coherent at two selected view distances?

## Diagnostic contract

For every matching exterior generation, correlate:

- OpenMW selected view distance, near/far projection, terrain cull distance, FOV/aspect/resolution, reversed-Z state;
- OpenMW fog start/end/color and OSG state application;
- GL4ES received mode/start/end/color;
- unique live GL4ES program consumption, including builtin fog uniform locations and applied values;
- exterior active grid and cell load/unload activity;
- camera clear color/mask/depth and sky-blending state.

The program record cannot be emitted until all four GL4ES fog components have been received and exactly match the current armed OpenMW exterior generation.

## Required device observations

- Reproduce the white/blank distance region and sharp blue horizon band.
- Capture one exterior view at the first selected view distance.
- Change to a materially different view distance and capture the equivalent boundary again.
- Share the bounded `Documents/OpenMW/renderer-diagnostic.jsonl`.

## Result

Not reached. Fast run `32623652029` stopped in cheap Python validation before production compilation. The ordered GL4ES/OpenMW patch-stack checks passed, but no IPA or device JSONL exists. R2 remains unlocalized; no renderer correction was made.
