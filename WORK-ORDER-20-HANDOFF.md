# OpenMW iOS — Work Order 20 Handoff

## Outcome

Work Order 20 reached **Condition C — the resource fix resolved the Lua/MWUI error, but the main-menu milestone still failed**. The built-in `vfs-mw` relocation is now correct and the prior `Misc::Color(nil)`/dependent menu-script failures are gone. The controlled, no-touch device run was nevertheless visually unchanged: a tiny Morrowind/Bloodmoon loading image in a mostly black landscape surface. Instrumentation localized the remaining presentation defect to a drawable-size query made before SDL creates the UIKit GLES view.

1. **Starting branch:** `fix/gl4es-modeltoclip-linkage`; Work Order 20 work was isolated on `codex/wo20-main-menu-milestone`.
2. **Starting HEAD:** `abdc29459c1b3d7090cef45bdf49e49916099c81`.
3. **Qualified renderer baseline:** OSG→GL4ES routing `cbb5fd4587109aab22c206ac27951a4ceb070d27`; main-less GL4ES crash guard `a6ab65a677d8c74cdf01aea982b372b9fe17f5df`; initializer correction `6076e7b7c91f013ee801ef0abeb3e0037cc4dd90`; modelToClip correction `f835091db7852e01cb8bd0a91ed2cedfa082c449`. Shader compilation and program linking were clean, content loaded, music played, and there was no crash/jetsam.
4. **Work Order 19 state:** `modelToClip` link failures 4→0, `glLinkProgram ... FAILED` 4→0, shader compile failures 0; process survived. Visible output remained a tiny loading region and no usable menu was proven.
5. **Current user-visible baseline:** unchanged after Work Order 20: tiny Morrowind/Bloodmoon loading artwork in a largely black landscape screen. The user explicitly reported, “We are exactly where we were.”
6. **Keyboard observation caveat:** no tapping was performed in the Work Order 20 passive baseline. Earlier native-keyboard presentation remains an uncontrolled observation and is not evidence of menu progression.
7. **Exact Lua failure before correction:** `scripts/omw/mwui/constants.lua:8` passed nil to `Misc::Color(std::string_view)` while evaluating `util.color.commaString(core.getGMST("FontColor_color_header"))`.
8. **Nil value identity:** `core.getGMST("FontColor_color_header")` returned nil.
9. **Expected source:** fallback GMST `FontColor_color_header`, supplied by the configured OpenMW fallback values and copied into the ESM GameSetting store by `scripts/omw/esmfallbacks.lua`.
10. **Complete MWUI dependency chain:** packaged `openmw.cfg` → mount `openmw-resources/vfs-mw` → load `esmfallbacks.lua` → populate fallback GMSTs → `core.getGMST` returns header color → `mwui/constants.lua` constructs `Misc::Color` → MWUI and Settings menu scripts initialize.
11. **Lua error classification:** dependent symptom, not an independent root cause. Its upstream cause was the stale bundled VFS path.
12. **Stale VFS path source:** the generic Apple/iOS CMake branch selected/configured the wrong local config content, leaving `data=./resources/vfs-mw` after Work Order 12 renamed the bundle directory.
13. **Actual packaged VFS location:** `App.app/openmw-resources/vfs-mw`.
14. **VFS contents relevant to MWUI:** notably `scripts/omw/esmfallbacks.lua`, plus the bundled Lua/settings resources. The packaged tree was complete: 405 entries, 349 files, 2,289,102 bytes, with zero missing/unexpected/changed-hash/type-mismatch entries.
15. **VFS→Lua causal result:** proven. After mounting the actual path, `esmfallbacks.lua` changed from absent to loaded, `Misc::Color` errors changed 1→0, and `Can't start Menu` errors changed 4→0.
16. **Android resource-path comparison:** the useful architectural pattern is a distinct bundled OpenMW resource root mounted separately from user Morrowind data. Work Order 20 preserved that pattern without recreating forbidden top-level lowercase `resources`.
17. **UIKit dimensions:** `UIScreen` points `480×320`; `scale=3.000`, `nativeScale=3.000`; reported native pixel dimensions `960×1440` (portrait ordering while the application view was landscape).
18. **Native drawable dimensions:** not successfully observed after the GLES view was created. The pre-context SDL query reported `480×320`; this is the key diagnostic limitation and the next target.
19. **SDL window dimensions:** `480×320` logical units.
20. **SDL drawable dimensions:** `480×320` at the Work Order 20 query point.
21. **OSG GraphicsContext dimensions:** traits `480×320`.
22. **OSG viewport dimensions:** camera `0,0,480×320`.
23. **Native `glViewport`:** `0,0,800×600` at the first bounded swap diagnostic.
24. **First viewport divergence:** `Engine::createWindow` calls `SDL_GL_GetDrawableSize` before `GraphicsWindowSDL2::init` calls `SDL_GL_CreateContext`. In SDL 2.32.10, the UIKit backend falls back to `SDL_GetWindowSize` when the controller view is not yet `SDL_uikitopenglview`; therefore the logical `480×320` seeds OSG traits before the retina GLES backing exists. The existing `SDL_WINDOW_ALLOW_HIGHDPI` flag was already present, so its absence is not the cause.
25. **Expected main-menu lifecycle:** resource/VFS initialization → MyGUI managers/resources → `WindowManager::initUI` reads the MyGUI view size and constructs `MainMenu` from `openmw_mainmenu.layout` → Lua MWUI/Settings initialization → main-menu state/update → first menu frame/presentation.
26. **Last successful menu stage:** MyGUI RenderManager, ResourceManager, LayerManager, FontManager, LayoutManager, and Gui initialized; `openmw_mainmenu.skin.xml` loaded; `esmfallbacks.lua` and the MWUI/Settings menu scripts loaded without the prior errors; the engine recorded a first complete frame.
27. **First failed menu stage:** user-visible presentation of a correctly sized, usable menu. No new Lua or shader exception marks this boundary; the captured viewport/drawable state is inconsistent and the screen remains on the tiny loading image.
28. **Complete causal blocker graph:** preserved in `build/work-order-20/analysis/causal-blocker-graph.md`. In summary: stale VFS mount → missing fallback GMST → `Misc::Color(nil)` (resolved); independently, pre-context drawable query → logical-size OSG traits → inconsistent camera/native viewport → tiny presentation (unresolved).
29. **Issue classifications:** stale config path = resolved primary cause; absent `esmfallbacks`/nil color/menu-script errors = resolved dependent symptoms; pre-context size capture = unresolved primary presentation blocker; tiny rectangle = dependent symptom; absolute user-data UUID = out of scope; MyGUI controller warnings = non-blocking.
30. **Authorized correction set:** Condition B before build authorized two independent narrow corrections: mount the relocated VFS root and use drawable dimensions for GL4ES/OSG sizing. Device evidence later proved only the first correction complete.
31. **Correction commit 1:** `f53c4dace0bfba3088207c605b8a795aef6b11ca` — `fix(ios): mount relocated built-in vfs resources`.
32. **Correction commit 2:** `87297d8f5219cb936516b2f7321951485f97562e` — `fix(ios): size GL4ES framebuffer from drawable pixels`. Patch-application follow-ups: `61782769811b45b92e20e05cda8523c0285c70f6` and `499ceb28b0087774fbb0b7a39c7f4104ac56d555` preserved canonical context only.
33. **Regression tests:** focused resource/viewport tests passed; fresh sequential application of patches 0001–0005 passed; full Python suite ran 44 tests with 2 skips and 2 unrelated Windows errors caused by trying to execute macOS shell scripts as Win32 programs. Production Apple bundle/resource qualification passed with zero resource loss.
34. **Fast Development run:** GitHub Actions run `32000078567`, attempt 2, job `95313242009`; completed successfully.
35. **Full Qualification:** did not run. The branch run list contains only `.github/workflows/ios-fast.yml` runs.
36. **Cache restoration:** source-download cache hit; vcpkg and qualified build-state caches missed. Fingerprint: `ios-fast-v4-xcode16.4-ios16.3-arm64-edd5fbcd7e18a5d33a4de616e039704d860dd513c9140bfb34ccbee5f1003987`; scope `refs/pull/8/merge`, recorded base `fix/gl4es-modeltoclip-linkage`. This is a cache-scope regression, not a runtime/build correctness failure.
37. **Build duration:** job wall clock `1h27m45s` (07:18:36–08:46:21 UTC); dependency/configuration `40m30s`; production compile/link `40m55s`; stage/validate/package `48s`; artifact upload `4s`.
38. **Production executable SHA-256:** `DF48702BA1E7A001E8F238A2669B5B8D7DCBE6446F20F93FD1B6410B8317B268`.
39. **IPA:** 39,063,653 bytes; SHA-256 `FBEA5FF9FE6A6E5A426BB6C24C3AC63F25D4AC0F49A4496544EC628B58557CD3`.
40. **Current game-data validation:** data container `/private/var/mobile/Containers/Data/Application/0253E674-C0C0-4A2B-9B52-632570B811E5`; all six required Morrowind/Tribunal/Bloodmoon BSA/ESM files were present under `Documents/OpenMW/Morrowind/Data Files`. Device-readback cfg SHA-256 `34245693B12A3FC9000EDD580B971FBB53081358EDCE111A8FFB962400B65887` used the current path.
41. **Logging readiness:** bounded syslog capture was active before launch; post-run `openmw.log`, `MyGUI.log`, and `Library/OpenMW/startup.jsonl` were recovered. No new 2026-08-17 OpenMW crash or jetsam report appeared; only the seven historical 2026-08-16 reports remained.
42. **User launch timestamp:** 2026-08-17 14:41:47 IST (09:11:47 UTC).
43. **Passive no-touch baseline:** unchanged tiny loading artwork on a mostly black landscape screen. The user did not touch the screen during the requested passive phase.
44. **Controlled interaction:** none performed; this preserves a clean comparison.
45. **`Misc::Color` before/after:** `1 → 0`.
46. **MWUI initialization before/after:** four `Can't start Menu` errors and four error-level log entries → zero; the MWUI and Settings menu scripts were listed without a subsequent Lua exception.
47. **VFS warning before/after:** stale `No such dir: .../resources/vfs-mw` `1 → 0`; the new log positively mounts `App.app/openmw-resources/vfs-mw` and loads `esmfallbacks.lua`.
48. **Viewport before/after:** visually unchanged. Work Order 20 measured UIKit `480×320` points at scale 3, pre-context SDL drawable/OSG traits/camera `480×320`, and native viewport `800×600`. The attempted callback correction did not alter the visible rectangle.
49. **Visible rendering classification:** loading screen only, confined to a tiny rectangle; no proven partial menu.
50. **Main-menu result:** not visibly rendered and not usable. The clean MWUI logs show resource/Lua readiness but do not justify claiming a visible menu state.
51. **Music/audio:** `openmw.log` records playback of `music/special/morrowind title.mp3`; the user did not separately reconfirm audio in the final Work Order 20 message.
52. **Process lifetime:** survived through the passive screenshot and evidence collection; no orderly termination marker was captured during that window. A later opportunistic process query lost the wireless service connection and is not used to infer termination.
53. **Crash/jetsam:** none new; device inventory showed only the seven historical 2026-08-16 OpenMW crash reports.
54. **Highest observable runtime milestone:** complete content/resource/MWUI initialization and first engine frame with loading artwork and title-music playback, but still no correctly presented usable main menu.
55. **Stop condition:** **Condition C**.
56. **Strongest causal conclusion:** the stale bundled VFS path was the direct cause of the nil color and MWUI/Settings startup errors, and that chain is fixed. It was not sufficient to change the visible milestone. The remaining presentation failure begins when OpenMW asks for drawable size before SDL has replaced its generic UIKit view with the high-density GLES view; logical `480×320` is then frozen into OSG traits, while later GL state reports `800×600`.
57. **Recommended Work Order 21:** isolate presentation sizing only. In a diagnostic copy, record window flags/view class/backing dimensions immediately before and immediately after `SDL_GL_CreateContext`; refresh OSG traits/camera and the GL4ES main-FBO callback from the post-context backing size; reconcile landscape orientation and explain the later `800×600` viewport. Add a resize/orientation propagation test, use no fixed device resolution, preserve the now-qualified VFS/MWUI and shader patches, run Fast Development only, and perform one controlled no-touch device validation. Do not modify Lua/resources again unless contradictory evidence appears.

## Evidence hashes

- `openmw.log`: `D856F85AED4A5DA33D14328FDD8BAA99D2526F3AF64D91B8CF647068516FE13B`
- `MyGUI.log`: `0035374E8D812C93F8A0E555EC2FBEBE26C994A452BD051C0A636D554549DB96`
- `startup.jsonl`: `5E03861E0D4E13C8CD0FD59505BF18818316A13C6A63286C73C98C2568693432`
- bounded syslog: `999159A35B209E629909B0922DEBC7264B6984B2A1DE29DB75E68A22F63AF670`
