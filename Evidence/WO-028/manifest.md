# WO-028 Evidence Manifest

- Work order: [WO-028 — Android Touch UI / Action Fidelity](../../WorkOrders/WO-028.md)
- Status: ACTIVE
- Engineering baseline: `6db1c2af5066f810df97c5af39bdbf2a48fb86b5`
- Control-plane baseline: `50a84c34fc213c20e8653e565b90b94da636013c`
- Active branch: `codex/wo28-android-touch-fidelity`

## Starting-state verification

- Both issued baseline commits resolve locally.
- Branch creation point: control-plane commit `50a84c34fc213c20e8653e565b90b94da636013c` atop WO27 engineering commit `6db1c2af5066f810df97c5af39bdbf2a48fb86b5`.
- Local control-plane state was one commit ahead of `origin/codex/wo27-runtime-data-path`; the migration commit had not been pushed.
- Latest successful engineering CI: WO27 Fast run `32480504839` at `6db1c2a`.
- No active CI run existed at WO28 issue time.
- Pre-existing dirty/untracked handoffs, ledger edits, temporary files, and bytecode caches were preserved and are not WO28 changes.

## Qualified evidence carried forward

- [DEC-001](../../Decisions/DEC-001.md): qualified renderer/runtime baseline.
- [DEC-002](../../Decisions/DEC-002.md): movement/look traversal works; Android fidelity is incomplete.
- [DEC-003](../../Decisions/DEC-003.md): current Documents-based default game-data resolution.
- [WO27 manifest](../WO-027/manifest.md): accepted candidate and device evidence.

## Android reference

- Repository: NOT YET RECORDED
- Tag/line: NOT YET RECORDED
- Commit: NOT YET RECORDED
- Touch UI paths: NOT YET RECORDED
- Native bridge paths: NOT YET RECORDED
- OpenMW input patches: NOT YET RECORDED

## Android control inventory

NOT YET RECORDED. The completed inventory must include control ID, visible function, gameplay purpose, emitted event, bridge call, consumed OpenMW action/input, press/release/hold/repeat behavior, mode visibility, contextual state, and analog/digital classification.

## iOS before/after inventory

NOT YET RECORDED. Each Android control must be classified as `MATCHES`, `MISSING`, `WRONG ACTION`, `WRONG EVENT TYPE`, `WRONG VISIBILITY`, `WRONG LAYOUT`, `PARTIAL`, or `NOT APPLICABLE`, with final disposition.

## Known starting defect

- Before Inventory dispatch: touch `INV` → keyboard `B` injection → inventory does not open.
- Required after dispatch: NOT YET RECORDED.

## Implementation and regression evidence

- Action-dispatch architecture: NOT YET RECORDED
- Files changed: NOT YET RECORDED
- Correction commits: NOT YET RECORDED
- Regression tests: NOT YET RECORDED
- Synthetic wide-iPhone result: NOT YET RECORDED
- Synthetic smaller-iPhone result: NOT YET RECORDED
- Synthetic landscape-iPad result: NOT YET RECORDED
- Arbitrary-aspect result: NOT YET RECORDED
- Floating-stick status: NOT YET RECORDED

## Build evidence

- Fast Development run: NOT YET RECORDED
- Full Qualification: MUST NOT RUN
- Cache result: NOT YET RECORDED
- Rebuilt components: NOT YET RECORDED
- Build duration: NOT YET RECORDED
- Executable SHA-256: NOT YET RECORDED
- IPA SHA-256: NOT YET RECORDED

## Device evidence

- Logging/preflight: NOT YET RECORDED
- Installation: NOT YET RECORDED
- User launch: NOT YET RECORDED
- Main-menu touch: NOT YET RECORDED
- Movement/look/multitouch: NOT YET RECORDED
- Activate/Attack/Jump: NOT YET RECORDED
- Inventory open/use/close: NOT YET RECORDED
- Journal/menu and weapon/magic: NOT YET RECORDED
- Dialogue and scene transition: NOT YET RECORDED
- Renderer regression: NOT YET RECORDED
- WO27 data-path regression: NOT YET RECORDED
- Crash/jetsam: NOT YET RECORDED
- Incidental performance: NOT YET RECORDED
- Exterior graphics defects: deferred; no WO28 correction authorized

## Outcome

- Stop condition: NOT YET RECORDED
- Strongest conclusion: NOT YET RECORDED
- Recommended next boundary: NOT YET RECORDED
