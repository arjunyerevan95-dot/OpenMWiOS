# WO-033 blend-transition model

## Target and observation contract

The representative target remains the runtime-discovered chimney-smoke texture (`OPENMW_IOS_RENDERER_TARGET_CHIMNEY_SMOKE`). No texture name, GL texture ID, or program ID is hard-coded into the transition tracer.

After OSG binds and identifies that target, blend events enter a 48-event in-memory ring. The ring is emitted only when the same dynamically identified target reaches either `glDrawElementsCommon` or the native draw inside `draw_renderlist`. Output remains subject to the existing 256 KiB file cap and a 128-record `r1.blend.transition` family budget.

Every retained event carries a process-monotonic sequence, thread identity, site, requested/current values where applicable, OSG `State` plus graphics-context identity, or GL4ES `glstate` plus render-list/FPE identity.

## Ordered alternatives

1. **Patched OSG route absent or not exercised**
   - OSG reports an issued `GL_BLEND=1` decision but no corresponding GL4ES ingress exists before the target draw.
   - The exact linked executable must separately prove whether the manual-route branch is present.
2. **Enable followed by disable**
   - The same GL4ES `glstate` receives `requested=1,current=1`, later receives `requested=0,current=0`, and the target draw reports `blend=0`.
3. **Different GL4ES state/context**
   - The enable and target draw carry different `glstate` identities or thread/context evidence.
4. **Render-list capture/replay mismatch**
   - Intake/capture records a different blend value or state identity from `draw_renderlist.native-draw` / `glDrawElementsCommon`.
5. **Consistent path**
   - OSG issues enable, the same GL4ES state receives and retains it, and the target draw reports `blend=1`. This would falsify the tracked state-transition candidates and require stopping unless another first invalid boundary is directly present in the bounded record.

## Deterministic coverage

`validation/fixtures/wo33_blend_transition_fixture.c` and `validation/test_wo33_blend_transition_diagnostics.py` cover enable-only, enable-then-disable, different-context, missing-route, and render-list/replay classifications. The source-level tests also check target arming, ring/output caps, route/factor fields, phase markers, and absence of diagnostic renderer mutation.

## Status

Runtime classification is **NOT OBTAINED** because run `32701930506` failed during patch bootstrap before compilation. No causal alternative can be selected from source evidence alone.
