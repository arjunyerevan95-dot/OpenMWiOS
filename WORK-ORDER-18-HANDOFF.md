# Work Order 18 Handoff

## Starting state

1. **Starting branch:** `fix/gl4es-debug-uniform-initializer`
2. **Starting HEAD:** `03d133dae7261a2004869af89f71e6eee0961c79`
3. **Work Order 17 state:** shader compilation succeeded; four native program links failed with `No definition of modelToClip in vertex shader`. The Work Order 16 GL4ES null-dereference crash remained eliminated. The keyboard observation is not treated as progression: it establishes only that an uncontrolled tap in Work Order 17 could invoke iOS text input.
4. **Previous cache correction:** `2f84b36b2a04e24ed61f383c57e9b40b8a3f74b7` (with fallback commit `ab02614`).

## Cache investigation

5. **Reason previous cache qualification failed:** the v4 keys themselves were branch-free, but GitHub Actions does not expose caches saved on one sibling branch to another sibling branch. Work Order 17 therefore could not see the cache saved on the Work Order 16 branch. The earlier v3-to-v4 action/key transition was an additional cache-version boundary. Classification: GitHub cache visibility causes B/C, with E also present during the original transition; it was not cause A and the ABI fingerprint had not genuinely changed.
6. **New cache architecture:** Fast Development now runs on `pull_request` and manual `workflow_dispatch`, not raw `push`. A work-order PR targets the last qualified cache-bearing development branch. GitHub therefore permits the PR run to restore the base branch's caches. Cache identity remains branch-free and content-derived: the exact build-state key is ABI fingerprint plus source fingerprint; an ABI-only restore prefix permits an incremental base only after the marker verifies ABI identity. The workflow records the requested primary key, actual matched key, PR base ref, and source delta. Full Qualification remains manual and independent.
7. **Cache input fingerprint:** ABI `ios-fast-v4-xcode16.4-ios16.3-arm64-edd5fbcd7e18a5d33a4de616e039704d860dd513c9140bfb34ccbee5f1003987`; Work Order 18 source `2512e2ab284afde9929b22c804aa640244142774940e5e97ce9d33667b4e8633`.
8. **Cross-branch cache mechanism:** draft PR #7, head `fix/gl4es-modeltoclip-linkage`, base `fix/gl4es-debug-uniform-initializer`. GitHub's supported PR-base cache visibility exposed the qualified Work Order 17 cache to `refs/pull/7/merge`. No unsafe sibling-branch fallback was added.
9. **Cache commit:** `e5f2d202acb0297c0ea27b6990731c19e6b5ad08` (`ci: restore Fast caches from qualified PR base`).
10. **Expected and actual cross-branch cache source:** `ios-fast-state-v4-macOS-X64-ios-fast-v4-xcode16.4-ios16.3-arm64-edd5fbcd7e18a5d33a4de616e039704d860dd513c9140bfb34ccbee5f1003987-5b71f556615e2184ba8388bd9daaee249d08d5d4c38b20e06f16962365a52b9d`, saved by the Work Order 17 base branch. It restored successfully by the ABI prefix; the marker recorded source delta `5b71... -> 2512...`.

## modelToClip investigation and correction

11. **Four original failing programs:** native program handles `0x122976100`, `0x122976200`, `0x122976400`, and `0x122976500`, in that order at 22:24:23.090, .100, .109, and .123. The Work Order 17 log did not record OSG shader names. A bounded four-program attachment inventory was added, but its diagnostic-only API call failed production compilation before it could produce a runtime name mapping; no shader-name mapping is claimed.
12. **modelToClip definition:** `files/shaders/lib/core/vertex.glsl`: `vec4 modelToClip(vec4 pos) { return projectionMatrix * modelToView(pos); }`.
13. **modelToClip reference sites:** compatibility vertex shaders `debug.vert`, `depthclipped.vert`, `objects.vert`, `outline.vert`, `sky.vert`, `terrain.vert`, `water.vert`, `bs/default.vert`, and `bs/nolighting.vert`.
14. **Shader unit containing main():** each compatibility entry `.vert` owns its `main()`. The linked `lib/core/vertex.glsl` unit owns the transform definitions and legitimately has no `main()`.
15. **OpenMW multi-unit shader architecture:** `vertex.h.glsl` originally used `@link "lib/core/vertex.glsl"` and exposed function prototypes. `ShaderManager::getLinkedShaders()` constructed a separate vertex-library `osg::Shader`; `addLinkedShaders()` attached it beside the entry vertex shader and fragment shader to one `osg::Program`.
16. **GL4ES multi-unit link architecture:** `gl4es_glAttachShader()` converted and attached every shader object independently to the native GLES program. `gl4es_glLinkProgram()` reconciled conversion-needs with `redoShader()` but did not merge same-stage source units or provide a cross-unit function-linkage adapter before native `gles_glLinkProgram()`.
17. **Pre-conversion shader set:** representative debug program = entry `compatibility/debug.vert`, declaring/calling `modelToClip` through `vertex.h.glsl`, plus main-less library `lib/core/vertex.glsl` containing the definition, plus `compatibility/debug.frag`. Other affected entry shaders used the same header/library structure.
18. **Post-conversion shader set:** Work Order 17 proved that compilation of the independently converted units succeeded, but Apple's native program linker saw the call in the entry unit without a usable definition and reported `No definition of modelToClip`. The Work Order 18 candidate would instead place the unchanged definition in each entry compilation unit. No Work Order 18 post-conversion runtime capture exists because the production build stopped at compile Condition C.
19. **Exact symbol-loss mechanism:** GL4ES preserved the OpenMW/OSG multi-object attachment structure through to native GLES. The desktop-style cross-shader helper definition was not resolved by Apple's GLES linker across those independently converted vertex objects. This was not a missing source definition: it existed in OpenMW's separate main-less library object.
20. **Android comparison:** `modding-openmw/openmw-android-docker` release 2.7.4 (`5b02e847dc646c9f10cd66001e4d65c5274dde49`) carries the same adaptation in `patches/openmw/ng-gl4es.patch`: remove the core vertex `@link` directives/prototypes and inline `modelToView`, `modelToClip`, and `viewToClip`, without changing their math. This keeps the definition and reference in one GLES compilation unit.
21. **Upstream GL4ES comparison:** pinned GL4ES is `c9895df34cd466c23bc60c2bd3db3d87e98fcbe7`. Inspection through current upstream master `81547d986798e876de8b434193920b606a72363f` found no directly applicable multi-unit merge/link correction. A wholesale GL4ES upgrade was not attempted.
22. **Selected fix owner:** narrow iOS OpenMW shader compatibility patch, matching the working Android precedent. This avoids implementing a risky GLSL linker/merger inside GL4ES and preserves the original transform calculations.
23. **Regression fixture:** `validation/test_openmw_modeltoclip_linkage.py`.
24. **Fixture before result:** pass: the original header is correctly identified as non-self-contained, with `@link` plus a prototype and a separate main-less definition unit.
25. **Fixture after result:** four tests pass. The corrected header is self-contained; exactly one `modelToClip` definition precedes `main()` and its first call; no `@link` remains in the expanded unit; all three transform expressions match the original library.
26. **Shader/link correction commit:** `f835091db7852e01cb8bd0a91ed2cedfa082c449` (`fix(ios): keep core vertex transforms in one GLES shader unit`). It includes `0003-ios-inline-core-vertex-transforms.patch`, the fixture, and bounded attachment instrumentation `0004-log-modeltoclip-program-attachments.patch`.

## Fast build

27. **Fast run ID:** `31963921124`, PR #7, merge SHA `65c52de525808b0e43d0bf66bc6c87d41cba34fb`, head SHA `f835091db7852e01cb8bd0a91ed2cedfa082c449`.
28. **Proof Full Qualification did not run:** the branch/run inventory contains only `iOS Fast Development`, event `pull_request`. Full Qualification was neither triggered nor a dependency.
29. **Cache restore result:** SUCCESS. Source-download cache exact hit; vcpkg cache exact hit; qualified build-state cache cross-branch partial hit from the Work Order 17 base. Cache restore took 179 seconds. The restored ABI marker passed and the differing source fingerprint was recorded rather than treated as ABI-compatible output identity.
30. **Restored components:** source downloads; complete vcpkg binary/install state; LuaJIT (`Reusing qualified cached LuaJIT iOS archive`); GL4ES source/build/prefix state; OSG and other fetched/build state within the qualified Xcode tree. GL4ES and OSG each emitted zero `CompileC` operations.
31. **Rebuilt components:** no GL4ES or OSG source was rebuilt. The GL4ES Xcode target performed only its no-op check and reported `BUILD SUCCEEDED`. The OpenMW Xcode project emitted 90 `CompileC` operations before the diagnostic compilation failed; the bootstrap reset/repatch of OpenMW makes OpenMW object reuse a remaining performance limitation even though third-party restoration succeeded.
32. **Total build duration:** 14m16s to failed completion (18:12:51–18:27:07 UTC). This is not a successful-build benchmark.
33. **Component timings:** cache restore 2m59s; tool install 1m18s; source bootstrap/validation 50s; configure/dependency preparation 2m43s; production compile step 5m46s until hard failure. GL4ES compile count 0; OSG compile count 0; production link never started.
34. **Executable SHA-256:** unavailable; production compile failed before link.
35. **IPA SHA-256:** unavailable; no package was produced.

## Device validation

36. **Current data-container UUID:** not queried because no valid Work Order 18 artifact existed and device preflight was not authorized past Condition C.
37. **Current cfg data path:** not queried for the same reason.
38. **Logging readiness:** not prepared; device validation was blocked before install/launch.
39. **User launch timestamp:** none.
40. **modelToClip error count before:** 4.
41. **modelToClip error count after:** not measured; no Work Order 18 runtime.
42. **Program-link results:** not reached. The static correction fixture passed, but production validation stopped first.
43. **Shader compile results:** not reached on device. Existing Work Order 17 result remains zero shader-compilation failures.
44. **GL error status:** not measured.
45. **Loading behavior:** no Work Order 18 launch.
46. **Music behavior:** no Work Order 18 launch.
47. **Process lifetime:** no Work Order 18 launch.
48. **Crash status:** no Work Order 18 process was launched; therefore no new crash evidence.
49. **Viewport status:** not retested; prior tiny viewport remains an independent known issue.
50. **Lua/MWUI status:** not retested; prior secondary errors remain parked.
51. **Stale VFS status:** not retested; prior warning remains parked.
52. **Keyboard observation:** none in Work Order 18. Work Order 17 keyboard presentation remains explicitly uncontrolled and is not a success criterion or evidence of menu progression.
53. **Highest runtime boundary:** unchanged from Work Order 17 because Work Order 18 produced no runnable artifact. Highest build boundary: real production ARM64 C++ compilation.
54. **Stop condition:** CONDITION C — PRODUCTION BUILD FAILS.
55. **Strongest causal conclusion:** Track A is qualified: PR-base cache visibility safely restored the branch-independent, input-fingerprinted dependency state. Track B's source analysis and Android-backed fixture support an in-unit `modelToClip` definition, but device causality is not yet validated. The run failed only because diagnostic logging used a nonexistent pinned-OSG API: `osg::Program::getShaderList()` in `shadermanager.cpp:607`. That diagnostic failure must not be confused with rejection of the transform-inline correction.
56. **Precise recommended Work Order 19:** correct or remove only the bounded attachment diagnostic using the pinned OSG 3.6.5 public API (for example, inspect the actual available shader accessor/count API before editing). Preserve `0003` unchanged. Run its local/CI compile guard, then perform one Fast Development PR update using the already-qualified base cache. If the real production build succeeds, package one artifact, verify the current data-container/config path, prepare bounded logging, and conduct one user-launched device test to measure `modelToClip` 4→0 and expose the next shader/link boundary. Do not touch viewport, Lua/MWUI, VFS, sandbox persistence, controls, or gameplay.
