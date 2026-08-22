# WO-029 Completion Record

## Execution result

- Result: **STRONG DEVICE PASS / PARTIAL FORMAL ACCEPTANCE EVIDENCE**
- Execution branch: `codex/wo29-ios-crash-isolation`
- Correction commit: `45c1d8c696fb328d977893b79efc78689a3f4d08`
- Fast Development run: `32548876888` (`success`)
- Artifact: `OpenMW-iOS-fast-31`, ID `9470501854`
- IPA SHA-256: `E295561EE9BF1F52A7337C6AACFE7777F530E9E394462F3C143DEB98E14BDD63`
- Executable SHA-256: `6FF52E861FF44D4C4449E1A82481EE7F52B515932A56279EB5C057F9E740F0C2`
- Mach-O UUID: `52739477-31F4-3693-9D6F-30366E3D640D`
- Full Qualification: not run
- Documentation-only run `32563091883`: unexpectedly triggered, cancelled after 34 seconds during cache restore; no configure, compile, link, package, or artifact step ran

## Proven result

The rejected WO28 build's launch, `New Game`, and overlay-action crashes converged at a non-ARC lifetime defect in the process-lifetime `UIImage*` cache. The bounded correction makes the cache own images created with `[[UIImage alloc] initWithData:]`. Local tests and the real production build passed.

The user installed the exact corrected IPA and reported that it boots normally and the controls work fine. The session reached indoor and exterior gameplay and produced nine screenshots without a user-observed native crash, unexplained termination, or jetsam. The corrected candidate therefore materially passes the old crash boundary.

## Evidence limitation

The canonical Phase 5 numeric matrix was not recorded: exact consecutive-launch attempts, fresh `New Game` transitions, and per-control attempts are unknown. After the session, `pymobiledevice3 usbmux list` returned `[]`, so an independent fresh crash-report inventory could not be pulled. This completion record does not invent those values or self-declare canonical acceptance.

## Out-of-scope feedback recorded

- touch icons should be substantially more transparent;
- controls need future resize/reposition/customization support;
- exterior foliage alpha/cutout rendering is broken;
- distance fog/horizon presentation is missing or incorrect;
- one screenshot shows a transient blocky red combat effect.

These observations were not fixed, promoted to durable decisions, or used to amend WO-029.

## Control-plane discipline

The worker did not modify `Documentation/CURRENT_STATE.md`, `WorkOrders/`, or `Decisions/`. Execution stops at the orchestrator-review gate. No subsequent engineering work was begun.
