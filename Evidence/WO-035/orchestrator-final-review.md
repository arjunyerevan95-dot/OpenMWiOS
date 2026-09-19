# WO-035 final orchestrator review

- Review date: 2026-08-25
- Disposition: **ACCEPT EVIDENCE / ACCEPT TARGET FALSIFICATION / NO PRODUCT CHANGE**
- Worker evidence commit: `0b563307a32688a4aa5feddb6587f329f13c67b0`
- Execution branch: `codex/wo35-sky-blending-qualification`
- Accepted engineering baseline: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9` — unchanged
- Stop condition: **C — sky-blending target hypothesis falsified**

## Authorization and ControlPlane continuity

The explicit WO35 start directive was delivered through the user at `2026-08-25T16:44:01Z`. The worker acknowledged receipt at `2026-08-25T16:44:18Z`, identified ControlPlane commit `08d62dea4806c65052cbdcb7bf86f4ea22edb3f7`, and began only WO35.

The canonical ControlPlane remained at READY because the direct worker-delivery/status path had timed out and the manual relay was not followed by the separate canonical ACTIVE commit. This is a historical status-recording discrepancy, not missing authorization. The worker session independently records both the directive and receipt.

The worker did not modify canonical CURRENT_STATE, WorkOrders, or Decisions.

## Source, branch, and scope review

Evidence commit `0b563307a32688a4aa5feddb6587f329f13c67b0` is a direct child of accepted engineering baseline `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`. Its diff adds only six files under `Evidence/WO-035/`. It contains no product/source change and does not contain rejected WO34 terrain correction `398a91759b1b327b464cf81e41320b8e5f312c9b`.

No build, CI workflow, IPA, or Full Qualification was required or started. This matches WO35 Route B after the no-build configuration experiment failed its visual target criterion.

## Configuration and runtime proof

The original effective `settings.cfg` is identified by SHA-256 `EE80D8B9EFD9076070EFDF26902D4D5B881A0B54FE47626CE5C79DC4703743BA`. It contained no `[Fog]` section, so pinned defaults supplied `sky blending = false` and `sky blending start = 0.8`.

The test file is identified by SHA-256 `744A7C89510C5E9BFD649CBD93739721905589F5C815D8F6430D99BA08A9EC10`. Its only semantic change was enabling sky blending while retaining start `0.8`. The same installed WO34 IPA and view distance were held constant.

The raw diagnostic attachment is independently identified as 163,586 bytes with SHA-256 `09649219B1A7AEC907EBB6386B0563AACF859D2C206FFECF0AB50F18D1DD0927`. Session `AFEF6F3A-DD3C-402D-AF51-9D91BECAE505` contains eight `sky_blending=1` records and no `sky_blending=0` records. It records `selected=7168`, `camera_far=7168`, aspect `2.17272727`, and resolution `2868x1320`.

The diagnostic's `terrain_cull=12221.2` belongs to the already-installed WO34 binary and is held constant. WO34 already proved that wider radius visually inert; it is absent from the WO35 source branch.

## Device result

All ten supplied 1280x589 screenshot SHA-256 identities independently match the worker manifest. Direct visual inspection confirms that, with sky blending active:

- the sharp blue horizontal band remains plainly visible;
- the large fog-colored/white cutoff remains behind water, terrain, and trees;
- dark and pure-black distant silhouettes remain in some views;
- nearby terrain, water, sky, HUD, touch overlay, smoke, and foliage remain present; and
- no crash was reported during the exterior session.

This is sufficient to falsify sky blending as a correction for the blue/white target: the intended feature is proven active and the target defects remain materially present.

The user reports that some silhouettes now fade or become translucent at certain angles/distances and explicitly chose to retain the setting because that presentation is preferable. Accept this as a user preference and secondary observation, not as a qualified product correction. WO35 did not assign fresh Arm A screenshot identities, so the silhouette improvement is not accepted with the same causal strength as the target falsification.

## Accepted conclusion and next boundary

Accept the execution evidence and disciplined stop. Reject any inference that sky blending fixes the blue/white cutoff, and do not enable it as an iOS product default on this evidence. The device may retain the explicit user setting without changing canonical product state.

Direct inspection of the preserved effective settings reveals `viewing distance = 7168` and no `[Terrain]` section. Pinned OpenMW therefore uses its `distant terrain = false` default. Source verification establishes that this selects `TerrainGrid`, limits the in-game slider to 7168, and leaves diagnostic object paging inactive; enabling distant terrain selects `QuadTreeWorld`, allows the large 81920 slider, and permits the existing default object-paging path. This is a stronger next configuration boundary than raising camera far distance alone.

Close WO35 as ACCEPTED for controlled falsification value. Issue WO36 to test distant-terrain paging at the same 7168 distance first, then bounded higher distances only if paging is proven active and stable.
