cmake_minimum_required(VERSION 3.28)

project(OpenMWBundleProbe LANGUAGES OBJC)

if(NOT CMAKE_GENERATOR STREQUAL "Xcode")
    message(FATAL_ERROR "The bundle probe requires the Xcode generator")
endif()

if(NOT CMAKE_SYSTEM_NAME STREQUAL "iOS")
    message(FATAL_ERROR "The bundle probe must target CMAKE_SYSTEM_NAME=iOS")
endif()

if(NOT CMAKE_OSX_SYSROOT MATCHES "iphoneos")
    message(FATAL_ERROR "The bundle probe must use the iphoneos SDK")
endif()

if(NOT CMAKE_OSX_ARCHITECTURES STREQUAL "arm64")
    message(FATAL_ERROR "The bundle probe must target arm64")
endif()

if(NOT CMAKE_OSX_DEPLOYMENT_TARGET VERSION_EQUAL "16.3")
    message(FATAL_ERROR "The bundle probe must target iOS 16.3")
endif()

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist.in"
    "${CMAKE_CURRENT_BINARY_DIR}/Info.plist"
    @ONLY
)

add_executable(openmw_bundle_probe MACOSX_BUNDLE main.m)

set_target_properties(openmw_bundle_probe PROPERTIES
    OUTPUT_NAME "OpenMW"
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_BINARY_DIR}/Info.plist"
    XCODE_GENERATE_SCHEME TRUE
    XCODE_ATTRIBUTE_PRODUCT_NAME "OpenMW"
    XCODE_ATTRIBUTE_EXECUTABLE_NAME "openmw"
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "org.openmw.ios"
    XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1"
    XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "16.3"
    XCODE_ATTRIBUTE_ARCHS "arm64"
    XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH "NO"
    XCODE_ATTRIBUTE_SUPPORTED_PLATFORMS "iphoneos"
    XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED "NO"
    XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED "NO"
    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY ""
    XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC "YES"
    XCODE_ATTRIBUTE_SKIP_INSTALL "NO"
)

target_link_libraries(openmw_bundle_probe PRIVATE
    "-framework Foundation"
    "-framework UIKit"
)
