# OpenMW iOS Work Order 16 Handoff

## Outcome

**Condition E — native crash eliminated.** The corrected build installed and reached a complete engine frame with Morrowind/Bloodmoon loading artwork and title music. It remained alive for approximately 15.4 seconds, well beyond the historical 1–2 second crash boundary, until iOS recorded an explicit user-initiated app-switcher termination (`0xDEADFA11`). No new OpenMW crash report or jetsam report appeared. The tiny viewport and already-known debug-shader failures remain; they were not changed in this work order.

## Required evidence

1. **Starting branch:** `work/wo13r-android-fast-ci`.
2. **Starting HEAD:** `b1faab136cf55e38a34cb10a3efa160faa7fde7a`.
3. **Pinned GL4ES revision:** `c9895df34cd466c23bc60c2bd3db3d87e98fcbe7`.
4. **Work Order 15 crash signature:** seven independent iOS crash reports reproduce `EXC_BAD_ACCESS / SIGSEGV` at null address through `_platform_strchr+12 -> ConvertShader+12072 -> redoShader+484 -> gl4es_glLinkProgram+748 -> osg::Program::PerContextProgram::linkProgram` on the OSG graphics thread.
5. **Upstream GL4ES search result:** official GL4ES HEAD `81547d986798e876de8b434193920b606a72363f` (2026-07-25) still contains the same unsafe nested `strchr(gl4es_find_string_nc(...))` expression. The pattern originated in clip-vertex handling commit `868354d900cae934130abbde1a05074067661ddc`; no later exact no-main correction was found.
6. **Android GL4ES comparison result:** the recent OpenMW Android reference uses NG-GL4ES (effective reference around `a26bd21c29126039c08f4bae60f47a6bf79ed786`) and avoids this code path through different `gl_ClipVertex` replacement semantics. It provides no directly applicable null-guard backport and was not adopted wholesale.
7. **Existing upstream fix found:** no.
8. **Exact faulty source/function:** pinned `src/gl/shaderconv.c`, `ConvertShader`, in the `isVertex && need && need->need_clipvertex` propagation branch. It passed the nullable result of `gl4es_find_string_nc(Tmp, "main")` directly to `strchr`.
9. **`need_clipvertex` semantics:** program linking merges shader requirements across all attached shader objects. `redoShader` reconverts each shader with the merged requirements. Each vertex unit needs the clip declaration, but main-body clip insertion applies only to the unit that owns the executable `main()`.
10. **Why a main-less shader is legitimate:** OpenMW attaches `@link` vertex helper/library shaders as separate shader objects. For example, `lib/core/vertex.glsl` provides helper functions without `main()`, while the root vertex shader owns `main()` and may use `gl_ClipVertex`.
11. **Correction design:** split token lookup and opening-brace lookup into the production helper `gl4es_find_string_opening_brace`. Return `NULL` when either lookup fails. Continue inserting the shared clip declaration, skip only main-body insertion for main-less/malformed units, and preserve insertion for the entry-point shader.
12. **Files changed:** `patches/gl4es/0002-handle-mainless-linked-shaders.patch`, `validation/fixtures/gl4es_mainless_linked_shader.c`, and `validation/test_gl4es_mainless_linked_shader.py`.
13. **Exact GL4ES patch:** `patches/gl4es/0002-handle-mainless-linked-shaders.patch`. It adds the null-safe helper in `string_utils.c/.h` and replaces only the unsafe nested expression in `shaderconv.c`.
14. **Proof OpenMW shaders were not modified:** commit `a6ab65a677d8c74cdf01aea982b372b9fe17f5df` contains no OpenMW source or shader file change.
15. **Proof OSG routing was not changed:** the correction commit contains no OSG patch/build change; Work Order 14 commits `cbb5fd4587109aab22c206ac27951a4ceb070d27` and `b1faab136cf55e38a34cb10a3efa160faa7fde7a` remain intact.
16. **Regression fixture source:** `validation/fixtures/gl4es_mainless_linked_shader.c`. It links directly with production `string_utils.c`, models a helper vertex unit without `main()`, an entry unit with `main()`, and a malformed `main` without `{`.
17. **Fixture result before fix:** the fixture's isolated legacy expression terminates non-zero by dereferencing the null token-search result.
18. **Fixture result after fix:** macOS Fast source validation passed; the production helper skips the main-less unit and still inserts clip handling into the entry-point shader.
19. **No-main NULL test:** passed in macOS Fast source validation.
20. **No-opening-brace test:** passed in macOS Fast source validation.
21. **Sibling unsafe-pattern audit:** no other active nested `strchr(gl4es_find_...)`, `strstr(gl4es_find_...)`, or `strlen(gl4es_find_...)` pattern exists in the same pinned converter/string-utils scope. Existing iterative `gl4es_find_string_nc` uses assign then test in loop conditions.
22. **Commit:** `a6ab65a677d8c74cdf01aea982b372b9fe17f5df` (`fix(gl4es): handle main-less linked shader units`) on `fix/gl4es-mainless-linked-shader`.
23. **Fast Development run ID:** `31946315269`, attempt 2, successful: <https://github.com/arjunyerevan95-dot/OpenMWiOS/actions/runs/31946315269>.
24. **Proof Full Qualification did not run:** branch push triggered only `iOS Fast Development`; `iOS Full Qualification` remains `workflow_dispatch` or `ios-qualification-*` tag only.
25. **Fast build duration:** job start `2026-08-16T12:33:11Z`, completion `13:47:57Z`: `1h 14m 46s`. The unusually cold duration is attributable to cache scope, not the GL4ES correction.
26. **GL4ES rebuild duration:** not independently instrumented inside the configure block. GL4ES rebuilt within `configure_and_dependencies`, whose measured duration was `2,055s` (`34m15s`). Do not misrepresent the entire block as GL4ES-only time.
27. **OpenMW relink duration:** the measured real production compile/link block was `2,133s` (`35m33s`). This included the real OpenMW target and final link; it was not separately split into compile versus link timing.
28. **Cache behavior:** source-download cache hit. Both the vcpkg binary cache and qualified incremental state missed despite matching branch-independent textual keys, confirming GitHub Actions branch cache visibility as the cold-build cause. The exact vcpkg key was `vcpkg-ios-v3-xcode16.4-4ee68f496c26e69a1f7c59f73ec427f00b39e764f2dc6cb26f56750f54383f3e`; the state key began `ios-fast-state-v3-macOS-X64-ios-fast-v3-xcode16.4-ios16.3-arm64-edd5fbcd...`.
29. **Executable SHA-256:** `51dd51cc827fccf4ef4094e9f0f6d61caf50de58a15778abbfe1cb1f8de339f4`.
30. **IPA SHA-256:** `4428561D09A8774F12DADFD47ADC21FDF48B8B8B8A9F721A6AA83914DDFE87ED`; size `39,055,034` bytes; local path `build/work-order-16/artifacts/OpenMW-iOS-fast-9/artifacts/OpenMW-iOS-unsigned.ipa`.
31. **Device install result:** successful through the established SideStore path. Installed bundle identifier: `org.openmw.ios.7CP756AU4P`. Current bundle container: `/private/var/containers/Bundle/Application/D56406D8-D633-49AC-A21E-804F63735F94/App.app`. Current data container: `/private/var/mobile/Containers/Data/Application/A5BFE920-162C-494B-8A96-5E88EF0A62D6`.
32. **Launch timestamp:** OpenMW log began `2026-08-16 19:47:47.710 +05:30`; SpringBoard recorded the open request at `19:47:48.143`.
33. **Loading-screen result:** recognizable Morrowind/Bloodmoon loading artwork rendered and remained visible. Screenshot: `build/work-order-16/device/post-run/wo16-visible-result.jpg`, SHA-256 `56BC2BE9268F9D27AEC32BF39CD342319FC55AF4472CC56A130CD2A92760E64C`.
34. **Music result:** Morrowind title music played; `openmw.log` records `Playing "music/special/morrowind title.mp3"` at `19:47:48.667`.
35. **Survival time:** approximately `15.4s`, from the SpringBoard open request at `19:47:48.143` to explicit app-switcher termination at `19:48:03.511`. This exceeds the old native-crash boundary by an order of magnitude.
36. **Crash report presence:** no new OpenMW `.ips` report and no new jetsam report. Post-run listing contains only the seven Work Order 15 reports (`163221`, `163225`, `163231`, `163233`, `163234`, `163236`, `163239`).
37. **Old `_platform_strchr` crash status:** eliminated in this run. Neither the bounded console nor crash-report delta contains `_platform_strchr -> ConvertShader -> redoShader -> gl4es_glLinkProgram`.
38. **New crash signature:** none. The only termination was SpringBoard's explicit `killed from app switcher`, exception code `User Initiated Quit (0xDEADFA11)`, report type `none`.
39. **Debug-shader initializer error status:** persists unchanged: two `Initializer not allowed` diagnostics, one each for `compatibility/debug.vert` and `.frag`.
40. **`useAdvancedShader` error status:** persists unchanged: two `Use of undeclared identifier 'useAdvancedShader'` diagnostics.
41. **GL error status:** raw GLSL `#version 120` and `centroid` errors remain absent. `invalid operation` warnings increased from one in the crashing Work Order 15 log to four because execution now survives long enough to attempt four failed program links; `invalid enumerant` remains one. This is a new post-crash shader/program boundary, not regression of the fixed SIGSEGV.
42. **Viewport status:** still a tiny centered/lower-left-ish loading rectangle on an otherwise black landscape surface. No viewport correction was made.
43. **Lua error status:** unchanged. Root `Misc::Color(std::string_view)` nil error persists, followed by dependent `MWUI`/`Settings` nil errors.
44. **Stale VFS warning status:** unchanged: `App.app/./resources/vfs-mw` is still reported missing while the relocated `openmw-resources` path is used successfully elsewhere.
45. **Highest runtime boundary reached:** `startup.jsonl` records `renderer_initialization` and `first_frame` at `2026-08-16 14:17:48 +0000`; the engine rendered loading artwork, played music, remained alive, and stalled before a usable main menu.
46. **Stop condition:** **Condition E — native crash eliminated.**
47. **Strongest causal conclusion:** the main-less linked-shader null-safety correction directly removes the seven-report GL4ES link-time SIGSEGV without modifying OpenMW shaders or OSG routing. The next earliest actionable runtime boundary is the converted debug-shader initializer/`useAdvancedShader` program failure; viewport sizing is a separate visible defect.
48. **Recommended Work Order 17:** first land/validate the separate cross-branch cache-scope change on the next normal Fast run, then capture the exact GL4ES-emitted `compatibility/debug.vert/.frag` source and correct only the proven global-initializer/`useAdvancedShader` conversion defect using recent Android/GL4ES precedent. Preserve the viewport, Lua, VFS, and stable-container-path issues as separate work orders. One device validation maximum after the debug-shader correction is proven.

## Post-stop Fast Development cache steering

Implemented locally after Condition E as a separate CI-only commit `2f84b36` (`ci: make fast caches cross-branch by fingerprint`). It was deliberately **not pushed**, so it did not rebuild the Work Order 16 artifact.

- A feature-branch push dispatches the exact source SHA to `ios-fast.yml` on the canonical `main` reference. The real build therefore reads/writes the repository-default-branch cache scope, which GitHub makes visible across branches.
- Cache keys contain no branch name. The v4 ABI fingerprint covers pinned revisions, vcpkg manifest/triplet, build scripts/options, iOS dependency patches, architecture, deployment target, and pinned Xcode/toolchain identity. The exact source fingerprint separately covers OpenMW patches, GL4ES patches, and iOS source/configuration.
- Exact source matches use the exact state key. ABI-identical source changes may restore only the validated incremental base; bootstrap refreshes changed sources and the real production build performs the resulting component rebuild/relink. ABI mismatches are rejected fail-closed.
- Every Fast artifact will carry `cache-fingerprints.txt` with the exact source SHA, canonical cache ref, ABI fingerprint, source fingerprint, and any source-delta restore.
- `iOS Fast Development` triggers on non-document pushes and pull requests, or manually. Non-main pushes dispatch only the Fast workflow's canonical build. `iOS Full Qualification` remains manual (`workflow_dispatch`) or explicit `ios-qualification-*` tags; it is neither automatically launched alongside Fast nor a dependency of Fast.
- The next development work order must validate this naturally and report the exact keys, cross-branch restore, rebuilt/restored components, and duration. No benchmark or Full Qualification run was started here.

## Preserved preflight evidence

- Exact previously tested IPA: `build/work-order-14/runtime/OpenMW-WO14-Refreshed.ipa`, size `40,506,663`, SHA-256 `c16a2e3adc02e87caa2d50ff5c17bc43f2fc439efc85558f53cd6bd181c30e75`.
- Installed bundle identifier before update: `org.openmw.ios.7CP756AU4P`.
- Data container before update: `55CF54BE-A445-471E-9FB7-028DB08BBDC9`.
- Bundle container before update: `94A05703-862F-42F5-80D4-841DB6BBDCF1`.
- Apple device transport before update: usbmux Network/Wi-Fi, UDID `00008140-0000458108A2201C`.
- Current `openmw.cfg` data path matches data-container UUID `A5BFE920-162C-494B-8A96-5E88EF0A62D6` and points to `Documents/OpenMW/Morrowind/Data Files`; all six Morrowind/Tribunal/Bloodmoon BSA/ESM files were verified before the controlled launch.

## Preserved post-run evidence

- Raw Apple console: `build/work-order-16/device/logs/wo16-controlled-launch-syslog-utf8.jsonl`, size `365,677,461`, SHA-256 `4ECA2B33E3EDEEB9CFDAD820B1006D0E84478C360835DB1966FDCC4FF1A54724`.
- `openmw.log`: size `10,467`, SHA-256 `38B43226A7DDCD89538C1E4BB9154EA04EFB641934694677226685DDCF26FEC6`.
- `MyGUI.log`: size `18,112`, SHA-256 `206284AA7EB7960143DED11792F031436442DE1DE5D9D7F5ABCEEA6E2423127E`.
- `startup.jsonl`: size `39,209`, SHA-256 `9A1EEFBA37417D7F22D81D8600DBB1578854B63A28A23986D5460239DE2D42A4`.
- Post-run crash list: SHA-256 `5C7E1F36703DDFD071CD9E7A4AAE801169CE1AAE90A7A326A5EA4BF9371C3E70`.
