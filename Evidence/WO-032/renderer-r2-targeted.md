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

Partially reached by replacement diagnostic Fast run `32627872506`; see [device-capture-analysis.md](device-capture-analysis.md).

- One effective fog generation was captured at selected/far 7168.
- OpenMW intent, OSG application, GL4ES receipt, and eight of nine sampled live programs agree on fog start/end/color/scale.
- Program 81 has no builtin fog locations, but this capture does not establish its render purpose.
- The bounded projection records following 7168 are adjacent slider-transition values from the same max-distance test, not a second deliberately selected and stable view-distance generation.

The mandatory two-distance comparison is absent. R2 therefore remains insufficient for a correction; no distance, fog, content, cull, sky, clear, or depth behavior was changed.

The user explicitly confirmed that all supplied distance observations used maximum view distance. The failed final correction build concerned R1 blend-state ownership only and does not change this R2 result.
