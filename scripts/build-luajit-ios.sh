#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

require_macos
require_command xcrun

VCPKG_TRIPLET="${VCPKG_TRIPLET:-arm64-ios-openmw-release}"
IOS_DEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET:-16.3}"
PREFIX="${BUILD_DIR}/prefix/${VCPKG_TRIPLET}"
SOURCE_COPY="${BUILD_DIR}/luajit-ios"
OUTPUT_LIBRARY="${PREFIX}/lib/libluajit-5.1.a"

if [[ "${OPENMW_FAST_REUSE_LUAJIT:-0}" == "1" \
    && -f "${OUTPUT_LIBRARY}" \
    && -f "${PREFIX}/include/luajit-2.1/luajit.h" ]]; then
    LUAJIT_ARCHS="$(xcrun lipo -archs "${OUTPUT_LIBRARY}" 2>/dev/null || true)"
    if [[ "${LUAJIT_ARCHS}" == "arm64" ]]; then
        echo "Reusing qualified cached LuaJIT iOS archive: ${OUTPUT_LIBRARY}"
        exit 0
    fi
    echo "Cached LuaJIT archive failed arm64 validation; rebuilding." >&2
fi

# The full qualification path reaches here without OPENMW_FAST_REUSE_LUAJIT
# and therefore always rebuilds. The fast path only returns above after its
# cache key and this archive-level architecture check have both succeeded.
rm -rf "${SOURCE_COPY}"
mkdir -p "${SOURCE_COPY}" "${PREFIX}/lib" "${PREFIX}/include/luajit-2.1"
cp -R "${DEPS_DIR}/luajit/." "${SOURCE_COPY}/"

IOS_SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
MACOS_SDK="$(xcrun --sdk macosx --show-sdk-path)"
HOST_CLANG="$(xcrun --sdk macosx --find clang)"
TARGET_CC="$(xcrun --sdk iphoneos --find clang)"
TARGET_AR="$(xcrun --sdk iphoneos --find ar)"
TARGET_STRIP="$(xcrun --sdk iphoneos --find strip)"

# LuaJIT builds minilua and buildvm for the runner before cross-compiling the
# target library. Apple Clang does not reliably infer the macOS SDK when its
# absolute path is invoked by make, so give the host tools an explicit sysroot.
make -C "${SOURCE_COPY}/src" -j "${JOBS:-4}" libluajit.a \
    HOST_CC="${HOST_CLANG} -isysroot ${MACOS_SDK}" \
    TARGET_CC="${TARGET_CC} -arch arm64 -isysroot ${IOS_SDK} -miphoneos-version-min=${IOS_DEPLOYMENT_TARGET}" \
    TARGET_AR="${TARGET_AR} rcus" \
    TARGET_STRIP="${TARGET_STRIP} -x" \
    TARGET_SYS=iOS \
    BUILDMODE=static

cp "${SOURCE_COPY}/src/libluajit.a" "${OUTPUT_LIBRARY}"
cp "${SOURCE_COPY}/src/lua.h" \
   "${SOURCE_COPY}/src/lua.hpp" \
   "${SOURCE_COPY}/src/luaconf.h" \
   "${SOURCE_COPY}/src/lauxlib.h" \
   "${SOURCE_COPY}/src/lualib.h" \
   "${SOURCE_COPY}/src/luajit.h" \
   "${PREFIX}/include/luajit-2.1/"

echo "Built LuaJIT interpreter library for iOS: ${OUTPUT_LIBRARY}"
