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
    scripts/dependency-inventory.py
    scripts/extract-link-command.py
    scripts/install-pinned-cmake.sh
    scripts/install-pinned-shellcheck.sh
    scripts/resolve-xcode-manifest.py
    scripts/validate-ios-dependencies.sh
    scripts/validate-apple-bundle.sh
    scripts/verify-resource-relocation.py
    scripts/verify-link-map.py
    scripts/verify-linked-product.sh
    scripts/verify-no-deployment-warnings.sh
    scripts/verify-bundle.sh
    validation/BundleProbe.swift)
foreach(_file IN LISTS _required_files)
    if(NOT EXISTS "${PORT_ROOT}/${_file}")
        message(FATAL_ERROR "Required port file is missing: ${_file}")
    endif()
endforeach()

file(READ "${PORT_ROOT}/vcpkg.json" _manifest)
string(JSON _dependency_count LENGTH "${_manifest}" dependencies)
math(EXPR _dependency_last "${_dependency_count} - 1")
set(_freetype_found FALSE)
set(_freetype_default_features TRUE)
foreach(_dependency_index RANGE 0 ${_dependency_last})
    string(JSON _dependency_type TYPE "${_manifest}" dependencies ${_dependency_index})
    if(_dependency_type STREQUAL "OBJECT")
        string(JSON _dependency_name GET "${_manifest}" dependencies ${_dependency_index} name)
        if(_dependency_name STREQUAL "freetype")
            set(_freetype_found TRUE)
            string(JSON _freetype_default_features GET
                "${_manifest}" dependencies ${_dependency_index} default-features)
        endif()
    endif()
endforeach()
if(NOT _freetype_found OR _freetype_default_features)
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
file(READ "${PORT_ROOT}/ios/CMakeLists.txt" _ios_cmake)
if(NOT _ios_cmake MATCHES "foreach\\(_plugin_target IN LISTS USED_OSG_PLUGINS\\)")
    message(FATAL_ERROR "iOS registrar generation must derive from USED_OSG_PLUGINS")
endif()
file(READ "${PORT_ROOT}/ios/link-smoke/main.cpp" _smoke_source)
if(_smoke_source MATCHES "USE_OSGPLUGIN\\(" OR _smoke_source MATCHES "USE_SERIALIZER_WRAPPER_LIBRARY\\(")
    message(FATAL_ERROR "Link smoke must not duplicate the canonical generated plugin registrations")
endif()
if(NOT _smoke_source MATCHES "openmw_ios_osg_plugins.hpp")
    message(FATAL_ERROR "Link smoke must include the generated canonical plugin registrations")
endif()
foreach(_anchor IN ITEMS
        btBoxShape btAlignedAlloc MyGUI::LogManager rcAlloc dtAlloc
        duDumpPolyMeshToObj sqlite3_libversion avutil_version ucol_open)
    if(NOT _smoke_source MATCHES "${_anchor}")
        message(FATAL_ERROR "Link smoke is missing required public symbol anchor: ${_anchor}")
    endif()
endforeach()
string(FIND "${_ios_cmake}" "ios-archive-products-$<CONFIG>.tsv" _product_manifest_reference)
if(_product_manifest_reference EQUAL -1)
    message(FATAL_ERROR "iOS CMake must generate the configuration-specific product manifest")
endif()
string(FIND "${_ios_cmake}" "required-osg-plugins-$<CONFIG>.txt" _registrar_manifest_reference)
if(_registrar_manifest_reference EQUAL -1)
    message(FATAL_ERROR "OSG registrar inventory must be configuration-specific for Xcode")
endif()
string(FIND "${_ios_cmake}" "required-osg-plugins.txt" _legacy_registrar_manifest_reference)
if(NOT _legacy_registrar_manifest_reference EQUAL -1)
    message(FATAL_ERROR "OSG registrar inventory must not use a configuration-independent output path")
endif()
string(FIND "${_smoke}" "ios-link-participation-$<CONFIG>.tsv" _participation_manifest_reference)
if(_participation_manifest_reference EQUAL -1)
    message(FATAL_ERROR "Link smoke must generate the exact archive participation manifest")
endif()

file(READ "${PORT_ROOT}/scripts/dependency-inventory.py" _inventory_script)
if(_inventory_script MATCHES "rglob\\(\"\\*\\.a\"\\)")
    message(FATAL_ERROR "Dependency inventory must not recursively scan broad build directories")
endif()
if(NOT _inventory_script MATCHES "read_product_manifest")
    message(FATAL_ERROR "Dependency inventory must consume the generated product manifest")
endif()

file(READ "${PORT_ROOT}/versions.env" _versions)
if(NOT _versions MATCHES "CMAKE_VERSION=4\\.3\\.4")
    message(FATAL_ERROR "CMake must remain pinned to 4.3.4")
endif()
if(NOT _versions MATCHES
        "CMAKE_MACOS_SHA256=bf6647c78ac295c54dbe0a094d4428f495be93c1f810fd8bde57374e8b548523")
    message(FATAL_ERROR "Pinned CMake checksum does not match Kitware's 4.3.4 macOS archive")
endif()
if(NOT _versions MATCHES "SHELLCHECK_VERSION=0\\.11\\.0")
    message(FATAL_ERROR "ShellCheck must remain pinned to 0.11.0")
endif()
if(NOT _versions MATCHES
        "SHELLCHECK_DARWIN_X86_64_SHA256=3c89db4edcab7cf1c27bff178882e0f6f27f7afdf54e859fa041fca10febe4c6")
    message(FATAL_ERROR "Pinned ShellCheck checksum does not match the official 0.11.0 macOS archive")
endif()

file(READ "${PORT_ROOT}/.github/workflows/ios.yml" _workflow)
if(NOT _workflow MATCHES "install-pinned-shellcheck\\.sh")
    message(FATAL_ERROR "CI must install the checksum-verified pinned ShellCheck")
endif()
if(NOT _workflow MATCHES "install-pinned-cmake\\.sh")
    message(FATAL_ERROR "CI must install the checksum-verified pinned CMake")
endif()
if(NOT _workflow MATCHES "ios-source-downloads-v5-cmake-4\\.3\\.4-shellcheck-0\\.11\\.0")
    message(FATAL_ERROR "Source-download cache key must encode pinned validation tool versions")
endif()
if(_workflow MATCHES "brew install cmake")
    message(FATAL_ERROR "CI must not install unversioned Homebrew CMake")
endif()
if(_workflow MATCHES "brew install[^\\n]*shellcheck")
    message(FATAL_ERROR "CI must not install unversioned Homebrew ShellCheck")
endif()
if(NOT _workflow MATCHES "openmw-ios-required-static-dependencies")
    message(FATAL_ERROR "Gate 3 must build the complete declared static dependency target set")
endif()
if(NOT _workflow MATCHES "verify-link-map\\.py")
    message(FATAL_ERROR "Gate 4 must enforce exact linker-map archive participation")
endif()
string(FIND "${_workflow}"
    "Gate 4 preflight - resolve static link participation manifest"
    _participation_preflight)
string(FIND "${_workflow}" "--schema link-participation" _participation_schema)
string(FIND "${_workflow}"
    "ios-link-participation-\${CONFIGURATION}.template.tsv"
    _participation_template_diagnostic)
string(FIND "${_workflow}"
    "ios-link-participation-\${CONFIGURATION}.resolved.tsv"
    _participation_resolved_manifest)
string(FIND "${_workflow}"
    "ios-link-participation-\${CONFIGURATION}.sha256"
    _participation_hashes)
if(_participation_preflight EQUAL -1 OR
        _participation_schema EQUAL -1 OR
        _participation_template_diagnostic EQUAL -1 OR
        _participation_resolved_manifest EQUAL -1 OR
        _participation_hashes EQUAL -1)
    message(FATAL_ERROR
        "Gate 4 must resolve and retain the concrete link participation manifest")
endif()
if(NOT _workflow MATCHES "required-osg-plugins-\\*\\.txt")
    message(FATAL_ERROR "Diagnostics must preserve every configuration-specific registrar inventory")
endif()
file(READ "${PORT_ROOT}/scripts/validate-ios-dependencies.sh" _dependency_validator)
if(NOT _dependency_validator MATCHES
        "required-osg-plugins-\\$\\{CONFIGURATION\\}\\.txt")
    message(FATAL_ERROR "Gate 3 must validate the registrar inventory for the selected configuration")
endif()
string(FIND "${_dependency_validator}" "resolve-xcode-manifest.py" _manifest_resolver)
string(FIND "${_dependency_validator}" ".resolved.tsv" _resolved_manifest)
string(FIND "${_dependency_validator}" "--manifest" _resolved_inventory)
if(_manifest_resolver EQUAL -1 OR _resolved_manifest EQUAL -1 OR _resolved_inventory EQUAL -1)
    message(FATAL_ERROR "Gate 3 must resolve and inventory the concrete Xcode product manifest")
endif()
string(FIND "${_workflow}" "build/diagnostics/openmw.final-link-command.txt" _app_link_command)
if(_app_link_command EQUAL -1)
    message(FATAL_ERROR "Gate 5 must capture the full app's exact final linker command")
endif()
if(NOT _workflow MATCHES
        "verify-bundle\\.sh build/device/openmw\\.app")
    message(FATAL_ERROR "Gate 6 must verify the full app against its captured linker command")
endif()
file(READ "${PORT_ROOT}/scripts/verify-bundle.sh" _verify_bundle)
if(NOT _verify_bundle MATCHES "verify-linked-product\\.sh" OR
        NOT _verify_bundle MATCHES "LINKER_COMMAND_FILE")
    message(FATAL_ERROR "Bundle verification must pass the final linker command to product verification")
endif()

if(NOT _verify_bundle MATCHES "openmw-resources" OR
        NOT _verify_bundle MATCHES "collides case-insensitively")
    message(FATAL_ERROR
        "Bundle verification must require the relocated resources and reject the Apple Resources collision")
endif()

file(READ "${PORT_ROOT}/patches/openmw/0001-openmw-ios-structural-port.patch" _openmw_ios_patch)
string(FIND "${_openmw_ios_patch}"
    "OPENMW_RESOURCE_FILES \"openmw-resources\"" _configured_resource_root)
string(FIND "${_openmw_ios_patch}"
    "$<TARGET_BUNDLE_DIR:openmw>/openmw-resources" _staged_resource_root)
if(_configured_resource_root EQUAL -1 OR _staged_resource_root EQUAL -1)
    message(FATAL_ERROR
        "The iOS patch must configure and stage the non-conflicting openmw-resources root")
endif()

file(READ "${PORT_ROOT}/ios/openmw_ios_bootstrap.mm" _ios_bootstrap)
if(NOT _ios_bootstrap MATCHES "bundle / \"openmw-resources\"")
    message(FATAL_ERROR "The iOS bootstrap must pass the relocated resource root to OpenMW")
endif()

string(FIND "${_workflow}" "verify-resource-relocation.py" _resource_manifest_gate)
string(FIND "${_workflow}" "validate-apple-bundle.sh" _apple_bundle_gate)
if(_resource_manifest_gate EQUAL -1 OR _apple_bundle_gate EQUAL -1)
    message(FATAL_ERROR
        "Gate 6 must validate resource preservation and Apple-native bundle identity")
endif()
