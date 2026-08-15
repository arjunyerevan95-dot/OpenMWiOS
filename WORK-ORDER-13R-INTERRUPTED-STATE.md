# Work Order 13R — Interrupted State Inventory

Recorded: 2026-08-15 (Asia/Calcutta)

## Repository state

- Branch: `fix/ios-resources-bundle-collision`
- HEAD: `71227ffdafc1bc3c80688d3654b09e853913617a`
- Worktree: clean (`git status --short` produced no entries)
- No Work Order 13 commits were created before interruption.
- Work Order 12 corrective commits preserved at this starting point:
  - `fa4bab4` — relocate OpenMW resources outside the reserved Apple bundle name
  - `9c45f35` — validate bundle layout and resource preservation
  - `5a48d18` — document the iOS Resources collision root cause
  - `85f971f` — run the new validations through the production gate
  - `71227ff` — qualify the reciprocal Apple-bundle test

No reset, clean, stash, deletion, or production-code edit was performed during the interrupted work.

## Generated evidence

- `build/work-order-13/device-baseline/openmw-container-inventory.jsonl`
  - Size: 4,520,041 bytes
  - Read-only inventory of the content-qualified device sandbox.
  - Confirms Morrowind, Tribunal, and Bloodmoon data and current OpenMW runtime logs exist.
- A subsequent narrow log pull was attempted after a PC restart, but Apple network-device discovery was offline. No partial log files were created.

## Pinned source/index validation

The existing Codebase Memory projects were found and queried at these exact revisions:

- OpenMW: `f4bec41444214a7903bebd178389ca22ca13f646`
- GL4ES: `c9895df34cd466c23bc60c2bd3db3d87e98fcbe7`
- OpenSceneGraph: `01cc2b585c8456a4ff843066b7e1a8715558289f`
- SDL2: `5d249570393f7a37e037abf22cd6012a4cc56a71`

Their working trees contain the expected historical port patches; those pre-existing dependency-tree modifications were not changed by the interrupted work.

## Useful graphics reconnaissance

1. OpenMW's `ShaderManager::getShader` reads the compatibility shader templates, preprocesses defines/directives, and passes the resulting desktop GLSL source to `osg::Shader::setShaderSource`.
2. The OpenMW compatibility shaders intentionally begin with `#version 120`.
3. OSG compiles through function pointers populated for `glShaderSource`, `glCompileShader`, and related entry points.
4. GL4ES's `gl4es_glShaderSource` stores the original source, calls `ConvertShader` for a GLSL 1.20 shader, and sends the converted source to native GLES.
5. `ConvertShader` removes/replaces the desktop `#version` header and contains explicit cleanup for the `centroid` keyword.
6. The Work Order 12 production link map proves both paths exist in the final executable:
   - `_gl4es_glShaderSource` comes from `libGL.a(shader.o)`.
   - `_glShaderSource.got`, `_glCompileShader.got`, `_glGetShaderInfoLog.got`, `_glGetString.got`, and `_glViewport.got` resolve from Apple's `OpenGLES.framework`.
7. The OpenMW CMake cache records OSG as desktop `GL1/GL2` (`OSG_GL2_AVAILABLE=ON`, GLES variants off) and records OSG libraries with direct OpenGLES framework dependencies.

This is strong navigation/static-link evidence for a possible OSG-to-native-GLES bypass of GL4ES shader conversion. It is preserved as a testable model, not yet promoted to the final conclusion; Work Order 13R must compare it against the known-working Android 2.7.4 integration.

## Useful native-context/configuration reconnaissance

- The iOS bootstrap sets:
  - `LIBGL_ES=2`
  - `LIBGL_GL=21`
  - `OPENMW_GLES_VERSION=2`
- `GraphicsWindowSDL2` requests SDL's ES profile, major 2, minor 0 before creating the context.
- SDL UIKit maps that major version to `EAGLRenderingAPI`, establishing an intended native GLES 2 context.
- GL4ES is initialized manually only after SDL creates the native context.
- GL4ES build flags include `NOEGL=ON`, `NO_LOADER=ON`, `NO_INIT_CONSTRUCTOR=ON`, `STATICLIB=ON`, and `DEFAULT_ES=2`.

## Useful secondary findings

- `centroid` originates in OpenMW compatibility shader sources such as `objects.frag`, `terrain.frag`, and `vertexcolors.glsl`; GL4ES's converter has code intended to remove it.
- The stale `./resources/vfs-mw` warning originates from the generated OpenMW configuration template (`files/openmw.cfg`, `data=${OPENMW_RESOURCE_FILES}/vfs-mw`), independently of the corrected iOS `--resources openmw-resources` argument. The runtime also mounts the valid relocated VFS and loads substantial content, so this remains a separate path/configuration issue.
- MyGUI initialization and Lua menu errors remain classified as secondary to the earlier shader failures.

## Useful CI profiling

Representative workflow run: `31878221600`, HEAD `71227ff`, total wall time approximately 75 minutes.

Largest steps:

- Gate 2 dependency build/configure: 34m13s
- Gate 5 real OpenMW compile/link: 22m17s
- Gate 3 dependency/registrar validation build: 14m05s
- Tool installation: 49s
- Gate 1 bootstrap/source validation: 34s
- Link-smoke: 27s
- Real bundle validation/package: 21s

The run passed the real production compile, link, and bundle/package gates, then failed only in the obsolete top-level-files transplant diagnostic that still expected the pre-fix layout. No workflow edits or caching experiments had been made yet.

## Classification of interrupted work

- Useful reconnaissance: shader call-path graph, GL4ES converter behavior, OSG/OpenGLES link-map evidence, native GLES request path, stale VFS path source.
- Useful instrumentation: none added; no diagnostic source changes exist.
- CI-only work: representative run timing/profile and initial historical-gate inventory.
- Obsolete speculation: none committed. The preliminary conversion-bypass model must be tested against Android rather than assumed.

