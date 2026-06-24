# hello-core: the "core" shared library, exposes hello().
#
# Builds two ways:
#   * as a subdirectory of the root project (monolithic build), or
#   * standalone as its own top-level project, producing a core staging that a
#     module build consumes via find_package(hello-core) / CMAKE_PREFIX_PATH.
cmake_minimum_required(VERSION 3.25)
project(hello-core VERSION 1.0.0 LANGUAGES CXX)

include(GNUInstallDirs)

add_library(hello-core SHARED src/hello.cpp)
add_library(hello-core::hello-core ALIAS hello-core)
target_include_directories(hello-core PUBLIC
    "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>"
    "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>")
set_target_properties(hello-core PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
    WINDOWS_EXPORT_ALL_SYMBOLS ON)

# Install + export a CMake package config so dependents can find_package(hello-core).
# Everything is tagged COMPONENT core so a staging build can scope the tarball to it.
install(TARGETS hello-core EXPORT hello-core-targets
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT core
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT core
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT core)
install(FILES src/hello.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} COMPONENT core)
install(EXPORT hello-core-targets
        FILE hello-core-targets.cmake
        NAMESPACE hello-core::
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/hello-core
        COMPONENT core)

include(CMakePackageConfigHelpers)
configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/hello-core-config.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/hello-core-config.cmake"
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/hello-core)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/hello-core-config-version.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion)
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/hello-core-config.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/hello-core-config-version.cmake"
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/hello-core
    COMPONENT core)

# Staging package: only when built as its own project (the root umbrella packages
# the whole tree itself).
if (PROJECT_IS_TOP_LEVEL)
    include("${CMAKE_CURRENT_SOURCE_DIR}/../cmake/StagingBootstrap.cmake")
    opendaq_setup_packaging(VERSION "${PROJECT_VERSION}")  # -> hello-core staging TGZ + metadata
endif()
