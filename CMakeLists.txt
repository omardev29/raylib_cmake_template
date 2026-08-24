cmake_minimum_required(VERSION 3.30)

<<<<<<< HEAD
# --- Project configuration --------------------------------------------------
# raylib_multiplatform.toml is the single source of truth for the project's
# identity. tools/configure.py turns it into the files below plus the Gradle
# properties and the XcodeGen spec; none of that is committed, so it cannot
# drift. This has to run before project(), because the project name comes out
# of it.
=======
# ---------------------------------------------------------------------------
# raylib_cmake_template
#
# raylib, statically linked, with a CMake build and one config file. Three
# targets, all of them built from this machine: Windows, Linux and the web.
#
# raylib.toml is the single source of truth for the project's identity.
# tools/configure.py turns it into the files under cmake/generated/ and into
# include/app_config.h; none of that is committed, so it cannot drift. It has
# to run before project(), because the project name comes out of it.
# ---------------------------------------------------------------------------

include(cmake/configure_hook.cmake)
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/generated/project.cmake")
>>>>>>> 3fec2f4 (Un template de raylib, y solo eso)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build raylib as a static library" FORCE)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "Generate compile_commands.json" FORCE)

find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
  set(CMAKE_C_COMPILER_LAUNCHER   ${CCACHE_PROGRAM})
  set(CMAKE_CXX_COMPILER_LAUNCHER ${CCACHE_PROGRAM})
endif()

option(PRODUCTION_BUILD "Optimised build that reads resources/ next to the executable" OFF)

<<<<<<< HEAD
# [dev] compiler/linker from the config. Deliberately only for development
# builds: CI builds `release`/`web`, so nothing here can change what ships.
# Must precede project(), which is where CMake locks in the compiler.
=======
# [dev] compiler and linker, and only for development builds: the release and
# web presets are unaffected by anything in that section. Must precede
# project(), which is where CMake locks the compiler in.
if(NOT PRODUCTION_BUILD)
  include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/generated/dev_toolchain.cmake" OPTIONAL)
endif()
>>>>>>> 3fec2f4 (Un template de raylib, y solo eso)

if(MSVC)
  # Static CRT in every configuration, so the .exe runs on a machine without
  # the Visual C++ redistributable.
  set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()

<<<<<<< HEAD

set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build Raylib as static libraries" FORCE)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "Generate compile_commands.json" FORCE)

project(ray_test)
=======
project(${TEMPLATE_PROJECT_NAME} LANGUAGES C CXX)
>>>>>>> 3fec2f4 (Un template de raylib, y solo eso)
add_executable("${CMAKE_PROJECT_NAME}")

# --- raylib -----------------------------------------------------------------

add_subdirectory(thirdparty/raylib)
<<<<<<< HEAD
=======

# [raylib] disabled_modules. raylib's own SUPPORT_* options are not used: they
# only take effect with CUSTOMIZE_BUILD=ON, and that flips roughly fifteen
# flags that are 0 in config.h to ON, because raylib's ParseConfigHeader.cmake
# maps any uncommented #define to ON without reading its value. The complete
# set through EXTERNAL_CONFIG_FLAGS is the only way to get what was asked for.
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/generated/raylib_flags.cmake")
>>>>>>> 3fec2f4 (Un template de raylib, y solo eso)
target_compile_definitions(raylib PRIVATE ${RAYLIB_CONFIG_DEFS})

# Disabling a module only makes the binary smaller if the linker can actually
# drop what nobody calls. Without these two, the code is compiled out of raylib
# but its dependencies are still dragged in, and `disabled_modules` saves
# nothing.
if(MSVC)
  target_link_options("${CMAKE_PROJECT_NAME}" PRIVATE /OPT:REF /OPT:ICF)
elseif(EMSCRIPTEN)
  # wasm-ld garbage-collects sections by default.
else()
  target_compile_options("${CMAKE_PROJECT_NAME}" PRIVATE -ffunction-sections -fdata-sections)
  target_compile_options(raylib PRIVATE -ffunction-sections -fdata-sections -Wno-stringop-overflow)
  if(APPLE)
    target_link_options("${CMAKE_PROJECT_NAME}" PRIVATE -Wl,-dead_strip)
  else()
    target_link_options("${CMAKE_PROJECT_NAME}" PRIVATE -Wl,--gc-sections)
  endif()
endif()

# --- your code --------------------------------------------------------------

# Every .cpp and .c under src/ is compiled. Adding a file needs no CMake edit;
# CONFIGURE_DEPENDS makes the build notice a new one on its own.
file(GLOB_RECURSE MY_SOURCES CONFIGURE_DEPENDS
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c"
)
target_sources("${CMAKE_PROJECT_NAME}" PRIVATE ${MY_SOURCES})

target_include_directories("${CMAKE_PROJECT_NAME}" PUBLIC
  "${CMAKE_CURRENT_SOURCE_DIR}/include/"
)

# RESOURCES_PATH is how your code finds resources/. In development it is an
# absolute path, so the game loads its assets whatever directory you launch it
# from; in a production build it is relative, and resources/ ships next to the
# executable.
if(PRODUCTION_BUILD)
  set(RESOURCES_PATH "./resources/")
else()
  set(RESOURCES_PATH "${CMAKE_CURRENT_SOURCE_DIR}/resources/")
endif()
target_compile_definitions("${CMAKE_PROJECT_NAME}" PUBLIC
  RESOURCES_PATH="${RESOURCES_PATH}")
message(STATUS "=== RESOURCES PATH: ${RESOURCES_PATH} ===")

<<<<<<< HEAD

set_property(TARGET "${CMAKE_PROJECT_NAME}" PROPERTY CXX_STANDARD 20)

target_sources("${CMAKE_PROJECT_NAME}" PRIVATE ${MY_SOURCES} ${RAYLIB_STUB_SOURCES})
=======
# --- optimisation, per build type -------------------------------------------
>>>>>>> 3fec2f4 (Un template de raylib, y solo eso)

if(PRODUCTION_BUILD)
  target_compile_definitions("${CMAKE_PROJECT_NAME}" PUBLIC PRODUCTION_BUILD=1)
  if(MSVC)
    # /SUBSYSTEM:WINDOWS so a released build does not open a console window
    # behind the game. mainCRTStartup keeps plain main() as the entry point.
    set_target_properties("${CMAKE_PROJECT_NAME}" PROPERTIES
      LINK_FLAGS "/SUBSYSTEM:WINDOWS /ENTRY:mainCRTStartup")
    target_compile_options("${CMAKE_PROJECT_NAME}" PRIVATE /O2 /GL)
    target_compile_options(raylib PRIVATE /O2 /GL)
    set_property(TARGET "${CMAKE_PROJECT_NAME}" PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
    set_property(TARGET raylib PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
  elseif(EMSCRIPTEN)
    # -Oz, not -O3: on the web what costs the player is the download.
    target_compile_options("${CMAKE_PROJECT_NAME}" PRIVATE -Oz)
    target_compile_options(raylib PRIVATE -Oz)
  else()
    if(MINGW)
      target_link_options("${CMAKE_PROJECT_NAME}" PRIVATE -mwindows)
    endif()
    target_compile_options("${CMAKE_PROJECT_NAME}" PRIVATE -O3)
    target_compile_options(raylib PRIVATE -O3)
    set_property(TARGET "${CMAKE_PROJECT_NAME}" PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
    set_property(TARGET raylib PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
  endif()
else()
  target_compile_definitions("${CMAKE_PROJECT_NAME}" PUBLIC PRODUCTION_BUILD=0)
  if(MSVC)
    target_compile_options("${CMAKE_PROJECT_NAME}" PRIVATE /Od /Zi)
  else()
    target_compile_options("${CMAKE_PROJECT_NAME}" PRIVATE -O0 -g)
  endif()
endif()

# --- web --------------------------------------------------------------------

<<<<<<< HEAD
target_include_directories("${CMAKE_PROJECT_NAME}" PUBLIC
  "${CMAKE_CURRENT_SOURCE_DIR}/include/"
  "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/rres"
  "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/raymob"
  "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/clay"
  "${CMAKE_CURRENT_SOURCE_DIR}/tests"
)

if(NOT DEFINED RRES_PACK_PASSWORD)
  set(RRES_PACK_PASSWORD "${TEMPLATE_RRES_PASSWORD}")
endif()
target_compile_definitions("${CMAKE_PROJECT_NAME}" PRIVATE RRES_PASSWORD="${RRES_PACK_PASSWORD}")


file(GLOB PACK_FILES LIST_DIRECTORIES false "${CMAKE_CURRENT_SOURCE_DIR}/resources/*")
set(_PACK_SUBDIRS "")
file(GLOB _RES_ENTRIES "${CMAKE_CURRENT_SOURCE_DIR}/resources/*")
foreach(_f ${_RES_ENTRIES})
  if(IS_DIRECTORY "${_f}")
    get_filename_component(_n "${_f}" NAME)
    list(APPEND _PACK_SUBDIRS "${_n}")
  endif()
endforeach()
if(_PACK_SUBDIRS AND PRODUCTION_BUILD)
  string(JOIN ", " _d ${_PACK_SUBDIRS})
  message(WARNING
    "resources/ has subfolders the pack does not reach: ${_d}\n"
    "  Resource names are flat, so nothing inside them is packed, and Linux, Windows x64 "
    "and macOS releases ship resources.rres on its own.\n"
    "  Move those files up into resources/, or ship the folder next to the executable "
    "yourself. See TECHNICAL.md, \"Resources\".")
endif()

# --- Headless UI layout test ------------------------------------------------
# Off by default: it is a developer tool, not part of a game build. The layout
# runs with the text measurement, the pointer and the viewport all injected, so
# it needs no window, no GL context and no display — which is what lets it run
# in a container.
#
#   cmake --preset debug -DBUILD_UI_TESTS=ON
#   cmake --build build --target ui_layout_test && ./build/ui_layout_test
option(BUILD_UI_TESTS "Build the headless UI layout test" OFF)
if(BUILD_UI_TESTS)
  file(GLOB UI_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/rmp/ui/*.cpp")
  add_executable(ui_layout_test "${CMAKE_CURRENT_SOURCE_DIR}/tests/ui_layout_test.cpp" ${UI_SOURCES})
  set_property(TARGET ui_layout_test PROPERTY CXX_STANDARD 20)
  target_include_directories(ui_layout_test PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/include/"
    "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/clay"
    "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/rres"
    "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/raymob"
    "${CMAKE_CURRENT_SOURCE_DIR}/tests"
  )
  # raylib is linked but never asked to open anything: MeasureTextEx and the
  # drawing calls are all behind the injected seams.
  target_compile_definitions(ui_layout_test PRIVATE RESOURCES_PATH="${RESOURCES_PATH}")
  target_link_libraries(ui_layout_test PRIVATE raylib_static)
endif()

# Remove the generated pack (e.g. to fall back to loose files in dev).
add_custom_target(unpack_resources
  COMMAND ${CMAKE_COMMAND} -E rm -f "${CMAKE_CURRENT_SOURCE_DIR}/resources/resources.rres"
  COMMENT "Removing resources.rres (back to loose files)"
)

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
else()
  set(ASM_PROD_BUILD "0")
endif()

# Include paths needed to recompile the sources standalone
set(ASM_INCLUDE_FLAGS
  "-I${CMAKE_CURRENT_SOURCE_DIR}/include"
  "-I${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/raylib/src"
  "-I${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/rres"
  "-I${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/raymob"
  "-I${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/clay"
  "-I${CMAKE_CURRENT_SOURCE_DIR}/tests"
)

# Create a header file that defines RESOURCES_PATH as a string literal (with quotes included)
# This allows proper string concatenation in C preprocessor
file(WRITE ${CMAKE_BINARY_DIR}/asm_defines.h "#pragma once
#define RESOURCES_PATH \"${RESOURCES_PATH}\"
")

# Add assembler target
# Generates the .s file for src/main.cpp
if(MSVC)
  # MSVC: wrapper batch script invoked through cmd.exe
  string(JOIN " " ASM_INCLUDES_STR ${ASM_INCLUDE_FLAGS})
  file(WRITE "${CMAKE_BINARY_DIR}/generate_asm.bat" "\
@echo off
cd /D ${CMAKE_CURRENT_SOURCE_DIR}
\"${CMAKE_CXX_COMPILER}\" -S -fverbose-asm ${ASM_OPT_FLAGS} ${ASM_INCLUDES_STR} -DPRODUCTION_BUILD=${ASM_PROD_BUILD} -include ${CMAKE_BINARY_DIR}/asm_defines.h %* -o ${CMAKE_BINARY_DIR}/main.s
")
  add_custom_target(assembler
    COMMAND cmd /C ${CMAKE_BINARY_DIR}/generate_asm.bat ${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp
    COMMENT "Generating assembler files"
    VERBATIM
  )
else()
  # GCC/Clang/MinGW: invoke the compiler directly (cmd.exe does not exist on Unix)
  add_custom_target(assembler
    COMMAND ${CMAKE_CXX_COMPILER} -S -fverbose-asm ${ASM_OPT_FLAGS} ${ASM_INCLUDE_FLAGS}
            -DPRODUCTION_BUILD=${ASM_PROD_BUILD}
            -include ${CMAKE_BINARY_DIR}/asm_defines.h
            ${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp
            -o ${CMAKE_BINARY_DIR}/main.s
    COMMENT "Generating assembler files"
    VERBATIM
  )
endif()

if(PLATFORM STREQUAL "Web")
=======
if(EMSCRIPTEN)
>>>>>>> 3fec2f4 (Un template de raylib, y solo eso)
  set_target_properties("${CMAKE_PROJECT_NAME}" PROPERTIES
    SUFFIX ".html"
    # --preload-file bundles resources/ into a .data file next to the .html, so
    # RESOURCES_PATH resolves in the browser's virtual filesystem exactly as it
    # does on disk.
    #
    # ASYNCIFY is deliberately NOT here, and that decides how you write your
    # loop: see src/main.cpp. It is what lets a `while (!WindowShouldClose())`
    # run in a browser, and it is expensive — it instruments every function
    # that could be on the stack at a suspension point, which is most of them,
    # and charges for it in size and speed whether anything suspends or not.
    LINK_FLAGS "-s USE_GLFW=3 -s TOTAL_MEMORY=67108864 -s ALLOW_MEMORY_GROWTH=1 \
--preload-file ${CMAKE_SOURCE_DIR}/resources@/resources/"
  )
endif()

target_link_libraries("${CMAKE_PROJECT_NAME}" PRIVATE raylib)
