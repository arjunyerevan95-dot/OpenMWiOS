set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_CMAKE_SYSTEM_NAME iOS)
set(VCPKG_BUILD_TYPE release)
set(VCPKG_OSX_SYSROOT iphoneos)

# vcpkg's community iOS triplet does not pin the minimum OS. Keep every
# package aligned with the app and the hand-built GL4ES/LuaJIT archives.
set(VCPKG_OSX_DEPLOYMENT_TARGET "16.3")
set(VCPKG_C_FLAGS "-miphoneos-version-min=16.3")
set(VCPKG_CXX_FLAGS "-miphoneos-version-min=16.3")
set(VCPKG_LINKER_FLAGS "-miphoneos-version-min=16.3")
