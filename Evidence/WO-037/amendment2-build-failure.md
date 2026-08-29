# WO-037 Amendment 2 Final Fast Build Failure

## Identity

- Run: `33265712820`
- Head: `fbddf1f65fef8d3d56e5ee9b3511e0b72198163d`
- Branch: `codex/wo37-distant-pixel-attribution`
- Job: `Real OpenMW arm64 iPhone development build`
- Conclusion: failure
- Started: `2026-08-29T17:28:44Z`
- Completed: `2026-08-29T17:37:00Z`

## Successful boundaries

- Checkout: pass.
- Source-download cache restore: pass/hit.
- vcpkg binary cache restore: pass/hit.
- Pinned build tools: pass.
- Exact-source bootstrap and all ordered patch validation: pass.

The qualified incremental build-state cache did not hit.

## Failure boundary

The `Incremental configure and dependency preparation` step failed before product compilation:

```text
CMake Error at /Users/runner/work/OpenMWiOS/OpenMWiOS/build/ios/extern/fetched/osg/CMakeModules/FindGLIB.cmake:91 (file):
  file failed to open for reading (No such file or directory):

    /usr/local/Cellar/glib/2.88.2/lib/glib-2.0/include/glibconfig.h
Call Stack (most recent call first):
  .../osg/CMakeLists.txt:767 (FIND_PACKAGE)

-- Configuring incomplete, errors occurred!
```

This is a configure/dependency-environment failure involving an unavailable Homebrew GLib header path. It is not a compile or runtime result for the Amendment 2 diagnostic source.

## Artifact boundary

- Failure diagnostics artifact: `OpenMW-iOS-fast-failure-63`.
- Artifact ID: `9718681291`.
- Artifact digest: `sha256:c7cc2fea29cf86ae6e8c16d78ee237c18487ef4e56409ffc6547c49a4966676e`.
- Production executable: none.
- IPA: none.
- Device validation: impossible for Amendment 2.

This was the third and final authorized WO-037 Fast dispatch. No retry or correction build remains authorized. Stop Condition F applies.
