cmake_minimum_required(VERSION 3.19)

# ══════════════════════════════════════════════════════════════════════════════
# KUBUVERSE / FLUTTER WINDOWS RUNNER
# Production-grade universal CMake configuration
#
# Supported:
#   - MSVC / Visual Studio
#   - Clang / clang-cl
#   - Debug / Release / RelWithDebInfo / MinSizeRel
#   - Windows SDK detection
#   - Flutter generated build integration
#   - Version metadata
#   - Installation
#   - Optional CPack packaging
#
# Expected Flutter variables/targets:
#   BINARY_NAME
#   FLUTTER_MANAGED_DIR
#   FLUTTER_VERSION
#   FLUTTER_VERSION_MAJOR
#   FLUTTER_VERSION_MINOR
#   FLUTTER_VERSION_PATCH
#   FLUTTER_VERSION_BUILD
#   flutter
#   flutter_wrapper_app
#   flutter_assemble
#   apply_standard_settings()
# ══════════════════════════════════════════════════════════════════════════════


# ──────────────────────────────────────────────────────────────────────────────
# CMake policy
# ──────────────────────────────────────────────────────────────────────────────

cmake_policy(VERSION 3.19...3.31)


# ──────────────────────────────────────────────────────────────────────────────
# Project metadata
# ──────────────────────────────────────────────────────────────────────────────

set(PROJECT_NAME "runner")

project(
  ${PROJECT_NAME}
  VERSION 1.0.0
  LANGUAGES CXX RC
)


# ──────────────────────────────────────────────────────────────────────────────
# Global build configuration
# ──────────────────────────────────────────────────────────────────────────────

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY
    "${CMAKE_BINARY_DIR}/bin"
)

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY
    "${CMAKE_BINARY_DIR}/lib"
)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY
    "${CMAKE_BINARY_DIR}/lib"
)


# ──────────────────────────────────────────────────────────────────────────────
# Build type
#
# Multi-config generators such as Visual Studio ignore CMAKE_BUILD_TYPE.
# Single-config generators use it.
# ──────────────────────────────────────────────────────────────────────────────

if(NOT CMAKE_CONFIGURATION_TYPES AND NOT CMAKE_BUILD_TYPE)
  set(
    CMAKE_BUILD_TYPE
    Release
    CACHE STRING
    "Build type"
  )

  set_property(
    CACHE CMAKE_BUILD_TYPE
    PROPERTY STRINGS
      Debug
      Release
      RelWithDebInfo
      MinSizeRel
  )
endif()


# ──────────────────────────────────────────────────────────────────────────────
# Windows validation
# ──────────────────────────────────────────────────────────────────────────────

if(NOT WIN32)
  message(
    FATAL_ERROR
    "This CMake configuration is intended for Flutter Windows builds."
  )
endif()


# ──────────────────────────────────────────────────────────────────────────────
# Windows SDK detection
# ──────────────────────────────────────────────────────────────────────────────

if(CMAKE_SYSTEM_VERSION)
  set(WINDOWS_SDK_VERSION "${CMAKE_SYSTEM_VERSION}")
else()
  set(WINDOWS_SDK_VERSION "Unknown")
endif()

message(STATUS "")
message(STATUS "════════ Flutter Windows Build Environment ════════")
message(STATUS "CMake version       : ${CMAKE_VERSION}")
message(STATUS "Generator           : ${CMAKE_GENERATOR}")
message(STATUS "System              : ${CMAKE_SYSTEM_NAME}")
message(STATUS "Architecture        : ${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "Windows SDK         : ${WINDOWS_SDK_VERSION}")
message(STATUS "Compiler            : ${CMAKE_CXX_COMPILER_ID}")
message(STATUS "Compiler version    : ${CMAKE_CXX_COMPILER_VERSION}")
message(STATUS "Build type          : ${CMAKE_BUILD_TYPE}")
message(STATUS "════════════════════════════════════════════════════")
message(STATUS "")


# Require a modern Windows SDK.
#
# Flutter Windows applications normally require a reasonably recent SDK.
# Adjust this minimum if your project has a stricter compatibility target.

if(MSVC AND CMAKE_SYSTEM_VERSION VERSION_LESS "10.0")
  message(
    FATAL_ERROR
    "Windows 10 SDK or newer is required. "
    "Detected SDK: ${CMAKE_SYSTEM_VERSION}"
  )
endif()


# ──────────────────────────────────────────────────────────────────────────────
# Compiler detection
# ──────────────────────────────────────────────────────────────────────────────

if(MSVC)

  message(
    STATUS
    "Compiler backend: Microsoft Visual C++ / MSVC"
  )

  add_compile_options(
    /W4
    /permissive-
    /EHsc
    /utf-8
  )

elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")

  message(
    STATUS
    "Compiler backend: LLVM Clang / clang-cl"
  )

  add_compile_options(
    -Wall
    -Wextra
    -Wpedantic
    -fexceptions
  )

elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")

  message(
    STATUS
    "Compiler backend: GNU C++"
  )

  add_compile_options(
    -Wall
    -Wextra
    -Wpedantic
  )

else()

  message(
    WARNING
    "Unknown C++ compiler: ${CMAKE_CXX_COMPILER_ID}"
  )

endif()


# ──────────────────────────────────────────────────────────────────────────────
# Architecture validation
# ──────────────────────────────────────────────────────────────────────────────

if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8)

  message(
    FATAL_ERROR
    "A 64-bit Windows target is required. "
    "Flutter Windows desktop builds should use x64."
  )

endif()


# ──────────────────────────────────────────────────────────────────────────────
# Flutter executable name
# ──────────────────────────────────────────────────────────────────────────────

if(NOT DEFINED BINARY_NAME)

  set(
    BINARY_NAME
    "runner"
    CACHE STRING
    "Flutter Windows executable name"
  )

endif()


# ──────────────────────────────────────────────────────────────────────────────
# Flutter managed directory validation
# ──────────────────────────────────────────────────────────────────────────────

if(NOT DEFINED FLUTTER_MANAGED_DIR)

  message(
    FATAL_ERROR
    "FLUTTER_MANAGED_DIR is not defined. "
    "This CMake project must be configured through Flutter's Windows build system."
  )

endif()


# ──────────────────────────────────────────────────────────────────────────────
# Flutter runner executable
# ──────────────────────────────────────────────────────────────────────────────

add_executable(
  ${BINARY_NAME}
  WIN32

  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"

  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"

  "Runner.rc"
  "runner.exe.manifest"
)


# ──────────────────────────────────────────────────────────────────────────────
# Flutter standard settings
# ──────────────────────────────────────────────────────────────────────────────

if(COMMAND apply_standard_settings)

  apply_standard_settings(
    ${BINARY_NAME}
  )

else()

  message(
    WARNING
    "apply_standard_settings() is not available. "
    "Using local CMake configuration."
  )

endif()


# ──────────────────────────────────────────────────────────────────────────────
# Version metadata
# ──────────────────────────────────────────────────────────────────────────────

set(FLUTTER_VERSION_STRING
    "${FLUTTER_VERSION}"
)

if(NOT FLUTTER_VERSION_STRING)
  set(FLUTTER_VERSION_STRING
      "${PROJECT_VERSION}"
  )
endif()


target_compile_definitions(
  ${BINARY_NAME}
  PRIVATE

  FLUTTER_VERSION="${FLUTTER_VERSION_STRING}"

  FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}
  FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}
  FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}
  FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}

  NOMINMAX
  WIN32_LEAN_AND_MEAN
  UNICODE
  _UNICODE
)


# ──────────────────────────────────────────────────────────────────────────────
# Include directories
# ──────────────────────────────────────────────────────────────────────────────

target_include_directories(
  ${BINARY_NAME}
  PRIVATE

  "${CMAKE_CURRENT_SOURCE_DIR}"
  "${CMAKE_SOURCE_DIR}"
)


# ──────────────────────────────────────────────────────────────────────────────
# Windows system libraries
# ──────────────────────────────────────────────────────────────────────────────

target_link_libraries(
  ${BINARY_NAME}
  PRIVATE

  flutter
  flutter_wrapper_app

  dwmapi.lib
)


# ──────────────────────────────────────────────────────────────────────────────
# Flutter build dependency
# ──────────────────────────────────────────────────────────────────────────────

if(TARGET flutter_assemble)

  add_dependencies(
    ${BINARY_NAME}
    flutter_assemble
  )

else()

  message(
    WARNING
    "Flutter target 'flutter_assemble' was not found."
  )

endif()


# ──────────────────────────────────────────────────────────────────────────────
# MSVC runtime configuration
#
# Use the dynamic runtime by default:
#   Debug   -> MultiThreadedDebugDLL
#   Release -> MultiThreadedDLL
#
# This avoids static CRT duplication in most Flutter/plugin environments.
# ──────────────────────────────────────────────────────────────────────────────

if(MSVC)

  set_property(
    TARGET ${BINARY_NAME}
    PROPERTY
      MSVC_RUNTIME_LIBRARY
      "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL"
  )

endif()


# ──────────────────────────────────────────────────────────────────────────────
# Debug configuration
# ──────────────────────────────────────────────────────────────────────────────

target_compile_definitions(
  ${BINARY_NAME}
  PRIVATE

  $<$<CONFIG:Debug>:DEBUG_BUILD=1>
  $<$<CONFIG:Debug>:_DEBUG>
)


# ──────────────────────────────────────────────────────────────────────────────
# Release configuration
# ──────────────────────────────────────────────────────────────────────────────

target_compile_definitions(
  ${BINARY_NAME}
  PRIVATE

  $<$<CONFIG:Release>:NDEBUG>
  $<$<CONFIG:RelWithDebInfo>:NDEBUG>
  $<$<CONFIG:MinSizeRel>:NDEBUG>
)


# ──────────────────────────────────────────────────────────────────────────────
# Optimization settings
# ──────────────────────────────────────────────────────────────────────────────

if(MSVC)

  target_compile_options(
    ${BINARY_NAME}
    PRIVATE

    $<$<CONFIG:Release>:/O2>
    $<$<CONFIG:RelWithDebInfo>:/O2>
    $<$<CONFIG:MinSizeRel>:/O1>
  )

elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")

  target_compile_options(
    ${BINARY_NAME}
    PRIVATE

    $<$<CONFIG:Release>:-O3>
    $<$<CONFIG:RelWithDebInfo>:-O2>
    $<$<CONFIG:MinSizeRel>:-Os>
  )

endif()


# ──────────────────────────────────────────────────────────────────────────────
# Installation layout
#
# install prefix:
#   <prefix>/
#     bin/
#       runner.exe
# ──────────────────────────────────────────────────────────────────────────────

include(GNUInstallDirs)

install(
  TARGETS
    ${BINARY_NAME}

  RUNTIME
    DESTINATION ${CMAKE_INSTALL_BINDIR}
)


# ──────────────────────────────────────────────────────────────────────────────
# Install Flutter assets
#
# Flutter's generated bundle normally lives under:
#
#   ${CMAKE_BINARY_DIR}/flutter_assets
#
# Only install it when it exists.
# ──────────────────────────────────────────────────────────────────────────────

set(FLUTTER_ASSETS_DIR
    "${CMAKE_BINARY_DIR}/flutter_assets"
)

if(EXISTS "${FLUTTER_ASSETS_DIR}")

  install(
    DIRECTORY
      "${FLUTTER_ASSETS_DIR}"

    DESTINATION
      ${CMAKE_INSTALL_BINDIR}
  )

endif()


# ──────────────────────────────────────────────────────────────────────────────
# CPack configuration
#
# Enable with:
#
#   cmake -S . -B build
#   cmake --build build --config Release
#   cpack --config build/CPackConfig.cmake
# ──────────────────────────────────────────────────────────────────────────────

option(
  ENABLE_CPACK
  "Enable CPack packaging"
  OFF
)

if(ENABLE_CPACK)

  include(InstallRequiredSystemLibraries)

  set(
    CPACK_PACKAGE_NAME
    "${PROJECT_NAME}"
  )

  set(
    CPACK_PACKAGE_VENDOR
    "KUBU"
  )

  set(
    CPACK_PACKAGE_DESCRIPTION_SUMMARY
    "Flutter Windows desktop application"
  )

  set(
    CPACK_PACKAGE_VERSION
    "${PROJECT_VERSION}"
  )

  set(
    CPACK_PACKAGE_INSTALL_DIRECTORY
    "${PROJECT_NAME}"
  )

  # NSIS installer
  set(
    CPACK_GENERATOR
    "NSIS"
  )

  set(
    CPACK_NSIS_DISPLAY_NAME
    "${PROJECT_NAME}"
  )

  set(
    CPACK_NSIS_PACKAGE_NAME
    "${PROJECT_NAME}"
  )

  set(
    CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL
    ON
  )

  include(CPack)

endif()


# ──────────────────────────────────────────────────────────────────────────────
# Build summary
# ──────────────────────────────────────────────────────────────────────────────

message(STATUS "")
message(STATUS "════════ Flutter Runner Configuration ════════")
message(STATUS "Executable          : ${BINARY_NAME}")
message(STATUS "Project version     : ${PROJECT_VERSION}")
message(STATUS "Flutter version     : ${FLUTTER_VERSION_STRING}")
message(STATUS "Compiler            : ${CMAKE_CXX_COMPILER_ID}")
message(STATUS "Compiler version    : ${CMAKE_CXX_COMPILER_VERSION}")
message(STATUS "Windows SDK         : ${WINDOWS_SDK_VERSION}")
message(STATUS "Architecture        : x64")
message(STATUS "CPack enabled       : ${ENABLE_CPACK}")
message(STATUS "══════════════════════════════════════════════")
message(STATUS "")
