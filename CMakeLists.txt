cmake_minimum_required(VERSION 3.19)

# ============================================================================
# KUBU / FLUTTER WINDOWS APPLICATION
# Production-grade universal Windows CMake configuration
# ============================================================================

project(
    diagram_viewer
    VERSION 1.0.0
    DESCRIPTION "Diagram Viewer - Flutter Windows Desktop Application"
    LANGUAGES CXX
)

# ============================================================================
# PROJECT METADATA
# ============================================================================

set(BINARY_NAME "diagram_viewer")
set(APPLICATION_ID "com.example.diagram_viewer")

set(APPLICATION_NAME "Diagram Viewer")
set(APPLICATION_DESCRIPTION "A production-grade Flutter Windows desktop application")
set(APPLICATION_VENDOR "Kubu")
set(APPLICATION_COPYRIGHT "Copyright (C) 2026 ${APPLICATION_VENDOR}")

# Semantic versioning
set(APPLICATION_VERSION_MAJOR "${PROJECT_VERSION_MAJOR}")
set(APPLICATION_VERSION_MINOR "${PROJECT_VERSION_MINOR}")
set(APPLICATION_VERSION_PATCH "${PROJECT_VERSION_PATCH}")

set(APPLICATION_VERSION
    "${APPLICATION_VERSION_MAJOR}.${APPLICATION_VERSION_MINOR}.${APPLICATION_VERSION_PATCH}"
)

# Flutter managed directory
set(FLUTTER_MANAGED_DIR
    "${CMAKE_CURRENT_SOURCE_DIR}/flutter"
)

# ============================================================================
# CMAKE POLICIES
# ============================================================================

if(POLICY CMP0063)
    cmake_policy(SET CMP0063 NEW)
endif()

if(POLICY CMP0091)
    # Enable modern MSVC runtime selection.
    cmake_policy(SET CMP0091 NEW)
endif()

# ============================================================================
# BUILD CONFIGURATION
# ============================================================================

# Single-config generators such as Ninja.
if(NOT CMAKE_CONFIGURATION_TYPES)

    if(NOT CMAKE_BUILD_TYPE)
        set(
            CMAKE_BUILD_TYPE
            "Debug"
            CACHE STRING
            "Build configuration"
            FORCE
        )
    endif()

    set_property(
        CACHE CMAKE_BUILD_TYPE
        PROPERTY STRINGS
        Debug
        Profile
        Release
        RelWithDebInfo
        MinSizeRel
    )

endif()

# ============================================================================
# ARCHITECTURE DETECTION
# ============================================================================

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(TARGET_ARCH "x64")
else()
    set(TARGET_ARCH "x86")
endif()

if(CMAKE_GENERATOR_PLATFORM)
    set(TARGET_PLATFORM "${CMAKE_GENERATOR_PLATFORM}")
else()
    set(TARGET_PLATFORM "${TARGET_ARCH}")
endif()

message(STATUS "============================================================")
message(STATUS "Diagram Viewer Windows Build Configuration")
message(STATUS "============================================================")
message(STATUS "Application       : ${APPLICATION_NAME}")
message(STATUS "Application ID    : ${APPLICATION_ID}")
message(STATUS "Version           : ${APPLICATION_VERSION}")
message(STATUS "Target            : ${TARGET_PLATFORM}")
message(STATUS "Generator         : ${CMAKE_GENERATOR}")
message(STATUS "Compiler ID       : ${CMAKE_CXX_COMPILER_ID}")
message(STATUS "Compiler          : ${CMAKE_CXX_COMPILER}")
message(STATUS "CMake Version     : ${CMAKE_VERSION}")
message(STATUS "============================================================")

# ============================================================================
# WINDOWS SDK DETECTION
# ============================================================================

if(WIN32)

    if(NOT CMAKE_SYSTEM_VERSION)
        message(
            STATUS
            "Windows SDK version was not explicitly specified."
        )
    else()
        message(
            STATUS
            "Windows SDK version: ${CMAKE_SYSTEM_VERSION}"
        )
    endif()

    # Detect Windows SDK root through environment.
    if(DEFINED ENV{WindowsSdkDir})

        file(
            TO_CMAKE_PATH
            "$ENV{WindowsSdkDir}"
            WINDOWS_SDK_ROOT
        )

        message(
            STATUS
            "Windows SDK root: ${WINDOWS_SDK_ROOT}"
        )

    endif()

endif()

# ============================================================================
# WINDOWS PLATFORM DEFINITIONS
# ============================================================================

if(WIN32)

    add_compile_definitions(
        UNICODE
        _UNICODE
        NOMINMAX
        WIN32_LEAN_AND_MEAN
        _WIN32_WINNT=0x0A00
        NTDDI_VERSION=0x0A000000
    )

endif()

# ============================================================================
# C++ STANDARD
# ============================================================================

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# ============================================================================
# MSVC RUNTIME
# ============================================================================
#
# Use the dynamic MSVC runtime:
#
# Debug:
#   MultiThreadedDebugDLL
#
# Release:
#   MultiThreadedDLL
#
# This avoids static runtime conflicts with Flutter plugins and third-party
# libraries.

if(MSVC)

    set(
        CMAKE_MSVC_RUNTIME_LIBRARY
        "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL"
    )

endif()

# ============================================================================
# GLOBAL OUTPUT DIRECTORIES
# ============================================================================

set(
    CMAKE_RUNTIME_OUTPUT_DIRECTORY
    "${CMAKE_BINARY_DIR}/bin"
)

set(
    CMAKE_LIBRARY_OUTPUT_DIRECTORY
    "${CMAKE_BINARY_DIR}/lib"
)

set(
    CMAKE_ARCHIVE_OUTPUT_DIRECTORY
    "${CMAKE_BINARY_DIR}/lib"
)

# Multi-configuration generators
foreach(CONFIGURATION Debug Profile Release RelWithDebInfo MinSizeRel)

    string(TOUPPER "${CONFIGURATION}" CONFIG_UPPER)

    set(
        CMAKE_RUNTIME_OUTPUT_DIRECTORY_${CONFIG_UPPER}
        "${CMAKE_BINARY_DIR}/bin/${CONFIGURATION}"
    )

    set(
        CMAKE_LIBRARY_OUTPUT_DIRECTORY_${CONFIG_UPPER}
        "${CMAKE_BINARY_DIR}/lib/${CONFIGURATION}"
    )

    set(
        CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${CONFIG_UPPER}
        "${CMAKE_BINARY_DIR}/lib/${CONFIGURATION}"
    )

endforeach()

# ============================================================================
# STANDARD COMPILER SETTINGS
# ============================================================================

function(APPLY_STANDARD_SETTINGS TARGET)

    target_compile_features(
        ${TARGET}
        PRIVATE
        cxx_std_17
    )

    # ------------------------------------------------------------
    # MSVC
    # ------------------------------------------------------------

    if(MSVC)

        target_compile_options(
            ${TARGET}
            PRIVATE

            /W4

            # Treat warnings as errors in CI.
            $<$<BOOL:$ENV{CI}>:/WX>

            # UTF-8 source and execution character sets.
            /utf-8

            # Parallel compilation.
            /MP

            # Security checks.
            /GS

            # Control Flow Guard where supported.
            $<$<CONFIG:Release>:/guard:cf>

        )

        target_link_options(
            ${TARGET}
            PRIVATE

            # Enable Control Flow Guard.
            $<$<CONFIG:Release>:/GUARD:CF>

        )

    # ------------------------------------------------------------
    # Clang / Clang-cl
    # ------------------------------------------------------------

    elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")

        target_compile_options(
            ${TARGET}
            PRIVATE

            -Wall
            -Wextra
            -Wpedantic

            $<$<BOOL:$ENV{CI}>:-Werror>

            -finput-charset=UTF-8
            -fexec-charset=UTF-8

        )

    # ------------------------------------------------------------
    # GCC / MinGW
    # ------------------------------------------------------------

    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")

        target_compile_options(
            ${TARGET}
            PRIVATE

            -Wall
            -Wextra
            -Wpedantic

            $<$<BOOL:$ENV{CI}>:-Werror>

        )

    endif()

    # =========================================================================
    # DEBUG
    # =========================================================================

    target_compile_definitions(
        ${TARGET}
        PRIVATE

        $<$<CONFIG:Debug>:DEBUG>

    )

    # =========================================================================
    # RELEASE
    # =========================================================================

    target_compile_definitions(
        ${TARGET}
        PRIVATE

        $<$<CONFIG:Release>:NDEBUG>
        $<$<CONFIG:Profile>:NDEBUG>
        $<$<CONFIG:RelWithDebInfo>:NDEBUG>
        $<$<CONFIG:MinSizeRel>:NDEBUG>

    )

    # =========================================================================
    # OPTIMIZATION
    # =========================================================================

    if(MSVC)

        target_compile_options(
            ${TARGET}
            PRIVATE

            # Release
            $<$<CONFIG:Release>:/O2>

            # Profile
            $<$<CONFIG:Profile>:/O2>

            # RelWithDebInfo
            $<$<CONFIG:RelWithDebInfo>:/O2>

            # MinSizeRel
            $<$<CONFIG:MinSizeRel>:/O1>

        )

    elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")

        target_compile_options(
            ${TARGET}
            PRIVATE

            $<$<CONFIG:Release>:-O3>
            $<$<CONFIG:Profile>:-O2>
            $<$<CONFIG:RelWithDebInfo>:-O2>
            $<$<CONFIG:MinSizeRel>:-Os>

        )

    endif()

endfunction()

# ============================================================================
# APPLICATION VERSION HEADER
# ============================================================================

set(
    GENERATED_INCLUDE_DIR
    "${CMAKE_CURRENT_BINARY_DIR}/generated"
)

file(MAKE_DIRECTORY "${GENERATED_INCLUDE_DIR}")

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/version.h.in"
    "${GENERATED_INCLUDE_DIR}/version.h"
    @ONLY
)

# ============================================================================
# FLUTTER MANAGED BUILD
# ============================================================================

if(NOT EXISTS "${FLUTTER_MANAGED_DIR}/CMakeLists.txt")

    message(
        FATAL_ERROR
        "Flutter managed directory not found: ${FLUTTER_MANAGED_DIR}"
    )

endif()

add_subdirectory(
    "${FLUTTER_MANAGED_DIR}"
)

# ============================================================================
# FLUTTER PLUGINS
# ============================================================================

if(EXISTS "${FLUTTER_MANAGED_DIR}/generated_plugins.cmake")

    include(
        "${FLUTTER_MANAGED_DIR}/generated_plugins.cmake"
    )

endif()

# ============================================================================
# APPLICATION DEFINITIONS
# ============================================================================

set(
    APPLICATION_VERSION_STRING
    "${APPLICATION_VERSION}"
)

# ============================================================================
# APPLICATION TARGET
# ============================================================================

add_executable(
    ${BINARY_NAME}
    WIN32

    "runner/main.cpp"
    "runner/flutter_window.cpp"
    "runner/utils.cpp"

    "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

# ============================================================================
# INCLUDE DIRECTORIES
# ============================================================================

target_include_directories(
    ${BINARY_NAME}
    PRIVATE

    "${CMAKE_CURRENT_SOURCE_DIR}/runner"
    "${GENERATED_INCLUDE_DIR}"
)

# ============================================================================
# COMPILE DEFINITIONS
# ============================================================================

target_compile_definitions(
    ${BINARY_NAME}
    PRIVATE

    APPLICATION_ID="${APPLICATION_ID}"
    APPLICATION_NAME="${APPLICATION_NAME}"
    APPLICATION_VERSION="${APPLICATION_VERSION}"
    APPLICATION_VENDOR="${APPLICATION_VENDOR}"
)

# ============================================================================
# STANDARD SETTINGS
# ============================================================================

apply_standard_settings(
    ${BINARY_NAME}
)

# ============================================================================
# FLUTTER LINKING
# ============================================================================

target_link_libraries(
    ${BINARY_NAME}
    PRIVATE

    flutter
)

# ============================================================================
# WINDOWS SYSTEM LIBRARIES
# ============================================================================

if(WIN32)

    target_link_libraries(
        ${BINARY_NAME}
        PRIVATE

        user32
        shell32
        ole32
        oleaut32
        version
        advapi32
        shlwapi
        dwmapi
    )

endif()

# ============================================================================
# FLUTTER BUILD DEPENDENCY
# ============================================================================

if(TARGET flutter_assemble)

    add_dependencies(
        ${BINARY_NAME}
        flutter_assemble
    )

endif()

# ============================================================================
# WINDOWS EXECUTABLE OUTPUT
# ============================================================================

set_target_properties(
    ${BINARY_NAME}

    PROPERTIES

    OUTPUT_NAME
    "${BINARY_NAME}"

    RUNTIME_OUTPUT_DIRECTORY
    "${CMAKE_BINARY_DIR}/bin"

    VS_DEBUGGER_WORKING_DIRECTORY
    "$<TARGET_FILE_DIR:${BINARY_NAME}>"

    VS_GLOBAL_KEYWORD
    "Win32Proj"

    VS_GLOBAL_ROOTNAMESPACE
    "${APPLICATION_ID}"

    VS_GLOBAL_ApplicationIcon
    "${CMAKE_CURRENT_SOURCE_DIR}/runner/resources/app_icon.ico"

    WIN32_EXECUTABLE
    TRUE
)

# ============================================================================
# FLUTTER ENGINE DEPLOYMENT
# ============================================================================

add_custom_command(
    TARGET ${BINARY_NAME}
    POST_BUILD

    COMMAND
        ${CMAKE_COMMAND}
        -E
        copy_if_different

        "${FLUTTER_LIBRARY}"

        "$<TARGET_FILE_DIR:${BINARY_NAME}>/flutter_windows.dll"

    COMMENT
        "Deploying Flutter Windows engine..."
)

# ============================================================================
# FLUTTER ICU DATA
# ============================================================================

add_custom_command(
    TARGET ${BINARY_NAME}
    POST_BUILD

    COMMAND
        ${CMAKE_COMMAND}
        -E
        make_directory

        "$<TARGET_FILE_DIR:${BINARY_NAME}>/data"

    COMMAND
        ${CMAKE_COMMAND}
        -E
        copy_if_different

        "${FLUTTER_ICU_DATA_FILE}"

        "$<TARGET_FILE_DIR:${BINARY_NAME}>/data/icudtl.dat"

    COMMENT
        "Deploying Flutter ICU data..."
)

# ============================================================================
# FLUTTER ASSETS
# ============================================================================

add_custom_command(
    TARGET ${BINARY_NAME}
    POST_BUILD

    COMMAND
        ${CMAKE_COMMAND}
        -E
        copy_directory

        "${PROJECT_BUILD_DIR}/flutter_assets"

        "$<TARGET_FILE_DIR:${BINARY_NAME}>/data/flutter_assets"

    COMMENT
        "Deploying Flutter assets..."
)

# ============================================================================
# PLUGIN DEPLOYMENT
# ============================================================================

if(PLUGIN_BUNDLED_LIBRARIES)

    add_custom_command(
        TARGET ${BINARY_NAME}
        POST_BUILD

        COMMAND
            ${CMAKE_COMMAND}
            -E
            copy_if_different

            ${PLUGIN_BUNDLED_LIBRARIES}

            "$<TARGET_FILE_DIR:${BINARY_NAME}>"

        COMMENT
            "Deploying Flutter plugin libraries..."
    )

endif()

# ============================================================================
# RUN TARGET
# ============================================================================

add_custom_target(
    run

    COMMAND
        ${CMAKE_COMMAND}
        -E
        echo
        "Launching ${APPLICATION_NAME}..."

    COMMAND
        "$<TARGET_FILE:${BINARY_NAME}>"

    DEPENDS
        ${BINARY_NAME}

    WORKING_DIRECTORY
        "$<TARGET_FILE_DIR:${BINARY_NAME}>"

    USES_TERMINAL

    COMMENT
        "Running ${APPLICATION_NAME}..."
)

# ============================================================================
# INSTALLATION / PORTABLE BUNDLE
# ============================================================================

include(GNUInstallDirs)

set(
    INSTALL_BUNDLE_DIR
    "${CMAKE_INSTALL_PREFIX}"
)

set(
    INSTALL_BUNDLE_DATA_DIR
    "${CMAKE_INSTALL_PREFIX}/data"
)

set(
    INSTALL_BUNDLE_LIB_DIR
    "${CMAKE_INSTALL_PREFIX}"
)

# ============================================================================
# INSTALL EXECUTABLE
# ============================================================================

install(
    TARGETS
        ${BINARY_NAME}

    RUNTIME
        DESTINATION .

    COMPONENT Runtime
)

# ============================================================================
# INSTALL FLUTTER ENGINE
# ============================================================================

install(
    FILES
        "${FLUTTER_LIBRARY}"

    DESTINATION .

    COMPONENT Runtime
)

# ============================================================================
# INSTALL ICU DATA
# ============================================================================

install(
    FILES
        "${FLUTTER_ICU_DATA_FILE}"

    DESTINATION data

    COMPONENT Runtime
)

# ============================================================================
# INSTALL FLUTTER ASSETS
# ============================================================================

install(
    DIRECTORY
        "${PROJECT_BUILD_DIR}/flutter_assets"

    DESTINATION data

    COMPONENT Runtime
)

# ============================================================================
# INSTALL PLUGIN LIBRARIES
# ============================================================================

if(PLUGIN_BUNDLED_LIBRARIES)

    install(
        FILES
            ${PLUGIN_BUNDLED_LIBRARIES}

        DESTINATION .

        COMPONENT Runtime
    )

endif()

# ============================================================================
# INSTALL AOT LIBRARY
# ============================================================================

if(AOT_LIBRARY)

    install(
        FILES
            "${AOT_LIBRARY}"

        DESTINATION .

        COMPONENT Runtime
    )

endif()

# ============================================================================
# CMAKE PACKAGE CONFIGURATION
# ============================================================================

set(
    CPACK_PACKAGE_NAME
    "${BINARY_NAME}"
)

set(
    CPACK_PACKAGE_VENDOR
    "${APPLICATION_VENDOR}"
)

set(
    CPACK_PACKAGE_DESCRIPTION_SUMMARY
    "${APPLICATION_DESCRIPTION}"
)

set(
    CPACK_PACKAGE_VERSION
    "${APPLICATION_VERSION}"
)

set(
    CPACK_PACKAGE_VERSION_MAJOR
    "${APPLICATION_VERSION_MAJOR}"
)

set(
    CPACK_PACKAGE_VERSION_MINOR
    "${APPLICATION_VERSION_MINOR}"
)

set(
    CPACK_PACKAGE_VERSION_PATCH
    "${APPLICATION_VERSION_PATCH}"
)

set(
    CPACK_PACKAGE_INSTALL_DIRECTORY
    "${APPLICATION_NAME}"
)

# ============================================================================
# CPack ZIP
# ============================================================================

set(
    CPACK_GENERATOR
    "ZIP"
)

set(
    CPACK_ARCHIVE_OUTPUT_DIRECTORY
    "${CMAKE_BINARY_DIR}/packages"
)

set(
    CPACK_ARCHIVE_FILE_NAME
    "${BINARY_NAME}-${APPLICATION_VERSION}-${TARGET_PLATFORM}"
)

# ============================================================================
# OPTIONAL NSIS
# ============================================================================

if(WIN32)

    set(
        CPACK_NSIS_DISPLAY_NAME
        "${APPLICATION_NAME}"
    )

    set(
        CPACK_NSIS_PACKAGE_NAME
        "${APPLICATION_NAME}"
    )

    set(
        CPACK_NSIS_CONTACT
        "${APPLICATION_VENDOR}"
    )

    set(
        CPACK_NSIS_HELP_LINK
        ""
    )

    set(
        CPACK_NSIS_URL_INFO_ABOUT
        ""
    )

    # Uncomment to make NSIS the default package generator.
    #
    # set(CPACK_GENERATOR "ZIP;NSIS")

endif()

# ============================================================================
# CPack
# ============================================================================

include(CPack)

# ============================================================================
# PACKAGE TARGET
# ============================================================================

add_custom_target(
    package_app

    COMMAND
        ${CMAKE_COMMAND}
        --build
        "${CMAKE_BINARY_DIR}"
        --target
        package

    USES_TERMINAL

    COMMENT
        "Packaging ${APPLICATION_NAME} ${APPLICATION_VERSION}..."
)

# ============================================================================
# BUILD INFORMATION
# ============================================================================

find_package(Git QUIET)

if(GIT_FOUND)

    execute_process(
        COMMAND
            ${GIT_EXECUTABLE}
            rev-parse
            --short
            HEAD

        WORKING_DIRECTORY
            "${CMAKE_CURRENT_SOURCE_DIR}"

        OUTPUT_VARIABLE
            GIT_COMMIT_HASH

        OUTPUT_STRIP_TRAILING_WHITESPACE

        ERROR_QUIET
    )

endif()

if(NOT GIT_COMMIT_HASH)

    set(
        GIT_COMMIT_HASH
        "unknown"
    )

endif()

message(STATUS "Git commit        : ${GIT_COMMIT_HASH}")

# ============================================================================
# FINAL BUILD SUMMARY
# ============================================================================

message(STATUS "")
message(STATUS "============================================================")
message(STATUS "Configuration complete.")
message(STATUS "")
message(STATUS "Application       : ${APPLICATION_NAME}")
message(STATUS "Binary            : ${BINARY_NAME}")
message(STATUS "Application ID    : ${APPLICATION_ID}")
message(STATUS "Version           : ${APPLICATION_VERSION}")
message(STATUS "Architecture      : ${TARGET_PLATFORM}")
message(STATUS "Git Commit        : ${GIT_COMMIT_HASH}")
message(STATUS "")
message(STATUS "Build target      : ${BINARY_NAME}")
message(STATUS "Run target        : run")
message(STATUS "Package target    : package_app")
message(STATUS "CPack             : package")
message(STATUS "============================================================")
