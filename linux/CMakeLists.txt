# Project-level configuration.
cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "roms_downloader")
# The unique GTK application identifier for this application. See:
# https://wiki.gnome.org/HowDoI/ChooseApplicationID
set(APPLICATION_ID "name.rafaismy.roms_downloader")

# Universal build support
option(BUILD_UNIVERSAL "Build universal binary for multiple architectures" OFF)
set(TARGET_ARCHITECTURES "native" CACHE STRING "Target architectures (native, x86_64, i386, armv7, aarch64, universal)")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(SET CMP0063 NEW)

# Load bundled libraries from the lib/ directory relative to the binary.
set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

# Root filesystem for cross-building.
if(FLUTTER_TARGET_PLATFORM_SYSROOT)
  set(CMAKE_SYSROOT ${FLUTTER_TARGET_PLATFORM_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
endif()

# Cross-compilation support
if(CMAKE_CROSSCOMPILING)
    # Set up cross-compilation paths
    set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
    set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
    set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
    set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
endif()

# Define build configuration options.
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Debug" CACHE
    STRING "Flutter build mode" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
    "Debug" "Profile" "Release")
endif()

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
    target_compile_features(${TARGET} PUBLIC cxx_std_14)
    target_compile_options(${TARGET} PRIVATE -Wall -Werror)
    target_compile_options(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:-O3>")
    target_compile_definitions(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:NDEBUG>")
    
    # Add architecture-specific optimizations
    if(BUILD_UNIVERSAL)
        # Universal build - let the system handle architecture detection
        message(STATUS "Building universal binary")
    elseif(TARGET_ARCHITECTURES STREQUAL "x86_64")
        target_compile_options(${TARGET} PRIVATE -march=x86-64 -mtune=generic)
    elseif(TARGET_ARCHITECTURES STREQUAL "i386")
        target_compile_options(${TARGET} PRIVATE -march=i686 -mtune=generic -m32)
        set_target_properties(${TARGET} PROPERTIES LINK_FLAGS "-m32")
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)" OR TARGET_ARCHITECTURES STREQUAL "aarch64")
        target_compile_options(${TARGET} PRIVATE -march=armv8-a)
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^arm" OR TARGET_ARCHITECTURES STREQUAL "armv7")
        target_compile_options(${TARGET} PRIVATE -march=armv7-a -mfpu=neon)
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|amd64)" OR TARGET_ARCHITECTURES STREQUAL "native")
        target_compile_options(${TARGET} PRIVATE -march=native -mtune=native)
    endif()
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")

# Enhanced Flutter target handling for cross-compilation
if(CMAKE_CROSSCOMPILING)
    # When cross-compiling, be more flexible with Flutter tool failures
    message(STATUS "Cross-compilation detected, using flexible Flutter build approach")
    
    # Try to find pre-built Flutter artifacts first
    set(PREBUILT_FLUTTER_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../build/linux")
    if(EXISTS "${PREBUILT_FLUTTER_DIR}")
        message(STATUS "Found pre-built Flutter artifacts at ${PREBUILT_FLUTTER_DIR}")
        # Use existing artifacts instead of rebuilding
        set(FLUTTER_LIBRARY "${PREBUILT_FLUTTER_DIR}/bundle/lib/libflutter_linux_gtk.so")
        set(FLUTTER_ICU_DATA_FILE "${PREBUILT_FLUTTER_DIR}/bundle/data/icudtl.dat")
    endif()
endif()

add_subdirectory(${FLUTTER_MANAGED_DIR})

# System-level dependencies.
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")

# Run the Flutter tool portions of the build. This must not be removed.
# But make it more tolerant of failures during cross-compilation
if(CMAKE_CROSSCOMPILING)
    # For cross-compilation, make flutter_assemble optional
    add_dependencies(${BINARY_NAME} flutter_assemble)
    # Add custom command as fallback
    add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E echo "Cross-compilation build completed"
        COMMENT "Finalizing cross-compiled build"
    )
else()
    add_dependencies(${BINARY_NAME} flutter_assemble)
endif()

# Only the install-generated bundle's copy of the executable will launch
# correctly, since the resources must in the right relative locations. To avoid
# people trying to run the unbundled copy, put it in a subdirectory instead of
# the default top-level location.
set_target_properties(${BINARY_NAME}
  PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/intermediates_do_not_run"
)


# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)


# === Installation ===
# By default, "installing" just makes a relocatable bundle in the build
# directory.
set(BUILD_BUNDLE_DIR "${PROJECT_BINARY_DIR}/bundle")
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

# Start with a clean build bundle directory every time.
install(CODE "
  file(REMOVE_RECURSE \"${BUILD_BUNDLE_DIR}/\")
  " COMPONENT Runtime)

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

foreach(bundled_library ${PLUGIN_BUNDLED_LIBRARIES})
  install(FILES "${bundled_library}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endforeach(bundled_library)

# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/linux/")
# Make native assets installation conditional
if(EXISTS "${NATIVE_ASSETS_DIR}")
  install(DIRECTORY "${NATIVE_ASSETS_DIR}"
     DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
     COMPONENT Runtime)
else()
  # Create empty native assets directory to satisfy dependencies
  install(CODE "
    file(MAKE_DIRECTORY \"${INSTALL_BUNDLE_LIB_DIR}/native_assets/linux/\")
    " COMPONENT Runtime)
endif()

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
if(NOT CMAKE_BUILD_TYPE MATCHES "Debug")
  install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()
