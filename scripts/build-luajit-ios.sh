#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

require_macos
require_command xcrun

VCPKG_TRIPLET="${VCPKG_TRIPLET:-arm64-ios-release}"
IOS_DEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET:-15.0}"
PREFIX="${BUILD_DIR}/prefix/${VCPKG_TRIPLET}"
SOURCE_COPY="${BUILD_DIR}/luajit-ios"
OUTPUT_LIBRARY="${PREFIX}/lib/libluajit-5.1.a"

if [[ -f "${OUTPUT_LIBRARY}" ]]; then
    echo "Using cached LuaJIT iOS library: ${OUTPUT_LIBRARY}"
    exit 0
fi

mkdir -p "${SOURCE_COPY}" "${PREFIX}/lib" "${PREFIX}/include/luajit-2.1"
if [[ ! -f "${SOURCE_COPY}/Makefile" ]]; then
    cp -R "${DEPS_DIR}/luajit/." "${SOURCE_COPY}/"
fi

IOS_SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
MACOS_SDK="$(xcrun --sdk macosx --show-sdk-path)"
HOST_CLANG="$(xcrun --sdk macosx --find clang)"
TARGET_CC="$(xcrun --sdk iphoneos --find clang)"
TARGET_AR="$(xcrun --sdk iphoneos --find ar)"
TARGET_STRIP="$(xcrun --sdk iphoneos --find strip)"

# LuaJIT builds minilua and buildvm for the runner before cross-compiling the
# target library. Apple Clang does not reliably infer the macOS SDK when its
# absolute path is invoked by make, so give the host tools an explicit sysroot.
make -C "${SOURCE_COPY}" -j "${JOBS:-4}" \
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
