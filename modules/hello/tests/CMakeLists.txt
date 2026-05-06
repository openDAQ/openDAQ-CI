include(FetchContent)

FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG v1.14.0
)
FetchContent_MakeAvailable(googletest)

# Suppress -Wcharacter-conversion in gtest headers (Clang 18+, Intel oneAPI)
foreach(_t gtest gtest_main gmock gmock_main)
    if (TARGET ${_t})
        target_compile_options(${_t} PUBLIC
            $<$<CXX_COMPILER_ID:Clang,IntelLLVM>:-Wno-character-conversion>)
    endif()
endforeach()

add_executable(test_hello test_hello.cpp)
target_link_libraries(test_hello PRIVATE hello gtest gtest_main)

add_test(NAME test_hello COMMAND test_hello)
