add_subdirectory(shaders)
add_subdirectory(data)
add_subdirectory(data-mw)
add_subdirectory(lua_api)

if (NOT DEFINED OPENMW_RESOURCES_ROOT)
    return()
endif()

copy_resource_file("launcher/images/openmw.png" "${OPENMW_RESOURCES_ROOT}" "resources/openmw.png")

if (IOS)
    file(GLOB_RECURSE deckwind_files RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}/deckwind"
        CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/deckwind/*")
    foreach(file IN LISTS deckwind_files)
        copy_resource_file("deckwind/${file}" "${OPENMW_RESOURCES_ROOT}" "resources/vfs/${file}")
    endforeach()
endif()
