##### General configurations #####

cmake_minimum_required(VERSION 3.28.4 FATAL_ERROR)

set(
    PROJECT_DESCRIPTION
    "This project implements a math library to support math studies and"
)
string(CONCAT PROJECT_DESCRIPTION "${PROJECT_DESCRIPTION}" "calculations")
project(
    "mathpp"
    DESCRIPTION "${PROJECT_DESCRIPTION}"
    VERSION 0.0.1
    LANGUAGES CXX
)

##### Default configuration options #####

# Set default compiler and linker
set(CMAKE_C_COMPILER "/usr/bin/gcc")
set(CMAKE_CXX_COMPILER "/usr/bin/g++")
set(CMAKE_LINKER "${CMAKE_C_COMPILER}")

# Verbose Makefile: Print compiler commands
set(CMAKE_VERBOSE_MAKEFILE ON)

# Set build type: Must be either Debug or Release (Default: Debug)
if (NOT DEFINED CMAKE_BUILD_TYPE OR NOT (
    CMAKE_BUILD_TYPE STREQUAL Debug
    OR CMAKE_BUILD_TYPE STREQUAL Release
))
    set(CMAKE_BUILD_TYPE Debug)
endif()

# Set output directory for binaries (Default: "${CMAKE_CURRENT_SOURCE_DIR}/bin")
if (NOT DEFINED CMAKE_RUNTIME_OUTPUT_DIRECTORY)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/bin")
endif()

# Set flag for creating shared library (Default: OFF)
if (NOT DEFINED BUILD_SHARED_LIBS)
    set(BUILD_SHARED_LIBS OFF)
endif()

# Set flag for profiling (Default: OFF)
if (NOT DEFINED PROFILING)
    set(PROFILING OFF)
endif()

# Set flag for memory sanitize check (Default: OFF)
if (NOT DEFINED SANITIZE)
    set(SANITIZE OFF)
endif()

# Set flag for creating test binary (Default: OFF)
if (NOT DEFINED TEST)
    set(TEST OFF)
endif()

# Specify the preferred usage of pthread
set(THREADS_PREFER_PTHREAD_FLAG ON)

# Display configuration settings
message(
    STATUS
    "Configuring and generating project ${CMAKE_PROJECT_NAME} with following "
    "parameters:\n\n"
    "PROJECT_DIR=${CMAKE_HOME_DIRECTORY}\n"
    "CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}\n"
    "CMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}\n"
    "BUILD_SHARED_LIBS=${BUILD_SHARED_LIBS}\n"
    "PROFILING=${PROFILING}\n"
    "SANITISE=${SANITISE}\n"
    "TEST=${TEST}\n"
    "THREADS_PREFER_PTHREAD_FLAG=${THREADS_PREFER_PTHREAD_FLAG}\n"
    "CMAKE_C_COMPILER=${CMAKE_C_COMPILER}\n"
    "CMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}\n"
    "CMAKE_LINKER=${CMAKE_LINKER}\n"
)

##### Specify compiler flags #####

list(
    APPEND COMP_FLAGS
    "-Wall"
    "-Wextra"
    "-Wno-comment"
    "-Wno-reorder"
    "-fPIC"
    "$<$<CONFIG:DEBUG>:-O0;-g;-ggdb>"
    "$<$<CONFIG:RELEASE>:-O3>"
)

if (SANATIZE)
    list(
        APPEND COMP_FLAGS
        "$<$<CONFIG:DEBUG>:-fsanitize=address;-fstack-protector-all>"
    )
endif()

if (PROFILING)
    list(
        APPEND COMP_FLAGS
        "$<$<CONFIG:DEBUG>:-pg>"
    )
endif()

message(STATUS "Compiler flags: ${COMP_FLAGS}")
add_compile_options("${COMP_FLAGS}")
 
##### Check for dependencies #####

find_package(Catch2 REQUIRED)
find_package(spdlog REQUIRED)
find_package(Threads REQUIRED)

##### Define default libraries #####

set(
    LIBRARIES
    Threads::Threads
    spdlog::spdlog
)

##### Define targets #####

set(TARGET_MATHPP "mathpp")
set(TARGET_RUN_EXAMPLE "run_example")
set(TARGET_RUN_TESTS "run_tests")

add_subdirectory(src)
add_subdirectory(tests)
