# WO-029 Execution Report

## Outcome

Status: **IN PROGRESS — causal boundary proven; corrected build pending**

WO-029 established and reverified the rejected candidate's exact CI artifact, IPA, executable, installed bundle, and Mach-O identities. Thirteen August 22 reports match the rejected executable UUID exactly and cover launch, `New Game`, and menu/overlay-action contexts.

All thirteen converge at `-[OpenMWTouchOverlay drawRect:] + 0x35c`. Nine are invalid-address `objc_msgSend` faults; four explicitly report that an unrelated dispatch/Metal object received `imageWithTintColor:renderingMode:`. Retrieved startup evidence correlates a MENU overlay press to the following matching report.

## Causal model

The rejected touch icon cache stored autoreleased `UIImage` pointers in a process-lifetime raw-pointer array. The file is compiled without ARC. When the autorelease pool drained, later `drawRect:` calls messaged dangling/reused addresses. That produces the two observed manifestations: invalid-address `objc_msgSend` and unrecognized selectors on objects subsequently allocated at those addresses.

The crash reports, exact selector, common instruction, compile mode, and checked-out source jointly prove this model. The launch, `New Game`, and overlay-action paths are `CONVERGED` at this ownership defect while retaining distinct surrounding lifecycle contexts.

## Corrections

One bounded runtime correction changes the image construction from autoreleased `+[UIImage imageWithData:]` to owned `[[UIImage alloc] initWithData:]` and releases the temporary `NSData`. A focused source regression test prevents restoring the non-owning cache pattern.

No touch behavior, mappings, layout, opacity, renderer, data path, dependency, cache, or workflow behavior changed.

## CI/build status

- Focused touch suite: 20 run, 19 passed, 1 compiler-dependent skip
- Aggregate suite: 106 run, 100 passed, 4 compiler-dependent skips, 2 Windows-only shell execution errors unrelated to WO29
- Diagnostic-only Fast build: not needed and not run
- Corrected Fast build: pending
- Full Qualification: not run
- Cache architecture: unchanged

## Acceptance status

Local correction gate reached. Production compilation/package and corrected device acceptance are pending.

## Required next execution step

1. Commit and push only the bounded runtime/test/evidence change.
2. Run one corrected Fast Development build and verify production compile/package identity.
3. Install the exact artifact.
4. Execute WO29's controlled launch, `New Game`, overlay, early-game, data-path, and renderer regression matrix.

No engineering scope beyond WO-029 is authorized.
