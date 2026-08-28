# Fetch opendaq-cmake-utils (download-only) and expose its packaging module so a
# project can call opendaq_detect_settings() / opendaq_compose_package_file_name() etc.
#
# SOURCE_SUBDIR points at a non-existent dir so MakeAvailable only downloads and
# does NOT run cmake-utils' own CMakeLists (it installs mode-guarded function
# overrides we don't want); we include just the packaging module.
if (NOT COMMAND opendaq_write_metadata)
    include(FetchContent)
    FetchContent_Declare(
        opendaq-cmake-utils
        GIT_REPOSITORY https://github.com/openDAQ/opendaq-cmake-utils.git
        GIT_TAG        v1.0.3
        SOURCE_SUBDIR  _download_only_
    )
    FetchContent_MakeAvailable(opendaq-cmake-utils)
    list(APPEND CMAKE_MODULE_PATH "${opendaq-cmake-utils_SOURCE_DIR}/cmake")
    include(openDAQPackagingUtils)
endif()
