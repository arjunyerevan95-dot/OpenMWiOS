# WO-028 Execution Completion Record

- Execution outcome: **PARTIAL / STOPPED AT CONDITION G**
- Candidate source HEAD: `1dc819cea447f8ac40c878e1a6d7f4d478e94063`
- Fast Development run: `32511443555` — successful
- Artifact: `OpenMW-iOS-fast-30` (GitHub artifact ID `9457442141`)
- Executable SHA-256: `2D87E61D8F6F372EBC90F4B0A1E747D3E9721EA0A9A1B87C629810BB06686B39`
- IPA SHA-256: `0E4169BFF35D0D2D37FFD7730A6FD6AF0A97ABDFAF4643DCBD4C3DDF63B082D0`
- Full Qualification: did not run

## Device observation

On 2026-08-22 the user reported:

- the main menu renders with the amended Android-derived overlay icons;
- tapping any overlay button causes a hard crash;
- tapping `New Game` also causes a hard crash;
- the white overlay icons are too visually dominant and should be approximately 80% transparent.

No crash report, jetsam report, or symbolicated stack accompanied the observation. The screenshot proves the visible main-menu/overlay state but cannot prove the native crash mechanism.

Screenshot evidence: `5F84DEBA-7DFD-4A2E-9FAA-FFDD3CA54BD7/1-Photo-1.jpg`, `1280x589`, SHA-256 `A1173517C96EF3BB73BEC6DE1DC010A1EEF6F26D6C50AB16764DE9C036A08C19`.

## Execution conclusion

The candidate cannot satisfy WO28 acceptance because touch/menu input produces a user-observed hard crash. Per Stop Condition G, execution stops without a source correction. The exact crash cause remains unproven and requires orchestrator review before any additional engineering work.

The opacity request is preserved as UX evidence. It is not treated as authorization to change the active work order or candidate.

## Control-plane boundary

Only WO28 execution evidence was updated. `WorkOrders/WO-028.md`, `Documentation/CURRENT_STATE.md`, and `Decisions/` were not modified in response to this device result. Canonical state may now be stale because it predates the rejected device candidate; resolving that is reserved for the orchestrator.
