# Fetch opendaq-cmake-utils (download-only) and expose its packaging module so a
# project can call opendaq_setup_packaging() / opendaq_detect_triplet() etc.
#
# SOURCE_SUBDIR points at a non-existent dir so MakeAvailable only downloads and
# does NOT run cmake-utils' own CMakeLists (it installs mode-guarded function
# overrides we don't want); we include just the packaging module.
if (NOT COMMAND opendaq_setup_packaging)
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
endif()
