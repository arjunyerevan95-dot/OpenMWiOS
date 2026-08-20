# Work Order 21 Handoff

## Outcome

**Stop condition: CONDITION D — VISIBLE RENDER AREA MATERIALLY CHANGED BUT REMAINS WRONG.**

The post-context drawable correction made the predicted physical difference: the Morrowind loading image expanded from a tiny rectangle to a much larger centered 4:3 region. The proposition that pre-context SDL dimensions contributed to the tiny surface is therefore confirmed. It is not, however, a complete presentation model. SDL and OSG converge on the measured 1440×960 backing drawable, while the native viewport is still 800×600 before the first present. The large loading frame then remains frozen even though touch and audio demonstrate that OpenMW advances through the hidden main menu into the Imperial Prison Ship/Jiub sequence.

No further correction was made after this boundary.

## Required handoff

1. **Starting branch:** `codex/wo20-main-menu-milestone`.
2. **Starting HEAD:** `21ba9cd1f3ca1cc7388f506ded90275ec49953ab`.
3. **Current qualified renderer state:** Work Order 14 OSG→GL4ES routing (`cbb5fd4587109aab22c206ac27951a4ceb070d27`), Work Order 16 GL4ES main-less linked-shader guard (`a6ab65a677d8c74cdf01aea982b372b9fe17f5df`), Work Order 17 initializer correction (`6076e7b7c91f013ee801ef0abeb3e0037cc4dd90`), Work Order 19 modelToClip correction (`f835091db7852e01cb8bd0a91ed2cedfa082c449`), and Work Order 20 VFS/MWUI correction (`f53c4dace0bfba3088207c605b8a795aef6b11ca`) all remain present. Pinned revisions remain OpenMW `f4bec41444`, SDL 2.32.10, OSG 3.6.5/`01cc2b585…`, and GL4ES `c9895df…`.
4. **Work Order 20 visible baseline:** a tiny approximately 4:3 loading image in the lower-left/left-central part of an otherwise black landscape screen; no visibly usable main menu.
5. **Work Order 20 dimension baseline:** UIKit 480×320 points at scale 3; pre-context SDL window 480×320; pre-context SDL drawable 480×320; OSG traits 480×320; OSG camera 480×320; later native viewport 800×600.
6. **Complete current sizing timeline:** SDL creates a high-DPI landscape window → `Engine::createWindow` queries logical and drawable size before a GLES context exists → SDL UIKit falls back to the logical 480×320 window size → those provisional values seed OSG traits → `GraphicsWindowSDL2::init` creates the SDL GLES context and UIKit EAGL backing → post-context `SDL_GL_GetDrawableSize` returns 1440×960 → Work Order 21 reconciles OSG traits and OpenMW renderer settings to 1440×960 → camera viewport is set to 1440×960 → the direct native viewport query before first present still reports 800×600 → physical loading artwork is presented in a much larger but still 4:3 region.
7. **Pre-context SDL behavior:** `SDL_GetWindowSize=480×320`; `SDL_GL_GetDrawableSize=480×320` because the root view is not yet `SDL_uikitopenglview` and SDL returns the logical fallback.
8. **Post-context SDL behavior:** `SDL_GetWindowSize=480×320`; `SDL_GL_GetDrawableSize=1440×960` after the UIKit GL view/backing exists.
9. **Authoritative drawable source:** post-context `SDL_GL_GetDrawableSize`, backed by SDL UIKit's EAGL renderbuffer storage. UIKit independently reports a 480×320-point `SDL_uikitopenglview` with content scale 3.
10. **Authoritative drawable dimensions:** `1440×960` pixels.
11. **Source of 800×600 viewport:** 800×600 is the OpenMW default/configuration resolution (`settings-default.cfg`). Runtime evidence proves the native viewport still has this value immediately before first present, but Work Order 21 does not yet prove the final writer or why it survives the 1440×960 OSG-camera setup. It is classified as a stale configuration-derived late viewport state requiring Work Order 22 tracing.
12. **First incorrect sizing handoff:** the pre-context `SDL_GL_GetDrawableSize` result was copied into OSG traits as if it were authoritative framebuffer pixels.
13. **Selected correction architecture:** post-context reconciliation (Option B). OSG may retain provisional dimensions until context creation; immediately after successful context creation, query the real drawable and update OSG traits, then synchronize the OpenMW renderer resolution and establish the camera viewport before meaningful rendering.
14. **Files/functions changed:** `patches/openmw/0006-ios-reconcile-post-context-drawable.patch` modifies `OMW::Engine::createWindow` and `SDLUtil::GraphicsWindowSDL2::init`; `ios/openmw_ios_logging.h/.mm` add a one-shot UIKit metric marker; `validation/test_ios_post_context_drawable.py` and `validation/CMakeLists.txt` add regression coverage.
15. **Proof no device resolution was hard-coded:** the correction contains no 480×320, 800×600, 1440×960, iPhone model, or scale-factor constants. Dimensions come from SDL/OSG/UIKit runtime queries. Regression tests explicitly reject fixed-device sizing behavior.
16. **Logical-vs-drawable semantics:** `SDL_GetWindowSize` remains the logical point/window-coordinate source. Only framebuffer-pixel consumers use post-context `SDL_GL_GetDrawableSize`. Input and logical window behavior were not globally rewritten.
17. **OSG traits reconciliation:** `480×320 → 1440×960` immediately after successful `SDL_GL_CreateContext`.
18. **OSG viewport reconciliation:** camera before setup was unset; camera after reconciliation is `0,0,1440×960`.
19. **Projection/aspect handling:** OpenMW's video resolution settings are synchronized to 1440×960 before `RenderingManager` consumes them, so renderer aspect/projection and UI pixel resolution no longer retain the provisional 480×320 values.
20. **GL4ES viewport behavior:** OSG GL entry points still route through GL4ES. Work Order 21 did not alter GL4ES. The corrected OSG camera is 1440×960, but the direct native viewport observation remains 800×600 before first present, proving a remaining OSG/GL4ES/native state divergence.
21. **Native `glViewport` behavior:** `0,0,0×0` immediately after context creation; `0,0,800×600` immediately before first present. No per-frame instrumentation was added.
22. **Orientation findings:** UIKit reports orientation `3` (landscape-right) after context creation. Window/view bounds are 480×320 points, correctly landscape. No evidence supports an orientation swap as the first defect.
23. **Safe-area findings:** one-shot UIKit marker reports all safe-area insets as zero for this fullscreen SDL view. No safe-area adjustment was applied.
24. **Bounded instrumentation output:** `pre_context_dimensions=window 480×320, drawable 480×320`; `post_context_dimensions=window 480×320, drawable 1440×960`; `osg_traits_before_reconcile=480×320`; `osg_traits_after_reconcile=1440×960`; `post_context_uikit=view SDL_uikitopenglview, bounds 480×320, content_scale/screen_scale/native_scale 3, safe_area 0/0/0/0, orientation 3`; `renderer_resolution_reconciled=1440×960`; `camera_viewport_after_reconcile=1440×960`; `native_viewport_before_first_present=800×600`. Each marker emits once.
25. **Before dimension table:**

    | Layer | Before | Units |
    |---|---:|---|
    | UIKit view | 480×320 | points |
    | SDL window | 480×320 | logical |
    | SDL drawable queried pre-context | 480×320 | pixels/fallback |
    | OSG traits | 480×320 | pixels |
    | OSG camera viewport | 480×320 | pixels |
    | Native GL viewport | 800×600 | pixels |

26. **After dimension table:**

    | Layer | After | Units |
    |---|---:|---|
    | UIKit view | 480×320 at scale 3 | points |
    | Native/SDL drawable post-context | 1440×960 | pixels |
    | SDL window | 480×320 | logical |
    | OSG traits | 1440×960 | pixels |
    | OSG camera viewport | 1440×960 | pixels |
    | Native GL viewport before first present | 800×600 | pixels |

    SDL/OSG now converge on the authoritative backing drawable; native viewport state does not.
27. **Regression tests:** five focused post-context sizing tests pass: provisional-vs-authoritative distinction, successful reconciliation, equal-size no-op validity, propagation of width/height, and absence of fixed-device constants. A clean pinned OpenMW tree accepted patches 0001–0006 with `--whitespace=error-all`. Windows Python discovery passed 47 runnable tests; two unrelated shell-script execution tests cannot run natively on Win32.
28. **Correction commit:** `6855180e17846646f677446a84e888f1b5c896ab` (`fix(ios): reconcile post-context drawable dimensions`) on `codex/wo21-post-context-drawable`.
29. **Fast Development run:** GitHub Actions run `32029316093`, job `95385500145`, successful. Draft PR: <https://github.com/arjunyerevan95-dot/OpenMWiOS/pull/9>.
30. **Proof Full Qualification did not run:** the exact pushed/PR merge commit had only the `iOS Fast Development` run; `iOS Full Qualification` was not launched.
31. **Cache restore behavior:** all three restores actually missed despite step-level success: source-download cache not found, vcpkg cache not found (0 packages restored), and qualified build-state cache not found. This caused a cold build. The miss is recorded as a residual cache visibility/scoping regression and was not changed in Work Order 21.
32. **Build duration:** 1h20m job wall time. Configure/dependencies 38m22s; real production compile/link 36m47s; stage/validate/package 21s; build-state save about 2m25s.
33. **Production executable SHA-256:** `E223E39A4F9C6A38DA3E6C53A312AF761CA4FA5044885EC7FF9E6F562316E518`.
34. **IPA SHA-256:** `5C62E49AA11DE5CDCFB9EC5E05984E479E52E3F80294B66D2B7F29BCFB311F88`; exact size 39,067,652 bytes.
35. **Data-path validation:** installed bundle `org.openmw.ios.7CP756AU4P`; current container `/private/var/mobile/Containers/Data/Application/A1B1DD6B-D632-4F43-A74B-36C8586B8F0F`; all six Morrowind/Tribunal/Bloodmoon BSA/ESM files exist. The stale `0253E674-…` cfg entry was changed only to the current `A1B1DD6B-…/Documents/OpenMW/Morrowind/Data Files` path and verified by byte-for-byte AFC readback.
36. **Logging readiness:** bounded filtered device syslog was active before launch; app logs and startup markers were retrieved afterward. Capture was stopped at `2026-08-20T18:28:36+05:30`. No device code or game data was changed during capture.
37. **User launch timestamp:** OpenMW log/startup markers begin `2026-08-20T18:24:53+05:30` (`12:54:53Z`).
38. **BEFORE_REFERENCE screenshot identity:** `build/work-order-21/device/before/work-order-20-before-reference.jpg`, SHA-256 `E23F0437AAD2AF33BB44EA56B1A5E38EA657E2A80157DDAA70228E3661031902`, 31,967 bytes.
39. **AFTER screenshot identity:** `build/work-order-21/device/after/work-order-21-after.jpg`, SHA-256 `890C634BC3DB7B97D0EDA94210A1DE58E1D93801154843A4BFFDC10B962DBF70`, 158,941 bytes.
40. **Visible before/after comparison:** before, loading artwork occupied roughly a 275×186 region in the 1280×720 supplied screenshot; after, it occupies roughly a 740×555 centered region. This is an approximately 2.7× change in both axes. The image remains 4:3 and letterboxed, rather than matching the complete landscape presentation surface.
41. **Visible-render classification:** **B — rectangle size/position changed materially but remains wrong.**
42. **Loading-screen result:** recognizable Bloodmoon loading artwork is now large and centered, but its final image remains frozen on screen after loading finishes.
43. **Main-menu result:** no visible usable main menu. User interaction was not part of the requested passive phase, but subsequent taps provided diagnostic evidence: an unseen menu selection apparently activated New Game. Do not claim a visibly rendered menu.
44. **Process lifetime:** process remained alive across loading, hidden menu selection, transition to the Imperial Prison Ship, character-name input, and guard audio. Syslog records OpenMW PID 12346 as running-active-visible and contains no termination for that PID during capture.
45. **Crash/jetsam status:** no `EXC_BAD_ACCESS`, no `SIGSEGV`, no OpenMW termination, and no evidence of OpenMW jetsam. Generic system `jetsam priority` messages concern process management and are not a jetsam kill.
46. **Music/audio status:** title music plays. After the hidden New Game activation, the user heard in-game Jiub scene audio, entered a character name when prompted, and heard the guard approach. The missing `video/new_game.webm` is logged, so the game correctly skipped the unavailable intro video and loaded `Imperial Prison Ship`.
47. **Shader compile status:** historical raw `#version 120`, raw `centroid`, debug `useAdvancedShader`, and modelToClip failures did not regress. A new later fullscreen-pass failure is now exposed: `compatibility/fullscreen_tri.vert` reports `Initializer not allowed` and undeclared `scaling` (one failed shader compilation).
48. **Program-link status:** historical four modelToClip links remain resolved. Two later failures occur after New Game: one program reports `No definition of main in fragment shader`; another reports an attached shader did not compile because of the fullscreen-triangle vertex failure.
49. **GL error status:** the run produces a severe repeating flood: `ColorMaski::apply` unsupported 552,502 times; `invalid operation` 9,995 times; `invalid enumerant` 9,996 times. This flood begins after the Imperial Prison Ship transition and is temporally consistent with failure to update the visible frame, but Work Order 21 does not yet prove which error is presentation-causal.
50. **Visible prediction confirmed or falsified:** **confirmed in part.** Correcting the pre-context sizing handoff materially enlarged/repositioned the physical render region exactly as predicted. The stronger prediction that all presentation state would converge to the full drawable is falsified: native GL remains 800×600 and the front image freezes while runtime continues behind it.
51. **Highest observable runtime milestone:** real Morrowind gameplay initialization in the Imperial Prison Ship/Jiub scene is audibly and interactively reached behind a stale loading frame; character-name input and guard approach occur. The highest *visible* milestone remains a large, centered but frozen loading screen.
52. **Stop condition:** **CONDITION D — VISIBLE RENDER AREA MATERIALLY CHANGES BUT REMAINS WRONG.**
53. **Strongest causal conclusion:** pre-context SDL fallback dimensions were a real cause of the tiny rectangle, and post-context OSG reconciliation fixes that part. A second presentation defect remains: a late 800×600 native viewport/default-FBO state diverges from OSG's 1440×960 state, and subsequent fullscreen/render-bin activity fails while the engine keeps running. The stale loading image is therefore not an engine stall or absent menu lifecycle; it is a front-buffer/presentation/update failure after successful runtime advancement.
54. **Precise recommended Work Order 22:** perform a bounded presentation/FBO/swap-chain differential, not another generic viewport multiplier. Trace every `glViewport` writer from reconciled OSG camera through GL4ES to native GLES and identify the exact late writer of 800×600. Capture current framebuffer/renderbuffer bindings, drawable/renderbuffer dimensions, offscreen FBO sizes, viewport/scissor state, and `SDL_GL_SwapWindow`/present success for the loading frame and first post-loading/gameplay frames. In parallel, capture the exact converted `fullscreen_tri.vert`/fragment units and determine whether its illegal `scaling` initializer, missing fragment `main`, unsupported `glColorMaski`, or associated GL errors prevent the final fullscreen composite/present. Correct only the first presentation-causal boundary, then require a physical frame update beyond the loading image.

## Evidence locations

- Build/analysis contract: `build/work-order-21/analysis/sizing-contract.md`
- Exact IPA: `build/work-order-21/artifact/run-32029316093/artifacts/OpenMW-iOS-unsigned.ipa`
- Startup markers: `build/work-order-21/device/after/logs/Library/OpenMW/startup.jsonl`
- OpenMW log: `build/work-order-21/device/after/logs/Documents/OpenMW/openmw.log`
- MyGUI log: `build/work-order-21/device/after/logs/Documents/OpenMW/MyGUI.log`
- Bounded syslog: `build/work-order-21/device/wo21-live-syslog.ndjson`
- Before/after screenshots: `build/work-order-21/device/before/` and `build/work-order-21/device/after/`
