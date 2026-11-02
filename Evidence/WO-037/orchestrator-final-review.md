# WO-037 Final Orchestrator Review

- Review date: 2026-08-29
- Disposition: **EXECUTION EVIDENCE ACCEPTED; NO PRODUCT CHANGE; NO RENDERER RESULT**
- Canonical work-order disposition: **SUPERSEDED by WO-038**
- Accepted engineering baseline remains: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`

## Inputs reviewed

- Worker execution/evidence commit: `7c17095ff876909e31e4c7e63702fff52b237373`
- Amendment 2 diagnostic source commit: `fbddf1f65fef8d3d56e5ee9b3511e0b72198163d`
- Fast run: `33265712820`
- Failure artifact: `OpenMW-iOS-fast-failure-63`, ID `9718681291`
- Failure artifact digest: `sha256:c7cc2fea29cf86ae6e8c16d78ee237c18487ef4e56409ffc6547c49a4966676e`
- Worker report: `Evidence/WO-037/report.md` at the evidence commit
- Mirrored report: <https://gist.github.com/arjunyerevan95-dot/d8e93d65c0df86ae40a863d188e8e122>

## Findings

Amendment 2 remained within its diagnostic-trigger scope. A valid `renderer-target-request.txt` remains authoritative; missing, unreadable, empty, or invalid input selects the same bounded one-shot capture at the first eligible exterior fog generation. The change does not alter target coordinates, readback, renderer state, product defaults, or presentation.

Local evidence records:

- focused validation: 25 passed and 2 compiler-dependent skips;
- aggregate validation: 148 passed, 8 skipped, and 2 pre-existing Windows executable-format errors;
- ordered OpenMW, OSG, and GL4ES patch reconstruction passed;
- explicit-request precedence, fallback selection, and one-shot behavior passed; and
- source syntax and diff checks passed.

Fast run `33265712820` passed source acquisition, cache restoration, patch bootstrap, and source validation. The qualified incremental build-state cache missed. During cold dependency configuration, pinned OSG's optional `FindGLIB.cmake` accepted a host Homebrew GLib path and attempted to read:

`/usr/local/Cellar/glib/2.88.2/lib/glib-2.0/include/glibconfig.h`

That file was absent. CMake configuration stopped before OpenMW compilation, linking, packaging, or device execution. The failure therefore says nothing about the auto-arm runtime behavior or the renderer defect.

Direct inspection establishes that pinned OSG discovers GLib with non-required `FIND_PACKAGE(GLIB COMPONENTS gobject)` and documents CMake's standard `CMAKE_DISABLE_FIND_PACKAGE_<Package>` mechanism. The iOS build does not currently disable optional GLib discovery. The required static iOS OSG plugin set does not include a GLib-dependent plugin. A narrow iOS-only `CMAKE_DISABLE_FIND_PACKAGE_GLIB=ON` configuration is therefore the evidence-backed recovery candidate; installing or hard-coding a host Homebrew path is not.

## Acceptance decision

- Accept the worker's execution evidence and failure classification.
- Reject the run as a diagnostic or renderer result because no IPA or device evidence exists.
- Do not accept Amendment 2 diagnostic source into the engineering baseline yet.
- Do not grant WO37 a fourth Fast dispatch; its authorized budget is exhausted.
- Supersede WO37 with WO38, which separately authorizes the narrow cold-configuration recovery and completion of pixel attribution.
- Keep black silhouettes and the blue/white horizon cutoff as distinct unresolved paths.

No durable engineering Decision is created from this failure. No accepted source/artifact milestone advances.
