# WO-038 Final Orchestrator Review

- Date: 2026-09-19
- Disposition: **PARTIAL ACCEPT — EXECUTION/BUILD EVIDENCE ONLY; NO NEW RUNTIME OR RENDERER QUALIFICATION**
- Work-order disposition: **SUPERSEDED by WO-039**
- Accepted engineering baseline remains: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`

## Exact checkpoint reviewed

- Canonical ControlPlane: `aff6bfcf92a532b8ed3ec334e2093f281cc8364a`, branch `codex/wo29-ios-crash-isolation`, local/remote equal and clean before this review.
- Worker: OpenMW Instrumentor, thread `019ffd24-a544-7153-9790-108f7079471e`; latest turn completed, thread not loaded. Its final exchange delivered the already-built IPA to a temporary download service. No later device response was found.
- Worker branch: `codex/wo38-cold-osg-attribution`; local/remote HEAD `7dbedda156b9ab2de1b23f7119f58a6f6a0d6667`.
- Worker [report at this commit](https://github.com/arjunyerevan95-dot/OpenMWiOS/blob/7dbedda156b9ab2de1b23f7119f58a6f6a0d6667/Evidence/WO-038/report.md), manifest, Pause correction record and target-capture record were inspected.
- Pause source commit: `457ab881442302a9bd59435c1878ed4e72f6e52b`.
- Latest CI independently queried: Fast `33306995685`, completed/success; no newer run in the repository listing. Cold recovery run `33269657425` also passed.
- Canonical-file diff on the worker from `7c17095ff876909e31e4c7e63702fff52b237373` through HEAD is empty. Untracked `.artifacts/` is preserved.

## Evidence accepted and not accepted

Accept the recorded cold-build recovery, bounded Pause source change, reported focused executable validation and successful real production compile/link/package as execution evidence. The Pause change preserves a pressed virtual START through an explicit SDL joystick-update opportunity before storing release. The local fixture verifies ordering, cancellation and long-press suppression; it is not a substitute for the missing physical input check.

The worker reports inherited Windows/CRLF aggregate-test failures and skips. This review does not relabel that aggregate suite as fully passing or rerun it unnecessarily.

No physical Pause/editor qualification, prepared-save identity or successful target-pixel capture is recorded. Therefore do not accept the Pause behavior, diagnostic observer or a renderer correction into the runtime baseline. No new Full Qualification result exists. Preserve these candidates for later explicit qualification.

## Preserved artifact

- Run: [33306995685](https://github.com/arjunyerevan95-dot/OpenMWiOS/actions/runs/33306995685)
- Artifact: `OpenMW-iOS-fast-67`, ID `9730898326`.
- Artifact digest recorded by the worker: `sha256:41709748e6cad3d8e48b1244ae42ee96a35ea7eb2607b751f8d6f834b69c315b`.
- GitHub API now reports the artifact expired on `2026-09-06T10:48:59Z`; the temporary link's recorded expiry was September 1. Neither link should be treated as a durable current download.
- Surviving local IPA: `C:/Users/arjun/Documents/Codex/2026-08-14/you-are-taking-over-an-existing-2/.worktrees/wo38/.artifacts/wo38-amendment1/artifacts/OpenMW-iOS-unsigned.ipa`.
- Independently recomputed IPA SHA-256: `9312EA3B1AD757E9CEE8A22785907F93AD9C68A33E02D845210FF5F733660593`; size `39159562` bytes. Matches worker report and delivery message.
- Executable SHA-256 reported by the worker: `26a73e55775a15bfdb60cc6c05861e1f790f60dfc920a5ef7b4087f7822ed912` (not re-extracted by this review).

Expired hosting is not a reason to rebuild. No artifact was uploaded or moved during review.

## Diagnostic adequacy finding

Direct inspection at worker HEAD establishes:

- `ios/openmw_ios_renderer_diagnostics.mm`: a 96-candidate budget, one-shot completion at presentation, and explicit `depth_sample=unsupported-gles2` / `sky_rtt_sample=not-observed-observer-only` output.
- `ios/patches/osg-route-gl-entry-points-through-gl4es.patch`: projected drawable bounding boxes nominate center candidates; they are not exact rasterized coverage.
- `patches/gl4es/0010-ios-target-pixel-attribution.patch`: center RGBA samples surround candidate draws and record tracked state.
- `patches/openmw/0016-ios-renderer-diagnostics-target-pixel-present.patch`: final center readback follows pre-swap handling.

These observations may narrow a failure but do not guarantee WO38's requested depth/sky/coverage correlation. An unchanged pixel can still have been written; bounding-box intersection is not triangle visibility; intermediate-framebuffer samples require an explicit relationship to the final displayed pixel. The implementation itself labels its classifications as candidates/ambiguous, not a proven root cause.

This is a mismatch between the requested proof and the implemented observation, not a new renderer diagnosis and not a device-placement failure by the user.

The auxiliary worker `target-pixel-captures.md` still describes the pre-amendment artifact/blocker. It remains historical evidence, not the current authority; the updated report/manifest and verified Git/CI establish the later build checkpoint. Existing worker records are preserved, not silently rewritten.

## Orchestrator decision

Supersede WO38's uncompleted execution authority and replace the first-frame attribution strategy with WO39's source/design/executable-contract gate under DEC-017. The user's September 19 request authorizes next-order issuance following the reviewed direction. No worker is running and no in-flight build is interrupted.

Retain all accepted WO33 behavior and WO34–36 falsification facts. Keep silhouette and horizon hypotheses separate. Do not infer a native GLES3 migration or explicit-fog-uniform fix is already warranted. Require the next measuring design to demonstrate what its output can actually prove before production integration or another IPA is authorized.

Codebase Memory's connected query reported no indexed projects during the checkpoint review. Direct source was used; no index deletion, reindexing or configuration migration occurred. This finding describes the connected service, not proof that historical index files were deleted.

WO39 is issued READY, not ACTIVE. Its start directive is a separate orchestrator action.
