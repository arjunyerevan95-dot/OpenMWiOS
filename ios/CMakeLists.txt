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

    string(APPEND _registrar_inventory "${_plugin_target}|${_registrar_symbol}\n")
    add_dependencies(openmw-ios-required-osg-plugins ${_plugin_target})
endforeach()
file(GENERATE OUTPUT "${CMAKE_BINARY_DIR}/generated/openmw_ios_osg_plugins.hpp"
    CONTENT "${_registration_header}")
file(GENERATE OUTPUT "${CMAKE_BINARY_DIR}/required-osg-plugins.txt"
    CONTENT "${_registrar_inventory}")

add_subdirectory(link-smoke)
