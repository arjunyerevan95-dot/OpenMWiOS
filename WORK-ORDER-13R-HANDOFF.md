# Work Order 13R Handoff

Recorded: 2026-08-16 (Asia/Calcutta)

## Section 1 — Interrupted work preservation

1. **Starting branch:** `fix/ios-resources-bundle-collision`.
2. **Starting HEAD:** `71227ffdafc1bc3c80688d3654b09e853913617a`.
3. **Interrupted changes found:** no source or workflow edits; only read-only reconnaissance and generated evidence. The device inventory is `build/work-order-13/device-baseline/openmw-container-inventory.jsonl` (4,520,041 bytes). A post-PC-restart narrow device pull did not start because Apple network discovery was unavailable; no partial log was created.
4. **Interrupted commits:** none. Work Order 12 commits `fa4bab4`, `9c45f35`, `5a48d18`, `85f971f`, and `71227ff` were preserved unchanged.
5. **Preserved/reused work:** the OpenMW→OSG→GL4ES shader call-path reconnaissance, link-map symbol provenance, native-context configuration, stale VFS path source, representative CI timing profile, and dependency-tree state were retained. The inventory is recorded in `WORK-ORDER-13R-INTERRUPTED-STATE.md` and committed as `7c3a246` on `work/wo13r-android-fast-ci`.
6. **Discarded/non-causal work:** nothing was deleted. The preliminary shader-conversion-bypass model was not accepted solely from the interrupted evidence; it was tested against Android 2.7.4 and then promoted after the Android OSG loader patch and the iOS link map independently agreed.

## Section 2 — Android reference

7. **Reference repository:** `https://gitlab.com/modding-openmw/openmw-android-docker`.
8. **Release/tag/commit:** tag `2.7.4`, repository commit `5b02e847dc646c9f10cd66001e4d65c5274dde49`. A successful public pipeline is `2513210109`, job `14294171798` (`https://gitlab.com/modding-openmw/openmw-android-docker/-/pipelines/2513210109`). Its downloaded log is `build/work-order-13r/android-reference/android-2.7.4-docker-build.log`, SHA-256 `8AA0B7E1CEFDA9D755381EFAF43F57A86BB3BDDCC3E3021AA8A782EF37F0D095`.
9. **Android OpenMW revision:** Docker argument `dbbd9456e8d3d643ec41bb1331ef4b607db20a04`.
10. **Android GL4ES revision:** Docker argument `f7a8370852579d6a11154178929a02e0cf60d574`, but the Dockerfile does not check it out; it clones the moving `Openmw3` branch into a directory named with the argument. The latest branch commit before the successful build began was `a26bd21c29126039c08f4bae60f47a6bf79ed786`, so that is the best evidence-supported effective revision, but it is an inference rather than a logged checkout. `f7a8370` introduced the custom converter and `a26bd21` defined `ANDROID` in `shaderconv.c`.
11. **Android OSG revision:** `8aa8d91747ff414ab0de19aae1e0dbd739acea2c`.
12. **Android SDL revision/version:** SDL `2.32.4` source release.
13. **Native GLES version:** the normal GL4ES path requests GLES 3.2 (`OPENMW_GLES_VERSION=32`, `LIBGL_ES=3`); Android API 26 and NDK r29 are used. The exact driver-reported strings were not printed in the public build log.
14. **GL4ES build flags:** dynamic `ng_gl4es.so`; OSG is built as desktop GL1/GL2 (`OSG_GL1_AVAILABLE=ON`, `OSG_GL2_AVAILABLE=ON`, GLES variants off) and explicitly links/loads that wrapper rather than native GLES symbols.
15. **GL4ES runtime settings:** `LIBGL_SIMPLE_SHADERCONV=1`, `LIBGL_INSTANCING=1`, `LIBGL_DXTMIPMAP=1`, `LIBGL_ES=3`, `OPENMW_GLES_VERSION=32`, and `SDL_VIDEO_GL_DRIVER=libng_gl4es.so` on the normal path. ANGLE is a separately selectable path and is not the control used here.
16. **Manual-init strategy:** Android owns the context through SDL and loads `ng_gl4es.so` as the SDL GL driver. It does not use the iOS `OPENMW_GL4ES_MANUAL_INIT` static-wrapper strategy.
17. **Relevant Android/OpenMW patches:** `allow-more-es-versions.patch` selects the requested ES context; `force-postprocess-glsl-version.patch` deliberately keeps post-process GLSL at 120 unless explicitly forced to 330. Other Android patches do not replace the compatibility shader family wholesale.
18. **Relevant shader patches:** Android still uses desktop-style compatibility shaders and `#version 120`; its success therefore depends on GL4ES conversion. `LIBGL_SIMPLE_SHADERCONV=1` selects its converter. The applied OSG `ng-gl4es.patch` is the decisive integration patch because it changes OSG's GL1 lookup library from `libGL.so` to `ng_gl4es.so`.
19. **Relevant historical upstream GL4ES work:** OpenMW history contains delayed feature detection until a context exists (`044e78407`, merged through `450b971bb`) and GL4ES workarounds (`dae091482`). GL4ES's iOS documentation requires initialization after a current EAGL context. The iOS port already follows the delayed/manual-init requirement, so initialization timing is not the remaining differentiator.

## Section 3 — iOS differential

20. **iOS OpenMW revision:** `f4bec41444214a7903bebd178389ca22ca13f646` plus the preserved iOS patch series.
21. **iOS GL4ES revision:** `c9895df34cd466c23bc60c2bd3db3d87e98fcbe7` (GL4ES 1.1.6).
22. **Native iOS GLES version:** EAGL/OpenGLES ES 2.0. `GraphicsWindowSDL2` requests the SDL ES profile with major 2/minor 0 and SDL UIKit maps that request to the ES2 EAGL API.
23. **Native GLSL version:** the ES2 context's native shader-language contract is ESSL 1.00. A separate device log of `GL_SHADING_LANGUAGE_VERSION` was not needed after the native framework symbol path and native compiler's rejection of GLSL 120 were proven.
24. **iOS GL4ES flags:** `NOEGL=ON`, `NO_LOADER=ON`, `NO_INIT_CONSTRUCTOR=ON`, `STATICLIB=ON`, `DEFAULT_ES=2`.
25. **iOS GL4ES runtime settings:** `LIBGL_ES=2`, `LIBGL_GL=21`, `OPENMW_GLES_VERSION=2`; the wrapper advertises `OpenGL 2.1 gl4es wrapper 1.1.6` to OpenMW.
26. **iOS init ordering:** SDL creates and makes the native EAGL context current first; the port then calls `set_getprocaddress(SDL_GL_GetProcAddress)`, supplies framebuffer dimensions, and invokes `initialize_gl4es`. This agrees with GL4ES's documented iOS order.
27. **Android-vs-iOS matrix:** see the table below.

| Area | Android 2.7.4 known-working path | Current iOS path | Material consequence |
|---|---|---|---|
| OpenMW | `dbbd9456...` | `f4bec414...` | Version difference is not causal to lookup routing. |
| GL4ES | Ng-gl4es `Openmw3`; effective HEAD inferred near `a26bd21...` | upstream `c9895df...`, static | Different fork/backend, but both contain desktop-shader conversion. |
| OSG | `8aa8d917...`, dynamic GL4ES loader patch | `01cc2b585...`, stock Apple loader | **Decisive.** Android resolves OSG GL calls from GL4ES; iOS resolves them from Apple OpenGLES. |
| SDL | 2.32.4 | 2.32.10 | Not material to the proven symbol-routing defect. |
| Native GLES | 3.2 normal path | 2.0 | Converter output target differs; neither accepts raw `#version 120`. |
| Context owner | SDL Android | SDL UIKit/EAGL | Both create a native context before use. |
| GL4ES init | dynamic driver load | explicit manual init after context | iOS ordering is correct. |
| `NOEGL`/`NO_LOADER`/constructor | not the same static mode | all enabled | Requires explicit iOS init, which exists. |
| Shader conversion | selected by `LIBGL_SIMPLE_SHADERCONV=1` | GL4ES converter linked | Converter is present in both, but OSG bypasses it on iOS. |
| OSG function lookup | `dlopen("ng_gl4es.so")`, `dlsym` | `dlopen(NULL)`, `dlsym` finds OpenGLES framework | **Root integration difference.** |
| Shader dialect | desktop GLSL 120 retained | desktop GLSL 120 retained | Android proves rewriting OpenMW shaders is not the required first move. |
| `centroid` | converter removes/rewrites it | Apple compiler receives it | Secondary confirmation of bypass. |

28. **Most significant differences:** Android's applied `patches/osg/ng-gl4es.patch` changes the library OSG searches for GL entry points. iOS's Apple branch uses `dlopen(NULL)`/`dlsym`, and the final link map shows those unprefixed shader functions resolving from `OpenGLES.framework`, not GL4ES. Native GLES version and wrapper linkage are secondary; the lookup destination determines whether conversion runs at all.

## Section 4 — shader path

29. **Original OpenMW GUI vertex shader:** `files/shaders/compatibility/gui.vert`, beginning with `#version 120` and desktop compatibility syntax.
30. **Original fragment shader:** `files/shaders/compatibility/gui.frag`, likewise beginning with `#version 120`.
31. **Source entering OSG:** `ShaderManager::getShader` loads the compatibility source, expands OpenMW directives/defines, constructs `osg::Shader`, and calls `setShaderSource`; no iOS ES rewrite occurs there.
32. **Source entering GL4ES:** no OSG GUI shader source reaches GL4ES in the failing path. OSG obtains `glShaderSource` through its Apple dynamic lookup path.
33. **Source leaving GL4ES:** not applicable to the failing OSG path. Static source inspection shows that `gl4es_glShaderSource` would call `ConvertShader` and then native `gles_glShaderSource` if reached.
34. **Source reaching native GLES:** the original/preprocessed desktop shader, including `#version 120` and later `centroid`, reaches Apple's native GLES entry point unchanged. The Apple compiler log is direct runtime evidence.
35. **Whether conversion runs:** no, not for the failing OSG shader submissions. GL4ES conversion code is linked but bypassed.
36. **Whether `#version 120` reaches Apple unchanged:** yes. The first device compiler error is `version '120' is not supported`, and the link map independently assigns OSG's unprefixed `glShaderSource` GOT reference to `OpenGLES.framework`.
37. **`centroid` provenance:** it exists in original OpenMW compatibility shaders/includes (including object/terrain/vertex-color paths). GL4ES `ConvertShader` contains explicit removal logic. Its appearance in the Apple compiler error is further evidence that conversion did not run; a textual strip hack is unwarranted.
38. **Exact causal classification:** **Category C / Stop B — the OSG shader submission path bypasses GL4ES conversion.** GL4ES is initialized and its converter is linked, but OSG's Apple entry-point loader resolves native framework functions.
39. **Relationship to `GL_INVALID_OPERATION`:** shader compile failure prevents valid program links; subsequent OSG compilation/draw calls operate on unusable programs and generate the sustained error flood. The flood is cascading evidence, not the first failure.
40. **MyGUI status:** MyGUI initializes RenderManager, Gui, ResourceManager, layers, widgets, input, fonts, layouts, skins, and numerous OpenMW resources. This is not a generic MyGUI initialization failure.
41. **Lua secondary errors:** `Misc::Color(std::string_view)` and dependent MWUI/Settings nil errors remain real but occur after the earlier shader failure. No Lua patch was made.
42. **Stale VFS path:** `files/openmw.cfg` expands `data=${OPENMW_RESOURCE_FILES}/vfs-mw`, producing the stale `./resources/vfs-mw` lookup. The explicit corrected iOS resource root still mounts `openmw-resources/vfs` and loads substantial built-in/game content. This needs a separate path-contract audit, not a shader commit.
43. **Viewport findings:** not reached. The small blue/purple rectangle remains a separately ranked drawable/viewport symptom; shader conversion is the proven earlier failure boundary.
44. **Strongest graphics root-cause model:** OSG's stock Apple GL resolver searches the process image and finds Apple's OpenGLES symbols. That routes desktop GLSL directly to the native ES2 compiler, bypassing GL4ES's version/qualifier conversion. Android's working OSG patch explicitly prevents the analogous bypass by loading GL4ES.
45. **Smallest proposed correction:** on `__APPLE__ && OPENMW_GL4ES_MANUAL_INIT`, make OSG `getGLExtensionFuncPtr` return `gl4es_GetProcAddress(funcName)`; keep the existing Apple resolver unchanged for all other builds. Prepared files are `ios/patches/osg-route-gl-entry-points-through-gl4es.patch`, `ios/cmake/apply-osg-patch.cmake`, and `patches/openmw/0002-ios-route-osg-gl-entry-points-through-gl4es.patch`. The patch changes entry-point ownership only—no shader strings, renderer settings, SDL context version, or GL4ES conversion rules.

## Section 5 — build pipeline

46. **Original workflow:** `.github/workflows/ios.yml`, historically displayed as `Build iOS`; representative run `31878221600` at `71227ff`.
47. **Original representative duration:** approximately 75m02s.
48. **Complete representative step timing:** sorted below.

| Step | Wall time | Classification |
|---|---:|---|
| Gate 2 dependency build/configure | 34m13s | full qualification; cacheable on fast path |
| Gate 5 real OpenMW compile/link | 22m17s | development-critical |
| Gate 3 dependency/deployment/registrar validation | 14m05s | change-conditional/full qualification |
| Install tools | 49s | required prerequisite |
| Gate 1 source/patch validation | 34s | development-critical cheap validation |
| Gate 4 dependency link smoke | 27s | full qualification |
| Gate 6 real bundle validation/package | 21s | development-critical reduced form |
| Xcode selection | 14s | development-critical |
| Checkout | 16s | required |
| Source-download cache | 14s | required optimization |
| Pinned CMake | 10s | required prerequisite |
| Executable transplant + upload | 16s | historical diagnostic |
| Production-plist transplant + upload | 22s | historical diagnostic |
| Bundle-probe configure/build/package/upload | 14s | historical diagnostic |
| Production artifact upload | 7s | development-critical, one artifact only |
| Detailed diagnostics + upload | 9s | failure/full qualification only |
| Link-smoke/preflight overhead outside build | 1s | full qualification |
| Top-level-files transplant | 1s, then failure | obsolete; encoded the pre-WO12 layout |
| Remaining setup/cleanup | about 23s | required runner overhead |

49. **Existing gates/checks:** Gate 1 exact source/patch validation; Gate 2 clean dependency build/configure; Gate 3 dependency, deployment-target, registrar and inventory validation; Gate 4 static dependency link smoke; Gate 5 real OpenMW production compile/link; Gate 6 real bundle/package/Mach-O validation; plus bundle probe and executable/plist/top-level transplant products.
50. **Classification:** Gate 1's cheap validation, real Gate 5 compile/link, and a reduced real Gate 6 are development-critical. Dependency construction is change-conditional and cached. Detailed Gate 3 and Gate 4 are full-qualification checks. Probe/transplant products are historical diagnostics; the top-level transplant is obsolete after the proven bundle-layout correction.
51. **Historical checks removed from default path:** link-smoke, bundle probe, executable transplant, plist transplant, top-level-files transplant, redundant product uploads, giant link-map-in-app packaging, and always-on detailed diagnostic collection. Useful scripts remain available; full qualification remains separate.
52. **Fast workflow:** `.github/workflows/ios-fast.yml`, workflow name `iOS Fast Development`.
53. **Full workflow:** `.github/workflows/ios.yml`, renamed `iOS Full Qualification` in source and limited to manual dispatch or `ios-qualification-*` tags. It retains Gates 1–6 and useful diagnostics; obsolete top-level-transplant execution is disabled, not deleted.

    **Verified trigger policy:**

    | Event | Fast Development | Full Qualification |
    |---|---|---|
    | Ordinary non-documentation push | Yes, except the protected historical `delivery/openmw-ios` branch | No |
    | Pull request with a non-documentation change | Yes | No |
    | Documentation-only push or pull request | No | No |
    | Manual `workflow_dispatch` | Yes, when Fast is explicitly selected | Yes, only when Full is explicitly selected |
    | Push of tag `ios-qualification-*` | No | Yes |

    Neither workflow declares `workflow_run`, `workflow_call`, or a cross-workflow `needs` relationship. Full Qualification is not a dependency of Fast Development and is not launched beside an ordinary development push. The simultaneous runs `31894641227` (Fast) and `31894070017` (Full) were a one-time, explicitly initiated benchmark/validation pair only. The ordinary branch push of `195760b` started Fast run `31899004175` and did not start a new Full run; the only Full run visible for the branch remained the older manually dispatched run `31894070017` at `c2b6f39`.
54. **Cache design:** separate source-download, vcpkg binary, and qualified incremental build-state caches. The build-state cache contains pinned source checkouts, vcpkg installed products, GL4ES/LuaJIT outputs, the prefix, and the Xcode/CMake OpenMW build tree. A fingerprint marker is validated before reuse.
55. **Cache keys:** ABI key includes pinned dependency inputs, manifests/triplet, build scripts, deployment target, architecture, Xcode identity, and OSG integration patches. Source key includes OpenMW patches, GL4ES patches, and iOS sources. Exact source hits are preferred; same-ABI fallback enables controlled incremental rebuilds.
56. **Invalidation graph:** toolchain/deployment/triplet/dependency-build/OSG-integration changes invalidate the broad state; OpenMW source/patch changes restore same-ABI state then reconfigure/rebuild affected objects; GL4ES source/patch changes rebuild GL4ES and relink; iOS bridge changes rebuild bridge objects and relink. Bootstrap resets pinned managed sources only when patch fingerprints change under the CI-only `OPENMW_REFRESH_PATCHES=1` contract.
57. **Dependency cache contents:** vcpkg downloads and binary packages; `build/vcpkg_installed`; GL4ES build/product; LuaJIT build/product; prefix-installed pinned dependencies; OpenMW/OSG/MyGUI build objects and generated Xcode state. The fast path checks architecture/platform/bundle/resource integrity before publishing regardless of cache hit.
58. **Cold build time:** corrected Fast run `31899004175` succeeded in 1h45m18s. Dependency/configure took 46m46s; real production compile/link took 52m50s; staging, Apple bundle/resource validation and packaging took 29s; artifact upload took 2s; saving the qualified incremental state took 3m07s. The earlier cold run `31894641227` reached the same valid product boundary in 1h17m03s but failed on stale report filenames after validation.
59. **Warm build time:** Fast-only run `31929405045` succeeded in 6m43s (job wall time 6m38s). The qualified state restored in 1m56s; dependency/configuration took 1m38s instead of 46m46s cold; real production compile/link took 57s instead of 52m50s cold; staging/Apple bundle validation/package took 29s; upload took 4s. The workflow uploaded exactly one artifact (`OpenMW-iOS-fast-5`, 38,927,908 bytes). Its unsigned IPA is 38,895,389 bytes with SHA-256 `45AAF440DC38BAE549769BBBA084E0DA6A5B8579FDDA27C9D8D1D240D1906710`. Relative to the corrected 1h45m18s cold run, the warm end-to-end path is 93.6% faster (15.7x speedup).
60. **OpenMW incremental build time:** controlled Fast-only `benchmark_mode=openmw` run `31930224686` succeeded in 9m08s end to end (job 9m02s). Cache restore took 2m30s; dependency/configuration took 2m00s; recompiling the touched OpenMW translation unit and relinking the real production target took 1m38s; stage/validate/package took 44s; upload took 25s. No third-party dependency reconstruction ran. Exactly one artifact (`OpenMW-iOS-fast-6`, 38,927,909 bytes; Actions digest `87c37f56e8e975dbd3d816415f18f3df77be04341f8cee75a283bf2ab2097b6b`) was published. Its IPA SHA-256 is `A9D31E6019C73A7DEB614814BF1160A6025726B791C4F6BD66E432FE1B9552F7`; the production executable and resource-manifest hashes remain exactly `4d76ffd...9853` and `8d4cdb2e...4760` respectively.
61. **GL4ES incremental build time:** controlled Fast-only `benchmark_mode=gl4es` run `31933625589` succeeded in 10m40s end to end (job 10m35s). Cache restore took 2m44s; touching `deps/gl4es/src/gl/shader.c` caused GL4ES-only rebuild/configuration in 2m35s; relinking the real OpenMW production target took 1m35s; stage/validate/package took 38s; upload took 2s. No unrelated third-party dependency rebuild occurred, so the GL4ES invalidation path is qualified. Exactly one artifact (`OpenMW-iOS-fast-7`, 38,927,909 bytes; Actions digest `312753cc0f8d5e60412622c07ff5049f45f9cf5efd7389c20225b74ebd81c5d0`) was published. Its IPA SHA-256 is `5870B5098D45AF7E4E2095802A02D1E2255E138D1C52BEC0C78AE55194EEBC29`; the unchanged executable/resource-manifest hashes are `4d76ffd...9853` and `8d4cdb2e...4760`.
62. **Bridge-only build time:** not run. After the warm, OpenMW-only, and directly relevant GL4ES-only measurements, the user explicitly closed further Track B benchmarking; avoiding another bridge-only run preserves focus and prevents redundant CI spend.
63. **Artifact size/count before:** representative run `31878221600` uploaded five artifacts totaling 533,327,637 bytes: production 214,613,853; executable transplant 154,786,164; plist transplant 154,786,396; bundle probe 80,716; diagnostics 9,060,508. The production artifact could also carry the linker map inside the app.
64. **Artifact size/count after:** successful cold Fast run `31899004175` uploaded exactly one seven-day artifact, `OpenMW-iOS-fast-4`, totaling 38,927,912 bytes with Actions artifact digest `aa0f1b5e2bed32b5c833752bfcff66bedb64bcd740db1f2176171f4899dbaa13`. It contains the unsigned production IPA plus concise manifest/hash/timing evidence; the link map is removed from the staged app. Failure uploads only targeted logs.
65. **Proof production target remains real:** the fast workflow invokes `xcodebuild ... -target openmw`, extracts the final `openmw` link command, stages the resulting `openmw.app`, and runs the existing real-bundle verifier. No probe/smoke/transplant executable can satisfy the artifact step.
66. **Proof compile/link errors hard-fail:** shell `set -euo pipefail` surrounds `xcodebuild`; failure prevents staging/package/upload and instead publishes targeted failure diagnostics.
67. **Proof bundle-collision guard remains:** fast staging runs `scripts/verify-bundle.sh`, which enforces the top-level `resources`/`Resources` collision guard, root plist/executable, ARM64/iOS Mach-O, relocation manifest, and Apple bundle API reciprocal validation.
68. **Fast-vs-full comparison:** the one-time manually dispatched Full Qualification run `31894070017` succeeded in 1h51m44s. Its major steps were Gate 2 dependency/configure 54m17s, Gate 3 dependency/registrar qualification 22m37s, Gate 4 link smoke 40s, Gate 5 real OpenMW compile/link 30m22s, and Gate 6 bundle/package 24s. It published the normal production IPA plus four qualification/diagnostic artifacts. Corrected Fast cold run `31899004175` and warm run `31929405045` both produced executable SHA-256 `4d76ffd176a1854636b434e4967a7e2df99a3cfdd4570eab5408de8659fc9853` and resource-manifest SHA-256 `8d4cdb2e34817b16386fb4a71104597a12b977ce4b0365a6d68bf28444904760`; both passed the same Foundation/CoreFoundation bundle-identity and reciprocal collision checks. Their IPA hashes differ because ZIP metadata is nondeterministic, not because the production executable/resources differ. No further Full run is part of the incremental benchmarks.
69. **Commits:** CI-only commits are `971ee59` (fast workflow), `0508ff3` (full qualification separation), `96db8e1` (OSG-patch cache invalidation), `c2b6f39` (supported cache-hash context), `c62a46a` (pinned ShellCheck prerequisite), and `195760b` (correct fast artifact manifest paths after cold run `31894641227` exposed stale filenames). The graphics correction is separately isolated as `cbb5fd4` (`fix(ios): route OSG GL entry points through GL4ES`) and was not included in the baseline CI benchmark runs.
70. **Remaining bottlenecks:** cold third-party construction and the first production compile remain large (46m46s and 52m50s in the corrected cold Fast run). On warm/incremental runs, fixed runner overhead now dominates: qualified-state restore takes roughly 2–3 minutes and pinned-tool installation 47–94 seconds. Actual no-change production compile/link is 57s; an OpenMW-object rebuild/relink is 1m38s; GL4ES rebuild plus relink is 4m10s across the two measured build steps. Further optimization should target cache archive size/restore and preinstalled tooling, not weaken validation or cache unrelated ABI state.

## Section 6 — next action

71. **Stop condition:** graphics reached **Stop A / Stop B**—the Android differential and iOS link/runtime evidence prove GL4ES conversion bypass. Track B reached **Stop E**: cold, warm, OpenMW-only, and GL4ES-only Fast measurements are complete; the one-time Full Qualification succeeded; actual triggers prove ordinary development pushes run only Fast while Full remains manual/qualification-tag-only and independent.
72. **Corrected test build produced:** no. The narrow OSG routing correction is preserved separately in local commit `cbb5fd4`, but was intentionally not pushed/built/device-tested in this work order; doing so would begin the Work Order 14 validation rather than add information to the now-complete baseline benchmarks.
73. **Test artifact hash:** not applicable; no corrected graphics artifact was produced. Baseline benchmark artifact hashes are recorded in items 59–61.
74. **Device result:** no Work Order 13R device test has been performed; the Work Order 12 content-qualified runtime baseline remains authoritative.
75. **Recommended Work Order 14:** apply/qualify the prepared Apple-only OSG entry-point routing patch with the fast workflow, statically verify the final link/function-lookup path now reaches `gl4es_GetProcAddress`, perform one controlled device run with first-shader logging capped to GUI vertex/fragment plus one object shader, and stop at the first converted-source/compiler result. Treat viewport sizing, stale VFS configuration, and Lua menu errors as separate follow-on scopes unless the corrected shader path makes one independently primary.
