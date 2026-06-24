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

option(HELLO_ENABLE_TESTS "Enable testing" ${PROJECT_IS_TOP_LEVEL})

if (HELLO_ENABLE_TESTS)
    enable_testing()
endif()

# opendaq-cmake-utils: triplet detection, package naming, staging sidecar.
# SOURCE_SUBDIR points at a non-existent dir so MakeAvailable only downloads and
# does NOT run cmake-utils' own CMakeLists (it installs mode-guarded function
# overrides we don't want); we include just the packaging module.
include(FetchContent)
FetchContent_Declare(
    opendaq-cmake-utils
    GIT_REPOSITORY https://github.com/openDAQ/opendaq-cmake-utils.git
    GIT_TAG        ci/staging
    SOURCE_SUBDIR  _download_only_
)
FetchContent_MakeAvailable(opendaq-cmake-utils)
list(APPEND CMAKE_MODULE_PATH "${opendaq-cmake-utils_SOURCE_DIR}/cmake")
include(openDAQPackagingUtils)

add_subdirectory(modules/hello)

# Packaging: TGZ tarball + staging-meta.json sidecar
install(TARGETS hello
        ARCHIVE DESTINATION lib
        LIBRARY DESTINATION lib
        RUNTIME DESTINATION bin)
install(FILES modules/hello/src/hello.h DESTINATION include)

opendaq_detect_triplet()
opendaq_generate_package_name(VERSION "${PROJECT_VERSION}" NAME "hello")
opendaq_write_staging_meta(VERSION "${PROJECT_VERSION}"
                           OUTPUT "${CMAKE_BINARY_DIR}/staging-meta.json")

set(CPACK_GENERATOR "TGZ")
set(CPACK_PACKAGE_FILE_NAME "${OPENDAQ_PACKAGE_NAME}")
set(CPACK_PACKAGE_CONTACT "noname <noname@example.com>")  # required by the DEB generator
include(CPack)
