#!/usr/bin/env bash

# ============================================================================
# Diagram Viewer - Universal Flutter Windows Build Script
# make.bash
# ============================================================================

set -Eeuo pipefail

# ============================================================================
# PROJECT CONFIGURATION
# ============================================================================

APP_NAME="diagram_viewer"
APP_VERSION="1.0.0"

BUILD_DIR="${BUILD_DIR:-build}"
INSTALL_DIR="${INSTALL_DIR:-${BUILD_DIR}/install}"
PACKAGE_DIR="${PACKAGE_DIR:-${BUILD_DIR}/packages}"

BUILD_TYPE="${BUILD_TYPE:-Release}"
ARCH="${ARCH:-x64}"

GENERATOR="${GENERATOR:-Visual Studio 17 2022}"

# ============================================================================
# COLORS / LOGGING
# ============================================================================

log() {
    printf '\n[BUILD] %s\n' "$1"
}

success() {
    printf '\n[SUCCESS] %s\n' "$1"
}

error() {
    printf '\n[ERROR] %s\n' "$1" >&2
}

# ============================================================================
# ERROR HANDLER
# ============================================================================

trap '
    error "Build failed at line ${LINENO}: ${BASH_COMMAND}"
' ERR

# ============================================================================
# PLATFORM CHECK
# ============================================================================

case "$(uname -s)" in

    MINGW*|MSYS*|CYGWIN*)
        PLATFORM="Windows"
        ;;

    Linux*)
        PLATFORM="Linux"
        ;;

    Darwin*)
        PLATFORM="macOS"
        ;;

    *)
        PLATFORM="Unknown"
        ;;

esac

log "Detected platform: ${PLATFORM}"

# ============================================================================
# COMMAND CHECK
# ============================================================================

require_command() {

    if ! command -v "$1" >/dev/null 2>&1; then

        error "Required command not found: $1"

        exit 1

    fi

}

require_command cmake

# ============================================================================
# FLUTTER CHECK
# ============================================================================

if command -v flutter >/dev/null 2>&1; then

    FLUTTER_VERSION="$(flutter --version | head -n 1)"

    log "Flutter: ${FLUTTER_VERSION}"

else

    error "Flutter SDK was not found in PATH."

    exit 1

fi

# ============================================================================
# PROJECT ROOT
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "${SCRIPT_DIR}"

log "Project root: ${SCRIPT_DIR}"

# ============================================================================
# CLEAN
# ============================================================================

clean() {

    log "Cleaning build directories..."

    rm -rf \
        "${BUILD_DIR}" \
        "${INSTALL_DIR}" \
        "${PACKAGE_DIR}"

    success "Clean completed."

}

# ============================================================================
# FLUTTER CLEAN
# ============================================================================

flutter_clean() {

    log "Running Flutter clean..."

    flutter clean

    success "Flutter clean completed."

}

# ============================================================================
# FLUTTER PUB GET
# ============================================================================

dependencies() {

    log "Resolving Flutter dependencies..."

    flutter pub get

    success "Dependencies resolved."

}

# ============================================================================
# FLUTTER DOCTOR
# ============================================================================

doctor() {

    log "Running Flutter doctor..."

    flutter doctor -v

}

# ============================================================================
# CONFIGURE
# ============================================================================

configure() {

    log "Configuring CMake..."

    cmake \
        -S . \
        -B "${BUILD_DIR}" \
        -G "${GENERATOR}" \
        -A "${ARCH}"

    success "CMake configuration completed."

}

# ============================================================================
# BUILD
# ============================================================================

build() {

    log "Building ${APP_NAME} ${APP_VERSION}"

    log "Configuration: ${BUILD_TYPE}"

    cmake \
        --build "${BUILD_DIR}" \
        --config "${BUILD_TYPE}" \
        --parallel

    success "Build completed."

}

# ============================================================================
# RUN
# ============================================================================

run() {

    log "Launching ${APP_NAME}..."

    cmake \
        --build "${BUILD_DIR}" \
        --config "${BUILD_TYPE}" \
        --target run

}

# ============================================================================
# INSTALL
# ============================================================================

install_app() {

    log "Installing application bundle..."

    rm -rf "${INSTALL_DIR}"

    cmake \
        --install "${BUILD_DIR}" \
        --config "${BUILD_TYPE}" \
        --prefix "${INSTALL_DIR}"

    success "Application installed to:"
    printf '%s\n' "${INSTALL_DIR}"

}

# ============================================================================
# PACKAGE
# ============================================================================

package_app() {

    log "Creating ${APP_NAME} package..."

    mkdir -p "${PACKAGE_DIR}"

    cmake \
        --build "${BUILD_DIR}" \
        --config "${BUILD_TYPE}" \
        --target package

    success "Package generation completed."

}

# ============================================================================
# BUILD + INSTALL + PACKAGE
# ============================================================================

release() {

    log "Starting production release build..."

    dependencies

    configure

    build

    install_app

    package_app

    success "Production release completed."

}

# ============================================================================
# REBUILD
# ============================================================================

rebuild() {

    clean

    dependencies

    configure

    build

}

# ============================================================================
# HELP
# ============================================================================

help() {

    cat <<EOF

${APP_NAME} - Flutter Windows Build System

Usage:

    ./make.bash <command>

Commands:

    configure       Configure CMake
    build           Build the application
    run             Build and launch the application
    install         Install the portable application bundle
    package         Create CPack package
    release         Build, install and package
    clean           Remove build artifacts
    flutter-clean   Run flutter clean
    deps            Resolve Flutter dependencies
    doctor          Run Flutter doctor
    rebuild         Clean and rebuild
    help            Show this help message

Environment variables:

    BUILD_TYPE      Debug | Profile | Release
    ARCH            x64 | Win32 | ARM64
    GENERATOR       CMake generator
    BUILD_DIR       Build directory
    INSTALL_DIR     Installation directory
    PACKAGE_DIR     Package directory

Examples:

    ./make.bash configure

    ./make.bash build

    ./make.bash run

    ./make.bash release

    BUILD_TYPE=Debug ./make.bash build

    ARCH=ARM64 ./make.bash configure

    GENERATOR="Visual Studio 17 2022" ./make.bash configure

EOF

}

# ============================================================================
# COMMAND DISPATCH
# ============================================================================

COMMAND="${1:-help}"

case "${COMMAND}" in

    configure)
        configure
        ;;

    build)
        build
        ;;

    run)
        run
        ;;

    install)
        install_app
        ;;

    package)
        package_app
        ;;

    release)
        release
        ;;

    clean)
        clean
        ;;

    flutter-clean)
        flutter_clean
        ;;

    deps)
        dependencies
        ;;

    doctor)
        doctor
        ;;

    rebuild)
        rebuild
        ;;

    help|-h|--help)
        help
        ;;

    *)
        error "Unknown command: ${COMMAND}"

        help

        exit 1
        ;;

esac
