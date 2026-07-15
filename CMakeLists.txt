cmake_minimum_required(VERSION 3.25)

# 32-bit Linux build: -m32 must be injected before project() so the compiler is
# probed as 32-bit (mirrors openDAQ's OPENDAQ_FORCE_COMPILE_32BIT).
option(HELLO_FORCE_COMPILE_32BIT "Compile 32-bit on non-MSVC Linux" OFF)
if (HELLO_FORCE_COMPILE_32BIT AND CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
    foreach (lang C CXX ASM)
        set(CMAKE_${lang}_FLAGS_INIT "${CMAKE_${lang}_FLAGS_INIT} -m32" CACHE STRING "" FORCE)
    endforeach()
endif()

project(hello VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Auto-export all symbols on Windows so the SHARED core/module libs need no
# __declspec annotations; colocate runtime outputs so the test exe finds the
# core/module DLLs next to it at runtime.
set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

option(HELLO_ENABLE_TESTS "Enable testing" ${PROJECT_IS_TOP_LEVEL})

if (HELLO_ENABLE_TESTS)
    enable_testing()
endif()

# opendaq-cmake-utils: triplet detection, package naming, staging metadata.
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/StagingBootstrap.cmake")

# How the module gets hello-core:
#   OFF (dev/monolith) - build core in-tree; the module links the in-tree target.
#   ON  (build against staging) - skip core; the module find_package()s hello-core
#       from a staging on CMAKE_PREFIX_PATH (the build-once / consume path).
option(HELLO_USE_INSTALLED_CORE
       "Resolve hello-core via find_package (installed/staged) instead of building it in-tree" OFF)

if (NOT HELLO_USE_INSTALLED_CORE)
    add_subdirectory(core)
endif ()
add_subdirectory(modules/hello)

# Staging: TGZ over what was installed + staging metadata. Package name comes from
# OPENDAQ_PACKAGE_NAME_OVERRIDE (a caller cache var) > lowercase PROJECT_NAME,
# so the umbrella dev build is "hello" and the module build sets "hello-module".
opendaq_detect_triplet()
opendaq_generate_package_name(VERSION "${PROJECT_VERSION}")
opendaq_write_staging_meta(VERSION "${PROJECT_VERSION}"
                           OUTPUT "${CMAKE_BINARY_DIR}/staging-meta.json"
                           COMPONENTS core module)

set(CPACK_GENERATOR "TGZ")
set(CPACK_PACKAGE_FILE_NAME "${OPENDAQ_PACKAGE_NAME}")
set(CPACK_PACKAGE_CONTACT "noname <noname@example.com>")  # required by the DEB generator

# Per-component package names: a component-scoped package (component install turned on by
# the reusable's package preset) is named exactly OPENDAQ_PACKAGE_NAME, which the caller
# pairs with the component (override "hello-core" + component core, etc.). Without these the
# DEB generator appends a redundant "-<component>" suffix. Left unused by the monolithic dev
# umbrella (component install off there). DEB requires the name to end in ".deb".
set(CPACK_ARCHIVE_CORE_FILE_NAME    "${OPENDAQ_PACKAGE_NAME}")
set(CPACK_ARCHIVE_MODULE_FILE_NAME  "${OPENDAQ_PACKAGE_NAME}")
set(CPACK_DEBIAN_CORE_FILE_NAME     "${OPENDAQ_PACKAGE_NAME}.deb")
set(CPACK_DEBIAN_MODULE_FILE_NAME   "${OPENDAQ_PACKAGE_NAME}.deb")
include(CPack)
