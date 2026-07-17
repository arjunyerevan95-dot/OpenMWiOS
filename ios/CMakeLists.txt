add_library(openmw_ios_platform INTERFACE)
target_link_libraries(openmw_ios_platform INTERFACE
    SDL2::SDL2
    "${OPENGL_gl_LIBRARY}"
    "-framework Foundation"
    "-framework UIKit"
    "-framework OpenGLES"
    "-framework AudioToolbox"
    "-framework AVFoundation"
    "-framework Accelerate"
    "-framework CoreAudio"
    "-framework CoreFoundation"
    "-framework CoreGraphics"
    "-framework CoreMedia"
    "-framework CoreVideo"
    "-framework CoreMotion"
    "-framework CoreHaptics"
    "-framework GameController"
    "-framework Metal"
    "-framework QuartzCore"
    "-framework Security"
    "-framework SystemConfiguration"
    "-framework VideoToolbox")
target_link_options(openmw_ios_platform INTERFACE "-ObjC")

file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/generated")
set(_registration_header "#pragma once\n#include <osgDB/Registry>\n\n")
set(_registrar_inventory "")
add_custom_target(openmw-ios-required-osg-plugins)
foreach(_plugin_target IN LISTS USED_OSG_PLUGINS)
    if(NOT TARGET ${_plugin_target})
        message(FATAL_ERROR "Required iOS OSG plugin target is missing: ${_plugin_target}")
    endif()

    if(_plugin_target STREQUAL "osgdb_serializers_osg")
        string(APPEND _registration_header "USE_SERIALIZER_WRAPPER_LIBRARY(osg)\n")
        set(_registrar_symbol "_wrapper_serializer_library_osg")
    elseif(_plugin_target MATCHES "^osgdb_(.+)$")
        set(_plugin_name "${CMAKE_MATCH_1}")
        string(APPEND _registration_header "USE_OSGPLUGIN(${_plugin_name})\n")
        set(_registrar_symbol "_osgdb_${_plugin_name}")
    else()
        message(FATAL_ERROR "Cannot derive static registrar for required OSG plugin: ${_plugin_target}")
    endif()

    string(APPEND _registrar_inventory
        "${_plugin_target}|${_registrar_symbol}|$<TARGET_FILE:${_plugin_target}>\n")
    add_dependencies(openmw-ios-required-osg-plugins ${_plugin_target})
endforeach()
file(GENERATE OUTPUT "${CMAKE_BINARY_DIR}/generated/openmw_ios_osg_plugins.hpp"
    CONTENT "${_registration_header}")
file(GENERATE OUTPUT "${CMAKE_BINARY_DIR}/required-osg-plugins-$<CONFIG>.txt"
    CONTENT "${_registrar_inventory}")

# Keep Gate 3 tied to generated target products rather than every archive that
# happens to exist under the CMake build tree. These are the bundled static
# targets that the iOS smoke executable is expected to consume directly or
# through a declared target dependency.
set(OPENMW_IOS_REQUIRED_CMAKE_ARCHIVES
    OpenThreads
    osg
    ${USED_OSG_COMPONENTS}
    ${USED_OSG_PLUGINS}
    BulletCollision
    LinearMath
    MyGUIEngine
    Recast
    Detour
    DebugUtils
    sqlite3)
list(REMOVE_DUPLICATES OPENMW_IOS_REQUIRED_CMAKE_ARCHIVES)

add_custom_target(openmw-ios-required-static-dependencies)
add_dependencies(openmw-ios-required-static-dependencies
    openmw-ios-required-osg-plugins)

set(_archive_product_manifest "kind\torigin\tname\tpath\n")
foreach(_archive_target IN LISTS OPENMW_IOS_REQUIRED_CMAKE_ARCHIVES)
    if(NOT TARGET ${_archive_target})
        message(FATAL_ERROR
            "Required iOS static dependency target is missing: ${_archive_target}")
    endif()
    get_target_property(_archive_type ${_archive_target} TYPE)
    if(NOT _archive_type STREQUAL "STATIC_LIBRARY")
        message(FATAL_ERROR
            "Required iOS dependency ${_archive_target} is ${_archive_type}, expected STATIC_LIBRARY")
    endif()
    add_dependencies(openmw-ios-required-static-dependencies ${_archive_target})
    string(APPEND _archive_product_manifest
        "archive\tcmake-target\t${_archive_target}\t$<TARGET_FILE:${_archive_target}>\n")
endforeach()

if(NOT IS_ABSOLUTE "${OPENGL_gl_LIBRARY}")
    message(FATAL_ERROR "GL4ES archive path must be absolute: ${OPENGL_gl_LIBRARY}")
endif()
string(APPEND _archive_product_manifest
    "archive\tstaged-dependency\tGL4ES\t${OPENGL_gl_LIBRARY}\n")

set(OPENMW_IOS_LUAJIT_ARCHIVE "")
foreach(_lua_library IN LISTS LUA_LIBRARIES)
    if(IS_ABSOLUTE "${_lua_library}" AND _lua_library MATCHES "\\.a$")
        if(OPENMW_IOS_LUAJIT_ARCHIVE)
            message(FATAL_ERROR
                "LuaJIT resolved to more than one static archive: ${LUA_LIBRARIES}")
        endif()
        set(OPENMW_IOS_LUAJIT_ARCHIVE "${_lua_library}")
    endif()
endforeach()
if(NOT OPENMW_IOS_LUAJIT_ARCHIVE)
    message(FATAL_ERROR "LuaJIT did not resolve to an absolute static archive: ${LUA_LIBRARIES}")
endif()
string(APPEND _archive_product_manifest
    "archive\tstaged-dependency\tLuaJIT\t${OPENMW_IOS_LUAJIT_ARCHIVE}\n")

if(NOT DEFINED OPENMW_IOS_VCPKG_LIBRARY_DIR
        OR NOT IS_ABSOLUTE "${OPENMW_IOS_VCPKG_LIBRARY_DIR}")
    message(FATAL_ERROR
        "OPENMW_IOS_VCPKG_LIBRARY_DIR must name the absolute vcpkg target library directory")
endif()
string(APPEND _archive_product_manifest
    "directory\tvcpkg-package-output\t${VCPKG_TARGET_TRIPLET}\t${OPENMW_IOS_VCPKG_LIBRARY_DIR}\n")

file(GENERATE
    OUTPUT "${CMAKE_BINARY_DIR}/generated/ios-archive-products-$<CONFIG>.tsv"
    CONTENT "${_archive_product_manifest}")

add_subdirectory(link-smoke)
