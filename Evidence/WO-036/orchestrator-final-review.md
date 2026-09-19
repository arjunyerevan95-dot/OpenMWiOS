# WO-036 Orchestrator Final Review

- Disposition: **ACCEPT — CONTROLLED FALSIFICATION; NO PRODUCT CHANGE**
- Stop condition: **C — distant-terrain and higher-distance hypothesis falsified**
- Worker execution branch: `codex/wo36-distant-terrain-qualification`
- Starting engineering baseline: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`
- Final evidence commit: `4f6cfc62ced645d4465f401520a1dfaca5e65ab7`
- Product/source diff: none
- Build/CI/artifact: none

## Repository and governance review

The final evidence commit and its predecessor are evidence-only descendants of the accepted engineering baseline. The branch diff adds only five files under `Evidence/WO-036/`; it changes no source, workflow, canonical CURRENT_STATE, WorkOrders, or Decisions. The pre-existing unrelated worker worktree files remain untouched.

A branch-specific GitHub Actions query returned no runs. This agrees with the evidence-only diff and the worker's report that no build or workflow was started.

## Configuration and diagnostic proof

Arm A preserves the restored `7168` configuration and proves `object_paging=0`. Arm B changes only the terrain-system selection, proves `object_paging=1` at the same `7168` distance, and leaves the target defects materially unchanged.

The Arm C attachment was independently identified as 163,291 bytes with SHA-256 `360A209BD9D751493E5C6215E5F369730CE13E09CF16A4A00D9037B92DF8A92C`. It contains one fresh session, `644CF060-AAD4-42AC-9026-9C8713EE78F8`, and records:

- `selected=16384` and `camera_far=16384`;
- `terrain_cull=27934.2`;
- `view_distance=16384` and fog end `16384`;
- `object_paging=1`; and
- scene clear color matching the light fog-colored background while sky blending remains active.

All six Arm C screenshot byte sizes and SHA-256 identities independently match the evidence manifest.

## Visual review

Direct inspection confirms that Arm C renders substantially more terrain and objects at moderate distance. It also confirms that this is displacement rather than correction:

- hard black distant rock/tree silhouettes remain;
- the sharp blue horizontal band remains at the farther horizon;
- the large pale/white fog-colored uncovered region remains; and
- the user reports a modest performance dip across long vistas.

No crash or jetsam was reported. Arm D was optional and was correctly omitted once Arm C established the same boundary at greater cost.

## Acceptance decision

Accept the execution discipline, configuration identity, diagnostic proof, visual classification, and exact restoration. Reject any inference that distant terrain or a larger default view distance corrects the renderer. Do not advance the accepted engineering baseline, enable distant terrain by default, or raise the iOS default view distance.

The strongest accepted conclusion is that view distance controls where the failure becomes visible but not why it occurs. Subsequent work must attribute exact target pixels/draws rather than continue global distance, terrain-radius, fog-enable, or sky-blending toggles.

## References

- [WO-036](../../WorkOrders/WO-036.md)
- [Execution report](report.md)
- [Configuration arms](configuration-arms.md)
- [Device capture](device-capture.md)
- [Evidence manifest](manifest.md)
- [DEC-016](../../Decisions/DEC-016.md)
