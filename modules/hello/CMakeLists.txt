# hello-module: the "module" shared library, links hello-core and adds
# print_hello(std::ostream&) on top of the core greeting.
#
# Builds two ways:
#   * as a subdirectory of the root project (hello-core is an in-tree target), or
#   * standalone as its own top-level project, resolving hello-core from an
#     installed core staging via find_package(hello-core) / CMAKE_PREFIX_PATH.
cmake_minimum_required(VERSION 3.25)
project(hello-module VERSION 1.0.0 LANGUAGES CXX)

include(GNUInstallDirs)

# In-tree (monolithic) build provides hello-core::hello-core directly; a
# standalone build resolves it from a core staging on CMAKE_PREFIX_PATH.
if (NOT TARGET hello-core::hello-core)
    find_package(hello-core REQUIRED)
endif()

add_library(hello-module SHARED src/hello_module.cpp)
add_library(hello-module::hello-module ALIAS hello-module)
target_include_directories(hello-module PUBLIC
    "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>"
    "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>")
target_link_libraries(hello-module PUBLIC hello-core::hello-core)
set_target_properties(hello-module PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
    WINDOWS_EXPORT_ALL_SYMBOLS ON)

install(TARGETS hello-module
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES src/hello_module.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

if (HELLO_ENABLE_TESTS)
    add_subdirectory(tests)
endif()

# Staging package: only when built as its own project (the root umbrella packages
# the whole tree itself).
if (PROJECT_IS_TOP_LEVEL)
    include("${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/StagingBootstrap.cmake")
    opendaq_setup_packaging(VERSION "${PROJECT_VERSION}")  # -> hello-module staging TGZ + sidecar
endif()
