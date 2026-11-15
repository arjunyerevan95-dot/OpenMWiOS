# Experimental city occlusion for iOS

Adapted from OpenMW MR 5150 (Intel MOC), original discussion reviewed 2026-11-15.
https://gitlab.com/OpenMW/openmw/-/merge_requests/5150

Differences from the proof of concept: unchanged original opaque triangles rather
than vertex-cluster averages; a subset capped at 1,024 triangles per static mesh,
32,768 rasterized triangles per frame; full ancestor alpha/blend/animation exclusions;
static-record-only cell occluders; whole current object bounds for visibility;
observer ownership plus transform validation for cache reuse; worldspace cache
invalidation and explicit exterior-only terrain selection; exact camera identity;
frame-end deactivation; finite-input/index checks; precise ARM sse2neon behavior.

No paging, shadows, textures, controls, saves or mod settings are reduced/reset.
`[Camera] occlusion culling = false` restores the previous path after restart.
Default true for this requested experimental city-culling build; no debug overlay.

Run `python3 validation/city-culling/run_tests.py`. Linux requires OSG development
headers/libs. On Apple ARM this executes real NEON MOC wall visibility/reset tests
before the actual iOS compilation. Linux additionally runs full OSG mesh/visibility
tests: opaque original coordinates, ancestor alpha/blend exclusion, wall/portal,
near-plane crossing, camera isolation, reset, invalid indices/NaN input.

Native render occlusion, terrain occlusion and object paging translation units
compiled in the isolated host harness. Full iOS compilation, device rendering and
performance remain unverified until the coordinated build and user test. Tests do
not establish end-to-end city speedup, absence of every modded-geometry issue, or
GPU image equivalence. Check Balmora alleys/arches/trees, cell transitions, water
reflections and off-screen shadow casters with the switch on/off. No phone profiling
or per-frame statistics disk logging is used.
