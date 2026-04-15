add_library(hello src/hello.cpp)
target_include_directories(hello PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/src)

if (HELLO_ENABLE_TESTS)
    add_subdirectory(tests)
endif()
