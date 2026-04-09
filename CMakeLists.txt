cmake_minimum_required(VERSION 3.25)
project(hello VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

option(HELLO_ENABLE_TESTS "Enable testing" ${PROJECT_IS_TOP_LEVEL})

if (HELLO_ENABLE_TESTS)
    enable_testing()
endif()

add_subdirectory(modules/hello)
