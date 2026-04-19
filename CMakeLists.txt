#https://github.com/meemknight/raylibCmakeSetup
#Version 1.0.0

cmake_minimum_required(VERSION 3.30)

set(CMAKE_CXX_STANDARD 20)

# i bet you don't want modules here, but if you want, turn this on
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

#basically this will change the RESOURCES_PATH to be the local path

find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
  set(CMAKE_C_COMPILER_LAUNCHER   ${CCACHE_PROGRAM})
  set(CMAKE_CXX_COMPILER_LAUNCHER ${CCACHE_PROGRAM})
endif()

option(PRODUCTION_BUILD "Make this a production build" OFF)

if(MSVC)
  set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Release>:Release>")
  set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
  add_compile_options(/arch:AVX2) #make sure SIMD optimizations take place
endif()


set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build Raylib as static libraries" FORCE)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "Generate compile_commands.json" FORCE)

project(ray_test)
add_executable("${CMAKE_PROJECT_NAME}")



#Add raylib, and here you would add other libraries if needed!
add_subdirectory(thirdparty/raylib-5.5)
if (NOT PRODUCTION_BUILD)
  add_subdirectory(thirdparty/raymob)
endif()
# remove compile warnings to raylib
if (MSVC)
  # Ensure the linker deletes death code
  target_link_options("${CMAKE_PROJECT_NAME}" PRIVATE /OPT:REF /OPT:ICF)
  # msvc doesnt have this flag but the error doesnt occur with it
  target_compile_options(raylib PRIVATE)
elseif(EMSCRIPTEN)
  # Emscripten handles dead code elimination differently, no extra flags needed
  # wasm-ld has its own --gc-sections but it's enabled by default
elseif(APPLE)
  # Apple ld64 uses -dead_strip instead of --gc-sections
  target_link_options("${CMAKE_PROJECT_NAME}" PRIVATE -Wl,-dead_strip)
  target_compile_options("${CMAKE_PROJECT_NAME}" PRIVATE -ffunction-sections -fdata-sections)
  target_compile_options(raylib PRIVATE -ffunction-sections -fdata-sections -Wno-stringop-overflow)
else()
  # GNU ld (Linux, MinGW)
  target_link_options("${CMAKE_PROJECT_NAME}" PRIVATE -Wl,--gc-sections)
  target_compile_options("${CMAKE_PROJECT_NAME}" PRIVATE -ffunction-sections -fdata-sections)
  target_compile_options(raylib PRIVATE -ffunction-sections -fdata-sections -Wno-stringop-overflow)
endif()

# MY_SOURCES is defined to be a list of all the source files for my game
# DON'T ADD THE SOURCES BY HAND, they are already added with this macro
file(GLOB_RECURSE MY_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp")

set(RESOURCES_PATH "../resources/")
target_compile_definitions("${CMAKE_PROJECT_NAME}" PUBLIC RESOURCES_PATH="./resources/")


set_property(TARGET "${CMAKE_PROJECT_NAME}" PROPERTY CXX_STANDARD 20)

target_sources("${CMAKE_PROJECT_NAME}" PRIVATE ${MY_SOURCES} )

if(PRODUCTION_BUILD)
  # setup the ASSETS_PATH macro to be in the root folder of your exe
  # remove the option to debug asserts.
  target_compile_definitions("${CMAKE_PROJECT_NAME}" PUBLIC PRODUCTION_BUILD=1)
  if(MSVC)
    set_target_properties("${CMAKE_PROJECT_NAME}" PROPERTIES
            LINK_FLAGS "/SUBSYSTEM:WINDOWS /ENTRY:mainCRTStartup")
    target_compile_options("${CMAKE_PROJECT_NAME}" PRIVATE /O2 /GL)
    target_compile_options(raylib PRIVATE /O2 /GL)
    set_property(TARGET "${CMAKE_PROJECT_NAME}" PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
    set_property(TARGET raylib PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
    message("===INITIALIZING PRODUCTION BUILD WITH MSVC===")
  elseif(EMSCRIPTEN)
    # Emscripten/WebAssembly - skip LTO, use -Oz for size optimization
    target_compile_options("${CMAKE_PROJECT_NAME}" PRIVATE -Oz)
    target_compile_options(raylib PRIVATE -Oz)
    message("===INITIALIZING PRODUCTION BUILD WITH EMSCRIPTEN===")
  else() # Linux, macOS, MinGW
    if (MINGW)
      target_link_options("${CMAKE_PROJECT_NAME}" PRIVATE -mwindows)
    endif()
    target_compile_options("${CMAKE_PROJECT_NAME}" PRIVATE -O3)
    target_compile_options(raylib PRIVATE -O3)
    set_property(TARGET "${CMAKE_PROJECT_NAME}" PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
    set_property(TARGET raylib PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
    message("===INITIALIZING PRODUCTION BUILD WITH GCC OR CLANG===")
  endif()
  # There´s no console to quit on Linux/MacOS
else()
  target_compile_definitions("${CMAKE_PROJECT_NAME}" PUBLIC PRODUCTION_BUILD=0)
  if (MSVC)
    target_compile_options("${CMAKE_PROJECT_NAME}" PRIVATE /Od /Zi)
    message("===INITIALIZING DEBUGGING WITH MSVC===")
  else()
    target_compile_options("${CMAKE_PROJECT_NAME}" PRIVATE -O0)

    message("===INITIALIZING DEBUGGING WITH GCC OR CLANG===")
  endif()
endif()

message(STATUS "=== RESOURCES PATH: ${RESOURCES_PATH} ===")

target_include_directories("${CMAKE_PROJECT_NAME}" PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include/")

# if you want to see the assembler
# This target generates .s (assembler) files for all sources in the project
# Compatible with GCC/Clang/MinGW and MSVC

# Determine optimization flag based on build type
if(PRODUCTION_BUILD)
  set(ASM_OPT_FLAGS "-O3")
else()
  set(ASM_OPT_FLAGS "-O0")
endif()

# Create defines based on build type (same as the main target)
if(PRODUCTION_BUILD)
  set(ASM_PROD_BUILD "1")
  set(ASM_RESOURCES_PATH "../resources/")
else()
  set(ASM_PROD_BUILD "0")
  set(ASM_RESOURCES_PATH "${CMAKE_CURRENT_SOURCE_DIR}/resources/")
endif()

# Build include paths as a single string
set(ASM_INCLUDES_STR "")
foreach(inc "${CMAKE_CURRENT_SOURCE_DIR}/include" "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/raylib-5.5/src" "${CMAKE_CURRENT_BINARY_DIR}/thirdparty/raylib-5.5/include")
  set(ASM_INCLUDES_STR "${ASM_INCLUDES_STR} -I${inc}")
endforeach()

# Create a header file that defines RESOURCES_PATH as a string literal (with quotes included)
# This allows proper string concatenation in C preprocessor
file(WRITE ${CMAKE_BINARY_DIR}/asm_defines.h "#pragma once
#define RESOURCES_PATH \"../resources/\"
")

# Create a wrapper script that generates assembler using the defines header
file(WRITE ${CMAKE_BINARY_DIR}/generate_asm.bat"
@echo off
cd /D ${CMAKE_CURRENT_SOURCE_DIR}
\"${CMAKE_CXX_COMPILER}\" -S -fverbose-asm ${ASM_OPT_FLAGS}${ASM_INCLUDES_STR} -DPRODUCTION_BUILD=${ASM_PROD_BUILD} -include ${CMAKE_BINARY_DIR}/asm_defines.h %* -o ${CMAKE_BINARY_DIR}/main.s
")

# Add assembler target
# Generates .s files for each source in the project
if(MSVC)
  # MSVC: generate .asm files
  add_custom_target(assembler
    COMMAND cmd /C ${CMAKE_BINARY_DIR}/generate_asm.bat ${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp
    DEPENDS ${CMAKE_PROJECT_NAME}
    COMMENT "Generating assembler files"
    VERBATIM
  )
else()
  # GCC/Clang/MinGW: generate .s files
  # Use wrapper script to set RESOURCES_PATH in environment before compilation
  add_custom_target(assembler
    COMMAND cmd /C ${CMAKE_BINARY_DIR}/generate_asm.bat ${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp
    DEPENDS ${CMAKE_PROJECT_NAME}
    COMMENT "Generating assembler files"
    VERBATIM
  )
endif()

if(${PLATFORM} STREQUAL "Web")
  set_target_properties("${CMAKE_PROJECT_NAME}" PROPERTIES
        SUFFIX ".html"
        LINK_FLAGS "-s USE_GLFW=3 -s ASYNCIFY -s TOTAL_MEMORY=67108864 --preload-file ${CMAKE_SOURCE_DIR}/resources@/resources/"
    )
endif()


# Link raylib library statically, Here you would add other libraries!
if (PRODUCTION_BUILD)

  target_link_libraries("${CMAKE_PROJECT_NAME}" PRIVATE
 raylib_static

)
else()

  target_link_libraries("${CMAKE_PROJECT_NAME}" PRIVATE
 raylib_static
 raymoblib
)
endif()
