if(NOT DEFINED OSG_SOURCE_DIR OR NOT DEFINED OSG_PATCH_FILE)
    message(FATAL_ERROR "OSG_SOURCE_DIR and OSG_PATCH_FILE are required")
endif()

set(_osg_gl_extensions "${OSG_SOURCE_DIR}/src/osg/GLExtensions.cpp")
if(NOT EXISTS "${_osg_gl_extensions}")
    message(FATAL_ERROR "OSG source file not found: ${_osg_gl_extensions}")
endif()

file(READ "${_osg_gl_extensions}" _osg_gl_extensions_source)
if(_osg_gl_extensions_source MATCHES "return gl4es_GetProcAddress\\(funcName\\);")
    message(STATUS "OSG GL4ES entry-point routing patch is already applied")
    return()
endif()

execute_process(
    COMMAND /usr/bin/patch -N -f -p1 -i "${OSG_PATCH_FILE}"
    WORKING_DIRECTORY "${OSG_SOURCE_DIR}"
    RESULT_VARIABLE _osg_patch_result
    OUTPUT_VARIABLE _osg_patch_stdout
    ERROR_VARIABLE _osg_patch_stderr
)

if(NOT _osg_patch_result EQUAL 0)
    message(FATAL_ERROR
        "Failed to route OSG GL entry points through GL4ES\n"
        "stdout:\n${_osg_patch_stdout}\n"
        "stderr:\n${_osg_patch_stderr}")
endif()
