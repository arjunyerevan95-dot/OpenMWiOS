#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

require_macos
require_command cmake
require_command git
require_command xcodebuild

if [[ ! -d "${DEPS_DIR}/openmw/.git" ]]; then
    echo "error: run ./scripts/bootstrap.sh first" >&2
    exit 1
fi

IOS_DEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET:-15.0}"
VCPKG_TRIPLET="${VCPKG_TRIPLET:-arm64-ios-release}"
CONFIGURATION="${CONFIGURATION:-Release}"
IPHONE_SDKVER="${IPHONE_SDKVER:-$(xcrun --sdk iphoneos --show-sdk-version)}"
JOBS="${JOBS:-$(sysctl -n hw.logicalcpu)}"
PREFIX="${BUILD_DIR}/prefix/${VCPKG_TRIPLET}"

"${DEPS_DIR}/vcpkg-pinned/bootstrap-vcpkg.sh" -disableMetrics
"${DEPS_DIR}/vcpkg-pinned/vcpkg" install \
    --x-manifest-root="${ROOT_DIR}" \
    --triplet="${VCPKG_TRIPLET}" \
    --x-install-root="${BUILD_DIR}/vcpkg_installed"

"${ROOT_DIR}/scripts/build-luajit-ios.sh"

cmake -S "${DEPS_DIR}/gl4es" -B "${BUILD_DIR}/gl4es-ios" -G Xcode \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_TOOLCHAIN_FILE="${DEPS_DIR}/ios-cmake/ios.toolchain.cmake" \
    -DPLATFORM=OS64 \
    -DDEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET}" \
    -DNOX11=ON \
    -DNOEGL=ON \
    -DSTATICLIB=ON \
    -DDEFAULT_ES=2 \
    -DNO_LOADER=ON \
    -DNO_INIT_CONSTRUCTOR=ON \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}"

cmake --build "${BUILD_DIR}/gl4es-ios" \
    --config "${CONFIGURATION}" --target GL --parallel "${JOBS}"

mkdir -p "${PREFIX}/lib" "${PREFIX}/include"
find "${BUILD_DIR}/gl4es-ios" -name 'libGL.a' -type f -exec cp {} "${PREFIX}/lib/libGL.a" \;
cp -R "${DEPS_DIR}/gl4es/include/GL" "${PREFIX}/include/"

VCPKG_PREFIX="${BUILD_DIR}/vcpkg_installed/${VCPKG_TRIPLET}"

cmake -S "${DEPS_DIR}/openmw" -B "${BUILD_DIR}/ios" -G Xcode \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_TOOLCHAIN_FILE="${DEPS_DIR}/ios-cmake/ios.toolchain.cmake" \
    -DPLATFORM=OS64 \
    -DDEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET}" \
    -DCMAKE_PREFIX_PATH="${VCPKG_PREFIX};${PREFIX}" \
    -DCMAKE_FIND_ROOT_PATH="${VCPKG_PREFIX};${PREFIX}" \
    -DOPENGL_INCLUDE_DIR="${PREFIX}/include" \
    -DOPENGL_gl_LIBRARY="${PREFIX}/lib/libGL.a" \
    -DOPENGL_HEADER1:STRING="#include <GL/gl.h>" \
    -DOPENGL_HEADER2:STRING= \
    -DOPENMW_IOS=ON \
    -DOPENMW_GL4ES_MANUAL_INIT=ON \
    -DOPENMW_USE_SYSTEM_BULLET=OFF \
    -DOPENMW_USE_SYSTEM_MYGUI=OFF \
    -DOPENMW_USE_SYSTEM_OSG=OFF \
    -DOPENMW_USE_SYSTEM_RECASTNAVIGATION=OFF \
    -DOPENMW_USE_SYSTEM_SQLITE3=OFF \
    -DOSG_STATIC=ON \
    -DOSG_BUILD_PLATFORM_IPHONE=ON \
    -DOSG_WINDOWING_SYSTEM=None \
    -DIPHONE_SDKVER:STRING="${IPHONE_SDKVER}" \
    -DIPHONE_VERSION_MIN:STRING="${IOS_DEPLOYMENT_TARGET}" \
    -DMYGUI_STATIC=ON \
    -DBULLET_STATIC=ON \
    -DRECASTNAVIGATION_STATIC=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_OPENMW=ON \
    -DBUILD_LAUNCHER=OFF \
    -DBUILD_WIZARD=OFF \
    -DBUILD_OPENCS=OFF \
    -DBUILD_MWINIIMPORTER=OFF \
    -DBUILD_ESSIMPORTER=OFF \
    -DBUILD_BSATOOL=OFF \
    -DBUILD_ESMTOOL=OFF \
    -DBUILD_NIFTEST=OFF \
    -DBUILD_NAVMESHTOOL=OFF \
    -DBUILD_BULLETOBJECTTOOL=OFF \
    -DBUILD_COMPONENTS_TESTS=OFF \
    -DBUILD_OPENMW_TESTS=OFF \
    -DUSE_LUAJIT=ON \
    -DRUN_RESULT_VAR=0 \
    -D_OPENTHREADS_ATOMIC_USE_GCC_BUILTINS_EXITCODE=0 \
    -D_OPENTHREADS_ATOMIC_USE_BSD_ATOMIC_EXITCODE=1 \
    -DCMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-}" \
    -DCMAKE_XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER="${PRODUCT_BUNDLE_IDENTIFIER:-org.openmw.ios}"

echo "Generated ${BUILD_DIR}/ios/OpenMW.xcodeproj"
