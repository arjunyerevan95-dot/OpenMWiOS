# OpenMW for iOS

An experimental iPhone and iPad port of OpenMW. The first milestone is a
signed, arm64 device build that reaches the OpenMW main menu using game files
supplied by the user.

## Current scope

- OpenMW 0.51.0
- Physical arm64 iPhone/iPad builds
- SDL2 for the iOS application and input layer
- GL4ES translating OpenMW's desktop OpenGL calls to OpenGL ES
- Statically linked native dependencies
- No Qt launcher, OpenMW-CS, wizard, or bundled Morrowind assets

The repository currently contains the reproducible source/dependency bootstrap,
the first iOS platform patch, the native path bridge, and the Xcode-generation
scripts. It intentionally does not include Bethesda game data.

## Requirements

- Apple Silicon or Intel Mac
- Xcode with the iOS SDK and command-line tools
- CMake 3.28+
- Ninja
- Git, Python 3, autoconf, automake, libtool, and pkg-config
- An Apple development team for installation on a physical device

Homebrew example:

```sh
brew install cmake ninja autoconf automake libtool pkg-config
```

## Bootstrap

```sh
./scripts/bootstrap.sh
./scripts/build-ios.sh
```

The second command builds the third-party libraries and generates
`build/ios/OpenMW.xcodeproj`. Open that project, select the `openmw` target,
set your development team and bundle identifier, and run on a physical device.

## GitHub Actions build

The `Build iOS` workflow performs the macOS/Xcode work remotely, matching the
workflow used for eDukeiOS. Push this repository to GitHub and either run the
workflow manually from the Actions tab or push to `main`/`port/**`.

Each successful run produces:

- `OpenMW-iOS-unsigned-<run>` containing the unsigned `.ipa` and `.app`
- `OpenMW-iOS-diagnostics-<run>` containing configure/build logs and the Xcode
  result bundle

The first artifact is intentionally unsigned. It can later be signed with a
development certificate, AltStore-style tooling, or a configured signing job.
During initial porting, the diagnostics artifact is the important output: it
lets us address the dependency, compiler, and linker failures without needing
a local Mac.

You can override signing settings when generating the project:

```sh
DEVELOPMENT_TEAM=ABCDE12345 \
PRODUCT_BUNDLE_IDENTIFIER=com.example.openmw \
./scripts/build-ios.sh
```

## Game files during the bootstrap milestone

The initial engine build expects the following writable sandbox layout:

```text
Documents/OpenMW/
  openmw.cfg
  settings.cfg
  Morrowind/
    Data Files/
      Morrowind.esm
      Morrowind.bsa
      ...
```

If `openmw.cfg` is absent, the bootstrap creates it automatically when it finds
`Morrowind/Data Files/Morrowind.esm`, including Tribunal and Bloodmoon when
present. The native file importer will replace this manual layout after the engine boot
path is verified. Until then, files can be installed through Xcode's Devices
and Simulators window or Finder file sharing when `UIFileSharingEnabled` is on.

## Build design

`vcpkg` cross-compiles the conventional libraries for `arm64-ios`. GL4ES is
built independently because it supplies the OpenGL compatibility layer.
LuaJIT is also built directly with its upstream iOS makefile path; this keeps
the host-side code generator and JIT-disabled target library in sync.
OpenMW builds its own pinned OpenSceneGraph, MyGUI, Bullet, Recast, and SQLite
copies so that its upstream patches remain intact.

The patches in `patches/openmw` are always applied to a clean, pinned OpenMW
checkout. `scripts/bootstrap.sh` verifies the exact revisions before applying
them, making failures visible instead of silently building a different engine.

## Non-goals for milestone one

- App Store submission
- Simulator builds
- Mod manager UI
- Touch-control customization
- Metal renderer
- Shipping copyrighted Morrowind assets

Those come after the renderer and lifecycle have been validated on hardware.
