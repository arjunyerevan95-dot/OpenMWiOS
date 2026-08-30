# WO-028 Execution Completion Record

- Execution outcome: **PARTIAL / STOPPED AT CONDITION G**
- Candidate source HEAD: `1dc819cea447f8ac40c878e1a6d7f4d478e94063`
- Fast Development run: `32511443555` — successful
- Artifact: `OpenMW-iOS-fast-30` (GitHub artifact ID `9457442141`)
- Executable SHA-256: `2D87E61D8F6F372EBC90F4B0A1E747D3E9721EA0A9A1B87C629810BB06686B39`
- IPA SHA-256: `0E4169BFF35D0D2D37FFD7730A6FD6AF0A97ABDFAF4643DCBD4C3DDF63B082D0`
- Full Qualification: did not run
- Orchestrator disposition: **implementation REJECTED; evidence accepted**
- Canonical work-order status: **SUPERSEDED** by [DEC-004](../../Decisions/DEC-004.md)

## Device observation

On 2026-08-22 the user reported:

- tapping the app icon sometimes causes an immediate launch-time hard crash;
- the launch-time crash may repeat for several consecutive attempts before a later launch reaches the main menu;
- the main menu renders with the amended Android-derived overlay icons;
- tapping any overlay button causes a hard crash;
- tapping `New Game` also causes a hard crash;
- the white overlay icons are too visually dominant and should be approximately 80% transparent.

The user also reported that SideStore had declared its own certificate invalid before this IPA was sideloaded. The user re-signed SideStore and then sideloaded OpenMW. No supplied crash or termination evidence implicates signing, entitlements, dyld, provisioning, or installation state, so this is retained only as environmental context.

No crash report, jetsam report, or symbolicated stack accompanied the observation. The screenshot proves the visible main-menu/overlay state but cannot prove the native crash mechanism.

The intermittent launch-time crash, `New Game` crash, and overlay-action crash are separate observed paths. They must not be merged into one causal claim unless later evidence shows that they converge.

Screenshot evidence: `5F84DEBA-7DFD-4A2E-9FAA-FFDD3CA54BD7/1-Photo-1.jpg`, `1280x589`, SHA-256 `A1173517C96EF3BB73BEC6DE1DC010A1EEF6F26D6C50AB16764DE9C036A08C19`.

## Execution conclusion

The candidate cannot satisfy WO28 acceptance because it produces user-observed hard crashes during launch and after menu input. Per Stop Condition G, execution stopped without a source correction. The exact cause or causes remain unproven.

The opacity request is preserved as UX evidence. It is not treated as authorization to change the closed work order or rejected candidate.

## Control-plane boundary

The successor orchestrator reviewed this evidence under the ControlPlane authority model, rejected the implementation result, accepted the evidence record, superseded WO28 through [DEC-004](../../Decisions/DEC-004.md), and retained WO27 as the highest accepted runtime baseline. No new engineering work was issued or started.
