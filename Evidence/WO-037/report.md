# WO-037 Execution Report

Status: **BLOCKED — STOP CONDITION B / AMENDMENT 1 RUNTIME DIAGNOSTIC INSUFFICIENT**

## Scope

WO-037 attempted to attribute, independently:

1. abrupt near-black distant silhouettes; and
2. the blue horizontal band plus pale/white horizon region.

No renderer correction was selected or implemented. The accepted WO33 product behavior remains unchanged. Canonical `Documentation/CURRENT_STATE.md`, `WorkOrders/`, and `Decisions/` were not modified.

## Amendment 1 implementation

- Continuation point: `e6a6a5b5f9b63b985d93068fb16feaacbb5f4737`.
- The invalid `LOAD_GLES_FPE(glReadPixels)` acquisition was replaced only with pinned-source-correct `LOAD_GLES(glReadPixels)`.
- The request trigger, target coordinate, budgets, two bounded 1x1 per-draw samples, bounded pre-swap sample, record schema, and renderer semantics were not changed.
- Deterministic validation now rejects `LOAD_GLES_FPE(glReadPixels)` and `fpe_glReadPixels`, requires the ordinary loader contract, and applies the complete ordered GL4ES patch stack to pristine pinned GL4ES `c9895df34cd466c23bc60c2bd3db3d87e98fcbe7`.
- Repair commit: `9f5cfee61a450d628901d8bc08da1ddaf441fbfb`.

## Validation

- Focused WO33 + WO37 validation: 24 tests, 22 passed, 2 compiler-dependent skips.
- Aggregate Windows-host validation with pinned dependency checkout available: 155 tests, 145 passed, 8 skipped, 2 existing `test_verify_linked_product` host errors (`WinError 193` from executing a Unix script on Windows). No product assertion failed.
- Complete ordered GL4ES patch reconstruction: pass.
- `git diff --check`: pass.
- Python syntax compilation of the strengthened test: pass.
- Exact diagnostic-source comparison proved the GL4ES loader line was the only runtime diagnostic semantic change from `7dc76a962fb5cd54494a41296b138badee15038a`.
- Color/fog/scene rendering and all non-diagnostic renderer behavior were untouched.

## Replacement Fast Development run

- Run: `33019021667` — success.
- Source commit: `9f5cfee61a450d628901d8bc08da1ddaf441fbfb`.
- Artifact: `OpenMW-iOS-fast-60`, ID `9628038289`.
- Artifact digest: `sha256:489e24849b01f88a47cfed96b69349d1c71434b325194b9a7d8bd239ce2e7259`.
- Executable SHA-256: `b98a716df7bfce8ef64abcd2782ed2be92aae19cd1b01c7721efadb8d71c661c`.
- Mach-O UUID: `2C5B768F-BFA4-3636-9918-6859DB68E285`.
- IPA SHA-256: `898ba0f25bb6b1a76050fddb0558721a50adf2a08e1f067e5d670d6ae10ec96b`.
- Production compile/link, bundle validation, packaging, and artifact upload: pass.
- Workflow duration: approximately 1 hour 41 minutes 37 seconds.
- Artifact timings: configure/dependencies 2672 seconds; production compile/link 3087 seconds.
- Source-download cache hit: true. Cache-restore steps completed successfully; the artifact fingerprint file did not serialize boolean values for vcpkg/build-state hits.
- Full Qualification: not run and not authorized.

## Physical-device result

The replacement IPA installed and rendered normally, but the request-gated target attribution did not arm in two fresh device sessions:

- Session `1FCD125A-6ADC-45DA-88E2-ABA46D46B974`, JSONL SHA-256 `013ac7a91762a5a01eb497662fd99e0a3dd568392cb4abddae4868a40940b791`: startup recorded `target_request=none`; zero `r3.*` records.
- Session `DEA6C1B8-C370-4561-B752-013882C79087`, JSONL SHA-256 `d3526ac3be040da5230d9f546b1ee77a275c84dec7d659a61af12c55bf0a8e2a`: startup recorded `target_request=none`; zero `r3.*` records.

The second attempt has independent iOS Files evidence that, before the new log was written, a 21-byte UTF-8/LF file named exactly `renderer-target-request.txt` containing `wo37-black-silhouette` was present beside `renderer-diagnostic.jsonl` in the OpenMW Documents folder. The tester's placement and filename were correct. See [request-loader device evidence](request-loader-device-evidence.md).

The screenshots contain suitable hard-black targets centered under the crosshair, but no OSG candidate, GL4ES draw, target-pixel depth/color, or presented-pixel `r3.*` record exists. The required target/draw/pixel correlation therefore remains unavailable.

## Causal result and correction gate

- Black silhouettes: **unclassified**.
- Pale/white region: **unclassified**.
- Blue band: **unclassified**.
- Drawn-pixel versus coverage/composition boundary: **not proven**.
- Renderer correction: **not authorized and not attempted**.

The loader compile defect was repaired successfully, but the runtime request-file loader failed to observe a correctly placed request. Amendment 1 explicitly forbids diagnostic redesign and authorizes no third diagnostic build. Continuing would require orchestrator review and a new amendment or work order.

## Build budget

- Diagnostic Fast dispatches used: 2 (original failed build plus the single Amendment 1 replacement).
- Correction IPA dispatches used: 0 / 1; reserved correction build was not eligible because attribution never armed.
- Further diagnostic replacement runs authorized: 0.
- Full Qualification: 0.

## Stop condition

**B — target/draw/pixel correlation insufficient**, at the Amendment 1 runtime-diagnostic-insufficient stop boundary.

Strongest conclusion: the native GLES loader repair is build- and package-correct, but WO-037's request-file activation contract is not operational on the physical device even when the request file is demonstrably named and placed correctly. No conclusion about the renderer defect itself can be promoted from this run.

Unlisted report Gist: `https://gist.github.com/arjunyerevan95-dot/d8e93d65c0df86ae40a863d188e8e122`
