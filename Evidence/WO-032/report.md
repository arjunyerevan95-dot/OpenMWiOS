# WO-032 execution report

## Outcome

**BLOCKED / STOPPED — Condition G, diagnostic build budget exhausted.**

The targeted R1/R2 diagnostic implementation and deterministic patch stacks were prepared on commit `4b626d80dcf58bc5768c71f2e043c9f4edec6b07`. The one authorized diagnostic Fast run failed during cheap Python regression validation, before production compilation. No IPA, device launch, or renderer evidence was produced, so no renderer correction is authorized.

## Execution identity

- ControlPlane issue commit: `9100edc9ee3f9dc89ec6adafc28ec72a77ed48a8`.
- Investigation continuation / execution baseline: `626b3321ee7ce83f82d22a707dfa4f9177cf6fff`.
- Branch: `codex/wo32-targeted-renderer-boundary`.
- Diagnostic implementation commit: `4b626d80dcf58bc5768c71f2e043c9f4edec6b07`.
- PR: `https://github.com/arjunyerevan95-dot/OpenMWiOS/pull/18`.
- Fast run: `32623652029`.
- Job: `97155562871`.
- Run window: 2026-08-23 06:43:03Z–06:44:53Z (1m50s).
- Full Qualification: not run.

## Implemented diagnostic model

R1 late-gates applied draw records to dynamically identified foliage/hanging-moss, chimney-smoke, and opaque-control textures. Hash-to-GL-name correlation is retained through the existing OpenMW/OSG bridge. Each target has an explicit armed-miss summary, a first-hit summary, and a four-record cap. Broad early `category=-1` uploads cannot consume this budget.

R2 creates a generation only when OpenMW exterior fog/view-distance intent changes. GL4ES records a unique program/generation only after mode/start/end/color were received and the live applied values match that generation. OpenMW also records projection, terrain cull distance, active grid/cell activity, clear color/mask/depth, and sky-blending changes. Details are in [sampling-model.md](sampling-model.md).

No diagnostic code mutates renderer state. No touch, data path, dependency revision, workflow, or canonical ControlPlane file changed.

## Local gates

- Focused WO-031 + WO-032 tests: 19 run, 17 pass, 2 skipped for lack of a C compiler on the Windows host; no failure.
- Reverse checks for cleaned GL4ES `0007` and OpenMW `0014`: pass.
- Reverse checks for new GL4ES `0008` and OpenMW `0015`: pass.
- `git diff --check`: pass.
- Existing dependency-patch whitespace defects were removed without changing patch semantics; CI subsequently confirmed every ordered dependency patch applied successfully.
- Touch source diff: empty.

The two compiler-backed fixture tests were skipped locally. This mattered because their patch-reconstruction helper was the later CI failure boundary.

## CI failure boundary

Run `32623652029` passed:

- source bootstrap and pinned revision checks;
- shell syntax and shellcheck;
- Python syntax;
- data/workflow validation;
- source snapshots;
- all OpenMW patches `0001`–`0015`;
- all GL4ES patches `0001`–`0008`.

The regression suite ran 131 tests and failed exactly two:

- `test_wo31_renderer_diagnostic_channel...test_gl4es_translation_unit_executes_app_bridge_and_writes_gl4es_r2_records`;
- `test_wo32_targeted_renderer_diagnostics...test_gl4es_fixture_proves_target_and_two_generation_gates`.

Both fail in the same test-only `apply_file_patch` assertion. WO-032 was required to remove trailing whitespace from embedded dependency patch payloads. Blank unified-diff context lines therefore became empty lines. The helper handles lines beginning with context/add/remove prefixes but does not treat an empty patch line as blank source context, so its cursor falls behind and the next context assertion fails. The real source patch stack passed completely, proving this is a fixture parser incompatibility rather than a dependency patch application failure.

Production compile/link, package validation, IPA upload, and device testing were all skipped. The failure diagnostics artifact is `OpenMW-iOS-fast-failure-44`, ID `9489106339`, digest `sha256:99b85d6fbf6f4981ead3e1fb07c58c76fb23a74e5ef0c98c36155673174b9045`.

## Build budget and disposition

- Authorized diagnostic Fast builds: 1.
- Consumed: 1 (`32623652029`).
- Authorized correction Fast build: conditional on causal device evidence; not reached and not used.
- Additional diagnostic build: prohibited after the one diagnostic budget was consumed.
- Renderer correction: none.
- Device candidate/evidence: none.

The narrow repair would be to teach both test helpers that an empty embedded-diff line represents blank context (advance and preserve one blank source line), then rerun the compiler-backed fixtures. WO-032 does not authorize another diagnostic run, so that repair is not applied or built here.

## Renderer conclusion

R1 and R2 remain unproven. There is no new device evidence and no basis for an alpha/blend/fog/content/cull/clear correction. The accepted WO-029 product baseline is unchanged.

## Required orchestrator review

WO-032 stopped at Condition G. The orchestrator must decide whether to amend/supersede the order with a fresh build budget for the narrow fixture-parser repair or choose another disposition. This report does not authorize either action.
