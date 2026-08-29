# WO-038 Cold OSG Configuration Recovery

## Proven pre-change failure

Fast run `33265712820` passed patch bootstrap and source validation, then stopped during cold OSG CMake configuration before OpenMW compilation. Pinned OSG's optional `FindGLIB.cmake` accepted a stale Homebrew location and tried to read:

`/usr/local/Cellar/glib/2.88.2/lib/glib-2.0/include/glibconfig.h`

The file was absent. No executable or IPA was produced, so this was an optional host-package discovery failure rather than a runtime renderer result.

## Direct source proof

- Pinned OSG revision: `01cc2b585c8456a4ff843066b7e1a8715558289f`.
- Its top-level `CMakeLists.txt` uses non-required `FIND_PACKAGE(GLIB COMPONENTS gobject)`.
- The iOS OpenMW configure command already selects static OSG, the iPhone platform, and no OSG windowing system.
- The structural iOS port removes `osgdb_dae` from the iOS plugin list while retaining BMP, DDS, FreeType, JPEG, OSG, PNG, OSG serializers, and TGA.
- No required iOS plugin needs GLib.

## Authorized change

The OpenMW iOS CMake invocation in `scripts/build-ios.sh` now includes exactly:

`-DCMAKE_DISABLE_FIND_PACKAGE_GLIB=ON`

This uses CMake's supported package-disable mechanism. It does not install GLib, add a Homebrew path, disable another package, alter dependency pins, change the deployment target/architecture, or change a runtime renderer/default.

## Deterministic coverage

`validation/test_wo38_cold_osg_configuration.py` checks:

1. exactly one GLib package-disable flag exists in the iOS configure command;
2. no other package is disabled;
3. no Homebrew/host GLib path or variable is embedded;
4. the iOS plugin filter moves only DAE and does not remove required static plugins;
5. platform, architecture, GL4ES, OSG, and deployment settings remain unchanged; and
6. all dependency pins remain exact.

Cold macOS CI result: pending.
