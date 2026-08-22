# WO-029 Execution Report

## Outcome

Status: **EXECUTION COMPLETE / STRONG DEVICE PASS; FORMAL ATTEMPT COUNTS NOT RECORDED**

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
- Correction commit: `45c1d8c696fb328d977893b79efc78689a3f4d08`
- Corrected Fast run: `32548876888` (`success`)
- CI validation step: 109 tests completed successfully
- Production compile/link/package: passed
- Artifact: `OpenMW-iOS-fast-31` (ID `9470501854`)
- Executable SHA-256: `6FF52E861FF44D4C4449E1A82481EE7F52B515932A56279EB5C057F9E740F0C2`
- IPA SHA-256: `E295561EE9BF1F52A7337C6AACFE7777F530E9E394462F3C143DEB98E14BDD63`
- Corrected Mach-O UUID: `52739477-31F4-3693-9D6F-30366E3D640D`
- Corrected artifact dSYM/link map: absent
- All three qualified caches missed; cache architecture was unchanged and no duplicate build ran
- Full Qualification: not run
- Cache architecture: unchanged

## Acceptance status

The user installed the exact corrected IPA and explicitly reported a pass: the app boots normally and the controls work. The observed session reached indoor and Seyda Neen exterior gameplay, with no user-observed crash or jetsam, and nine screenshots demonstrate sustained rendering, traversal, HUD, overlay, weapon/combat, and scene changes. The rejected candidate's immediate launch/menu/action crash behavior did not recur during this session.

The exact Phase 5 quotas were not logged: the consecutive-launch count, fresh `New Game` count, and per-control enumeration are `NOT RECORDED`. A post-test crash pull was also unavailable because usbmux reported no connected device after the session. The evidence is a strong corrected-device pass, but the worker does not self-declare canonical acceptance of the unrecorded numeric matrix.

No prohibited subsystem changed. The user-requested icon transparency and control resize/reposition customization, plus observed foliage-alpha/cutout, missing distance fog/horizon, and transient blocky combat-effect issues, are recorded as out-of-scope observations only.

## Stop / review boundary

WO-029 execution stops at the orchestrator-review gate. The bounded correction is proven and positively device-observed; orchestrator review is required because formal attempt counts and the independent post-test crash inventory were not captured. No UX/renderer follow-up was begun, no canonical ControlPlane file was modified, and no subsequent work order is authorized.
