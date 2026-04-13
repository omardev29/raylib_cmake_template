# For more information about using CMake with Android Studio, read the
# documentation: https://d.android.com/studio/projects/add-native-code.html

cmake_minimum_required(VERSION 3.22.1)

set(CMAKE_C_STANDARD 99)
set(CMAKE_CXX_STANDARD 20)

project("${APP_LIB_NAME}")

# Define absolute paths to the raylib_cmake_template root directory
# CMAKE_CURRENT_SOURCE_DIR is raymob/app/src/main/cpp
get_filename_component(USER_ROOT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../" ABSOLUTE)
set(USER_SRC_DIR "${USER_ROOT_DIR}/src/")
set(USER_INCLUDE_DIR "${USER_ROOT_DIR}/include/")
set(USER_RESOURCES_DIR "${USER_ROOT_DIR}/resources/")
set(RAYLIB_DIR "${USER_ROOT_DIR}/thirdparty/raylib-5.5")
set(RAYMOB_DIR "${USER_ROOT_DIR}/thirdparty/raymob")

# Include raylib and raymob as subdirectories (using absolute paths)
add_subdirectory(${RAYLIB_DIR} "${CMAKE_BINARY_DIR}/raylib-5.5")
add_subdirectory(${RAYMOB_DIR} "${CMAKE_BINARY_DIR}/raymob")

# Fetch all source files from the user's src/ directory (recursively)
file(GLOB_RECURSE SOURCES 
    "${USER_SRC_DIR}/*.c" 
    "${USER_SRC_DIR}/*.cpp"
)

# Create a shared library with game source files
add_library(${APP_LIB_NAME} SHARED ${SOURCES})

# Define compiler macros for the library
target_compile_definitions(${APP_LIB_NAME} PRIVATE 
    PLATFORM_ANDROID
)

if(CMAKE_BUILD_TYPE MATCHES "Debug")
    target_compile_definitions(${APP_LIB_NAME} PRIVATE _DEBUG DEBUG)
endif()

# Include directories
target_include_directories(${APP_LIB_NAME} PRIVATE 
    "${USER_INCLUDE_DIR}"
    "${RAYLIB_DIR}/src"
    "${RAYMOB_DIR}"
)

# Link required libraries to the native application
target_link_libraries(${APP_LIB_NAME} raylib raymoblib)
