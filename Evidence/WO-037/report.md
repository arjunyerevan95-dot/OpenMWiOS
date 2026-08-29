# WO-037 Execution Report

Status: **BLOCKED — STOP CONDITION F / FINAL FAST RUN FAILED BEFORE PRODUCT COMPILATION**

## Scope and authority

WO-037 Amendment 2 continued only on `codex/wo37-distant-pixel-attribution` from exact continuation commit `c890fcda3178c36bc34ae2e99760c971dc9dd4ec`. It replaced the fragile request-file prerequisite with a bounded first-exterior fallback while preserving valid explicit requests and all existing target-pixel attribution semantics.

No renderer correction was selected or implemented. Canonical `Documentation/CURRENT_STATE.md`, `WorkOrders/`, and `Decisions/` were not modified.

## Amendment 2 implementation

- Product commit: `fbddf1f65fef8d3d56e5ee9b3511e0b72198163d`.
- A valid `renderer-target-request.txt` remains authoritative and records activation as `explicit-request`.
- A missing, unreadable, empty, or invalid request selects the fixed label `wo37-auto-first-exterior` and records activation as `auto-first-exterior`.
- The same existing capture arms on the first eligible exterior-fog generation and completes at most once per process.
- Target coordinates, candidate/record budgets, OSG-to-GL4ES/present correlation, bounded 1x1 readbacks, GL state, renderer state, and presentation semantics were unchanged.
- No polling, retry, delay, Files-provider coordination, menu/touch trigger, new storage path, or unbounded logging/readback was added.

Changed product/test files:

- `ios/openmw_ios_renderer_diagnostics.h`
- `ios/openmw_ios_renderer_diagnostics.mm`
- `validation/test_wo37_target_pixel_attribution.py`

## Local validation

- Focused WO33 + WO37 validation: 27 tests, 25 passed, 2 compiler-dependent skips.
- Aggregate Windows-host validation: 158 tests, 148 passed, 8 skipped, 2 existing `test_verify_linked_product` host errors (`WinError 193` from executing a Unix script on Windows). No product or diagnostic assertion failed.
- Complete ordered OpenMW/OSG/GL4ES patch reconstruction: pass.
- Valid explicit-request precedence: pass.
- Missing/unreadable/empty/invalid fallback selection: pass.
- First eligible exterior-only arm and one-shot completion: pass.
- `git diff --check`: pass.
- Python syntax compilation: pass.

## Final authorized Fast Development run

- Run: `33265712820` — failure.
- URL: `https://github.com/arjunyerevan95-dot/OpenMWiOS/actions/runs/33265712820`.
- Exact source: `fbddf1f65fef8d3d56e5ee9b3511e0b72198163d`.
- Job: `Real OpenMW arm64 iPhone development build`.
- Job duration: 2026-08-29 17:28:44Z through 17:37:00Z (8 minutes 16 seconds).
- Source-download cache: hit.
- vcpkg cache: hit.
- Qualified incremental build-state cache: miss.
- Patch bootstrap and source validation: pass, including all ordered OpenMW and GL4ES patches.
- Failed step: `Incremental configure and dependency preparation` after approximately 3 minutes 11 seconds.
- Product compile/link: skipped.
- Bundle/package: skipped.
- IPA upload: skipped.
- Full Qualification: not run and not authorized.

Exact configure failure:

```text
CMake Error at .../osg/CMakeModules/FindGLIB.cmake:91 (file):
  file failed to open for reading (No such file or directory):

    /usr/local/Cellar/glib/2.88.2/lib/glib-2.0/include/glibconfig.h

-- Configuring incomplete, errors occurred!
```

The run restored source and vcpkg caches but not qualified incremental build state. OSG configuration discovered a stale or unavailable Homebrew GLib path, so CMake stopped before any changed product source compiled.

The only uploaded artifact is failure diagnostics:

- Artifact: `OpenMW-iOS-fast-failure-63`.
- Artifact ID: `9718681291`.
- Digest: `sha256:c7cc2fea29cf86ae6e8c16d78ee237c18487ef4e56409ffc6547c49a4966676e`.
- Contents include `configure.log`, cache/source-validation records, and CMake configure diagnostics.

There is **no executable, Mach-O identity, IPA, installation, or device capture** from Amendment 2.

## Attribution result

Because the final authorized run produced no IPA, the auto-first-exterior channel could not be exercised on device:

- Black silhouettes: **unclassified**.
- Pale/white region: **unclassified**.
- Blue band: **unclassified**.
- Drawn-pixel versus coverage/composition boundary: **not proven**.
- Renderer correction: **not authorized and not attempted**.

## Build budget and stop condition

- Total WO-037 Fast dispatches used: 3 / 3.
- Further diagnostic builds authorized: 0.
- Further correction builds authorized: 0; Amendment 2 reallocated the former correction slot to this final diagnostic dispatch.
- Full Qualification runs: 0.

**Stop Condition F — patch/build/infrastructure replacement budget exhausted.**

Strongest conclusion: Amendment 2's bounded auto-first-exterior fallback is locally validated and its ordered patches bootstrap successfully in CI, but the final authorized run failed during CMake dependency configuration on an unavailable Homebrew GLib header path. No intended IPA was produced, so WO-037 still cannot classify the exterior pixels. The canonical order forbids another build; orchestrator review is required.

Unlisted report Gist: `https://gist.github.com/arjunyerevan95-dot/d8e93d65c0df86ae40a863d188e8e122`
