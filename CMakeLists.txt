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

# opendaq-cmake-utils: triplet detection, package naming, staging sidecar.
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/StagingBootstrap.cmake")

# core and module install + export themselves; this monolithic build wires them
# in-tree (no find_package) and packages the whole tree as one umbrella staging.
add_subdirectory(core)
add_subdirectory(modules/hello)

# Umbrella staging: TGZ tarball over everything core/module installed + sidecar.
opendaq_detect_triplet()
opendaq_generate_package_name(VERSION "${PROJECT_VERSION}" NAME "hello")
opendaq_write_staging_meta(VERSION "${PROJECT_VERSION}"
                           OUTPUT "${CMAKE_BINARY_DIR}/staging-meta.json")

set(CPACK_GENERATOR "TGZ")
set(CPACK_PACKAGE_FILE_NAME "${OPENDAQ_PACKAGE_NAME}")
set(CPACK_PACKAGE_CONTACT "noname <noname@example.com>")  # required by the DEB generator
include(CPack)
