cmake_minimum_required(VERSION 3.25)
project(ClaudeClang LANGUAGES C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(NOT CMAKE_C_COMPILER_ID MATCHES "Clang" OR CMAKE_C_COMPILER_VERSION VERSION_LESS 18)
    message(FATAL_ERROR "Clang >= 18 is required (found ${CMAKE_C_COMPILER_ID} ${CMAKE_C_COMPILER_VERSION}). "
                        "Build inside the claudeclangbuild Docker image.")
endif()

add_compile_options(-Wall -Wextra -Wpedantic -Werror)

# Production code: src/<component>/CMakeLists.txt defines the libraries.
if(EXISTS ${CMAKE_SOURCE_DIR}/src/CMakeLists.txt)
    add_subdirectory(src)
endif()

# Test suites. Each suite prefixes its CTest names so they can be run and
# measured separately:  unit.*  tdd.*  integration.*  system.*
enable_testing()
set(CLAUDECLANG_TEST_SUITES unit tdd integration system)
foreach(suite IN LISTS CLAUDECLANG_TEST_SUITES)
    if(EXISTS ${CMAKE_SOURCE_DIR}/tests/${suite}/CMakeLists.txt)
        if(NOT TARGET GTest::gtest)
            find_package(GTest REQUIRED)
            include(GoogleTest)
        endif()
        add_subdirectory(tests/${suite})
    endif()
endforeach()

# Usage in tests/<suite>/CMakeLists.txt:
#   add_executable(unit_calc calc_test.cpp)
#   target_link_libraries(unit_calc PRIVATE calc GTest::gtest_main GTest::gmock)
#   gtest_discover_tests(unit_calc TEST_PREFIX "unit.")
