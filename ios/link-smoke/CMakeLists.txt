add_executable(openmw-ios-link-smoke MACOSX_BUNDLE EXCLUDE_FROM_ALL main.cpp)
target_include_directories(openmw-ios-link-smoke PRIVATE
    "${CMAKE_BINARY_DIR}/generated"
    "${OPENSCENEGRAPH_INCLUDE_DIRS}"
    "${BULLET_INCLUDE_DIRS}"
    "${MyGUI_INCLUDE_DIRS}"
    "${FFmpeg_INCLUDE_DIRS}"
    "${LUA_INCLUDE_DIR}")
target_compile_definitions(openmw-ios-link-smoke PRIVATE OSG_LIBRARY_STATIC)

target_link_libraries(openmw-ios-link-smoke PRIVATE
    openmw_ios_platform
    openmw_ios_osg_plugins
    OpenThreads osg osgAnimation osgDB osgGA osgFX osgParticle osgText
    osgUtil osgShadow osgSim osgViewer
    Freetype::Freetype PNG::PNG JPEG::JPEG ZLIB::ZLIB
    Boost::program_options Boost::iostreams
    "${LUA_LIBRARIES}"
    LZ4::LZ4
    "${ICU_LIBRARIES}"
    "${FFmpeg_LIBRARIES}"
    "${OPENAL_LIBRARY}"
    "${MyGUI_LIBRARIES}"
    "${BULLET_LIBRARIES}"
    RecastNavigation::DebugUtils
    RecastNavigation::Detour
    RecastNavigation::Recast
    SQLite3::SQLite3)

if(yaml-cpp_VERSION VERSION_GREATER_EQUAL 0.8.0)
    target_link_libraries(openmw-ios-link-smoke PRIVATE yaml-cpp::yaml-cpp)
else()
    target_link_libraries(openmw-ios-link-smoke PRIVATE yaml-cpp)
endif()
if(NOT TARGET SDL2::SDL2main)
    message(FATAL_ERROR "The iOS link smoke requires the SDL2::SDL2main static target")
endif()
target_link_libraries(openmw-ios-link-smoke PRIVATE SDL2::SDL2main)

# This manifest is separate from the wider Gate 3 product inventory: every
# entry here must contribute at least one object to the final smoke link map.
# Paths come from CMake targets or the exact resolved package variables used by
# target_link_libraries above.
set(_smoke_participation_manifest "name\tcategory\tarchive\n")
set(_smoke_target_archive_specs
    "OpenThreads|osg-core|OpenThreads"
    "osg|osg-core|osg"
    "osgAnimation|osg-component|osgAnimation"
    "osgDB|osg-component|osgDB"
    "osgGA|osg-component|osgGA"
    "osgFX|osg-component|osgFX"
    "osgParticle|osg-component|osgParticle"
    "osgText|osg-component|osgText"
    "osgUtil|osg-component|osgUtil"
    "osgShadow|osg-component|osgShadow"
    "osgSim|osg-component|osgSim"
    "osgViewer|osg-component|osgViewer"
    "BulletCollision|engine-dependency|BulletCollision"
    "LinearMath|engine-dependency|LinearMath"
    "MyGUIEngine|engine-dependency|MyGUIEngine"
    "Recast|engine-dependency|Recast"
    "Detour|engine-dependency|Detour"
    "DebugUtils|engine-dependency|DebugUtils"
    "SQLite|engine-dependency|sqlite3"
    "SDL2|package|SDL2::SDL2"
    "SDL2main|package|SDL2::SDL2main"
    "FreeType|package|Freetype::Freetype"
    "PNG|package|PNG::PNG"
    "JPEG|package|JPEG::JPEG"
    "zlib|package|ZLIB::ZLIB"
    "LZ4|package|LZ4::LZ4"
    "ICU-uc|package|ICU::uc"
    "ICU-i18n|package|ICU::i18n"
    "ICU-data|package|ICU::data"
    "Boost-program-options|package|Boost::program_options"
    "Boost-iostreams|package|Boost::iostreams")

if(TARGET yaml-cpp::yaml-cpp)
    list(APPEND _smoke_target_archive_specs "yaml-cpp|package|yaml-cpp::yaml-cpp")
elseif(TARGET yaml-cpp)
    list(APPEND _smoke_target_archive_specs "yaml-cpp|package|yaml-cpp")
else()
    message(FATAL_ERROR "The iOS link smoke requires a yaml-cpp CMake target")
endif()

foreach(_plugin_target IN LISTS USED_OSG_PLUGINS)
    list(APPEND _smoke_target_archive_specs
        "${_plugin_target}|osg-plugin|${_plugin_target}")
endforeach()

foreach(_archive_spec IN LISTS _smoke_target_archive_specs)
    string(REPLACE "|" ";" _archive_fields "${_archive_spec}")
    list(GET _archive_fields 0 _archive_name)
    list(GET _archive_fields 1 _archive_category)
    list(GET _archive_fields 2 _archive_target)
    if(NOT TARGET ${_archive_target})
        message(FATAL_ERROR
            "Required smoke participation target is missing: ${_archive_target}")
    endif()
    if(NOT _archive_category STREQUAL "package")
        list(FIND OPENMW_IOS_REQUIRED_CMAKE_ARCHIVES "${_archive_target}"
            _product_manifest_target_index)
        if(_product_manifest_target_index EQUAL -1)
            message(FATAL_ERROR
                "Smoke target ${_archive_target} is absent from the Gate 3 product manifest")
        endif()
    endif()
    string(APPEND _smoke_participation_manifest
        "${_archive_name}\t${_archive_category}\t$<TARGET_FILE:${_archive_target}>\n")
endforeach()

set(_smoke_resolved_archive_specs
    "GL4ES|staged-dependency|${OPENGL_gl_LIBRARY}"
    "LuaJIT|staged-dependency|${OPENMW_IOS_LUAJIT_ARCHIVE}"
    "FFmpeg-avcodec|package|${FFmpeg_AVCODEC_LIBRARY}"
    "FFmpeg-avformat|package|${FFmpeg_AVFORMAT_LIBRARY}"
    "FFmpeg-avutil|package|${FFmpeg_AVUTIL_LIBRARY}"
    "FFmpeg-swresample|package|${FFmpeg_SWRESAMPLE_LIBRARY}"
    "FFmpeg-swscale|package|${FFmpeg_SWSCALE_LIBRARY}"
    "OpenAL|package|${OPENAL_LIBRARY}")
foreach(_archive_spec IN LISTS _smoke_resolved_archive_specs)
    string(REPLACE "|" ";" _archive_fields "${_archive_spec}")
    list(GET _archive_fields 0 _archive_name)
    list(GET _archive_fields 1 _archive_category)
    list(GET _archive_fields 2 _archive_path)
    if(NOT IS_ABSOLUTE "${_archive_path}" OR NOT _archive_path MATCHES "\\.a$"
            OR NOT EXISTS "${_archive_path}")
        message(FATAL_ERROR
            "Smoke dependency ${_archive_name} did not resolve to an absolute static archive: ${_archive_path}")
    endif()
    string(APPEND _smoke_participation_manifest
        "${_archive_name}\t${_archive_category}\t${_archive_path}\n")
endforeach()

file(GENERATE
    OUTPUT "${CMAKE_BINARY_DIR}/generated/ios-link-participation-$<CONFIG>.tsv"
    CONTENT "${_smoke_participation_manifest}")

target_link_options(openmw-ios-link-smoke PRIVATE
    "-Wl,-map,$<TARGET_FILE_DIR:openmw-ios-link-smoke>/openmw-ios-link-smoke.map")
set_target_properties(openmw-ios-link-smoke PROPERTIES
    XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED NO
    XCODE_ATTRIBUTE_ENABLE_BITCODE NO
    XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "${CMAKE_OSX_DEPLOYMENT_TARGET}")
