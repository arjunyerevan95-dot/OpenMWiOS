# WO-038 Execution Report

Status: **IN PROGRESS — PRE-CI VALIDATION COMPLETE**

## Scope

WO38 continues the reviewed WO37 diagnostic source and applies only the authorized optional-GLib discovery disable to recover cold OSG configuration. It does not contain a renderer correction or modify product defaults.

## Baseline integrity

- Branch: `codex/wo38-cold-osg-attribution`
- Start/continuation HEAD: `7c17095ff876909e31e4c7e63702fff52b237373`
- Accepted engineering baseline: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9` (verified ancestor)
- Canonical `Documentation/CURRENT_STATE.md`, `WorkOrders/`, and `Decisions/`: untouched
- Rejected WO34 terrain candidate: absent from this continuation
- WO35/WO36 configuration experiments: evidence/config-only and absent from product source

## Change

- `scripts/build-ios.sh`: add `-DCMAKE_DISABLE_FIND_PACKAGE_GLIB=ON` to the iOS OpenMW/OSG configuration.
- `validation/test_wo38_cold_osg_configuration.py`: add five deterministic scope and invariance checks.
- `Evidence/WO-038/`: compact execution records.

## Validation

- WO38 focused tests: 5/5 passed.
- Aggregate: 163 run, 8 skipped, with two pre-existing Windows executable-format errors and two CRLF checkout failures in inherited OSG patch tests.
- Python syntax: passed.
- Diff check: passed.
- macOS shell/configure/compile/link/package: pending Fast Development.

## CI and artifact

- Fast run: pending
- Artifact: pending
- IPA SHA-256: pending
- Executable SHA-256: pending
- Mach-O UUID: pending

## Physical attribution

Pending qualified artifact. No target classification is claimed yet.

## Current stop boundary

Not reached. The next authorized step is the single primary Fast Development dispatch. No duplicate or Full Qualification run is authorized.
