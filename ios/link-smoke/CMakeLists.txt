add_executable(openmw-ios-link-smoke MACOSX_BUNDLE EXCLUDE_FROM_ALL main.cpp)
target_include_directories(openmw-ios-link-smoke PRIVATE
    "${CMAKE_BINARY_DIR}/generated"
    "${OPENSCENEGRAPH_INCLUDE_DIRS}"
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
if(TARGET SDL2::SDL2main)
    target_link_libraries(openmw-ios-link-smoke PRIVATE SDL2::SDL2main)
endif()

target_link_options(openmw-ios-link-smoke PRIVATE
    "-Wl,-map,$<TARGET_FILE_DIR:openmw-ios-link-smoke>/openmw-ios-link-smoke.map")
set_target_properties(openmw-ios-link-smoke PROPERTIES
    XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED NO
    XCODE_ATTRIBUTE_ENABLE_BITCODE NO
    XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "${CMAKE_OSX_DEPLOYMENT_TARGET}")
