cmake_minimum_required(VERSION 3.20)
project(OpenMWiOSPortValidation LANGUAGES NONE)

if(NOT DEFINED PORT_ROOT)
    get_filename_component(PORT_ROOT "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
endif()

set(_required_files
    vcpkg.json
    triplets/arm64-ios-openmw-release.cmake
    ios/CMakeLists.txt
    ios/link-smoke/CMakeLists.txt
    scripts/validate-ios-dependencies.sh
    scripts/verify-bundle.sh)
foreach(_file IN LISTS _required_files)
    if(NOT EXISTS "${PORT_ROOT}/${_file}")
        message(FATAL_ERROR "Required port file is missing: ${_file}")
    endif()
endforeach()

file(READ "${PORT_ROOT}/vcpkg.json" _manifest)
if(NOT _manifest MATCHES "\"default-features\"[ \t\r\n]*:[ \t\r\n]*false")
    message(FATAL_ERROR "FreeType default features must remain disabled")
endif()
file(READ "${PORT_ROOT}/triplets/arm64-ios-openmw-release.cmake" _triplet)
if(NOT _triplet MATCHES "VCPKG_OSX_DEPLOYMENT_TARGET \"16\\.3\"")
    message(FATAL_ERROR "Overlay triplet must pin iOS 16.3")
endif()
file(READ "${PORT_ROOT}/ios/link-smoke/CMakeLists.txt" _smoke)
if(NOT _smoke MATCHES "openmw_ios_osg_plugins")
    message(FATAL_ERROR "Link smoke must consume the canonical OSG plugin interface")
endif()
