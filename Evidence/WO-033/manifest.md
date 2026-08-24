# WO-033 evidence manifest

## Baselines

- Accepted product baseline: `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27`
- Investigation continuation: `164abe4ba2becf46ea043811963ac28195d29bcd`
- Execution branch: `codex/wo33-blend-state-transition`
- Control-plane order: `WorkOrders/WO-033.md` at `6dab03257a9cac213c377203f16d5fdbec08e74d`
- Durable predecessor decision: `Decisions/DEC-012.md`

## Local evidence

- [Transition model](blend-transition-model.md)
- [Linked route proof](linked-route-proof.md)
- [Device capture](device-capture.md)
- [Execution report](report.md)
- Focused tests: `validation/test_wo33_blend_transition_diagnostics.py`
- Compiled sequence fixture: `validation/fixtures/wo33_blend_transition_fixture.c`

## CI/artifact evidence

Pending the one authorized diagnostic Fast Development build.

## Scope

WO-033 changes bounded diagnostics and tests only before causal device evidence. No blend, factor, depth, shader, texture, draw, foliage, distance/horizon, touch, data-path, dependency-version, or accepted-runtime correction is made.
