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

set(_registrar_inventory "")
foreach(_plugin_registrar IN LISTS OPENMW_REQUIRED_OSG_PLUGIN_REGISTRARS)
    string(APPEND _registrar_inventory "${_plugin_registrar}\n")
endforeach()
file(GENERATE OUTPUT "${CMAKE_BINARY_DIR}/required-osg-plugins.txt"
    CONTENT "${_registrar_inventory}")

add_subdirectory(link-smoke)
