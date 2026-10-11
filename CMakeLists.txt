cmake_minimum_required(VERSION 3.25)

# Everything you would want to change lives in config.cmake: the game's name,
# which raylib modules to build, the window backend, your local compiler and
# linker. This file is how those settings become a build, and it reads top to
# bottom.
include(config.cmake)

option(PRODUCTION_BUILD "Optimised build that reads resources/ next to the executable" OFF)

# The presets always name a build type. Plain `cmake -B build` would get none —
# no optimisation and no debug info — so it gets Debug.
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Debug CACHE STRING "Debug or Release" FORCE)
endif()

# --- check config.cmake ---------------------------------------------------------

# A typo in config.cmake stops here, with a message that names the setting,
# instead of surfacing later as a raylib or linker error that never mentions it.
function(expect_one_of setting)
  if(NOT "${${setting}}" IN_LIST ARGN)
    list(JOIN ARGN " | " choices)
    message(FATAL_ERROR "config.cmake: ${setting} is \"${${setting}}\"; it has to be one of: ${choices}")
  endif()
endfunction()

if(NOT "${GAME_NAME}" MATCHES "^[A-Za-z0-9_-]+$")
  message(FATAL_ERROR
    "config.cmake: GAME_NAME \"${GAME_NAME}\" becomes a file name on every system. "
    "Use letters, digits, _ and - only.")
endif()
# To CMake, "raudio rmodels" in quotes is one string, not two modules. Both that
# and the list form (raudio rmodels, unquoted) mean what you meant.
string(REGEX MATCHALL "[^ \t\r\n;]+" RAYLIB_DISABLED_MODULES "${RAYLIB_DISABLED_MODULES}")
foreach(module IN LISTS RAYLIB_DISABLED_MODULES)
  if(NOT "${module}" MATCHES "^(rshapes|rtextures|rtext|rmodels|raudio)$")
    message(FATAL_ERROR
      "config.cmake: RAYLIB_DISABLED_MODULES has \"${module}\". Pick from rshapes "
      "rtextures rtext rmodels raudio — rcore and rlgl are mandatory.")
  endif()
endforeach()
# raylib's own dependency, which its config.h only mentions in a comment: rtext
# builds its fonts with rtextures. Without this, the link fails on functions
# like GenImageColor that your code never called.
if("rtextures" IN_LIST RAYLIB_DISABLED_MODULES AND NOT "rtext" IN_LIST RAYLIB_DISABLED_MODULES)
  message(FATAL_ERROR
    "config.cmake: rtext needs rtextures, so disabling rtextures means disabling "
    "rtext too. Add rtext to RAYLIB_DISABLED_MODULES, or keep rtextures.")
endif()
expect_one_of(WINDOWS_BACKEND glfw win32 rgfw)
expect_one_of(LINUX_BACKEND glfw rgfw)
expect_one_of(LINUX_WAYLAND ON OFF)
expect_one_of(DEV_COMPILER default clang gcc mingw msvc)
expect_one_of(DEV_LINKER auto mold lld default)

# Each valid on its own, together a contradiction: RGFW on Linux is X11-only, so
# the build would quietly produce X11 while config.cmake said Wayland.
if(LINUX_BACKEND STREQUAL "rgfw" AND LINUX_WAYLAND)
  message(FATAL_ERROR
    "config.cmake: LINUX_BACKEND rgfw is X11-only, so it cannot be combined with "
    "LINUX_WAYLAND ON. Use glfw for native Wayland, or set LINUX_WAYLAND OFF.")
endif()

# --- the toolchain --------------------------------------------------------------

include(cmake/dev_compiler.cmake) # DEV_COMPILER: has to come before project()
project(${GAME_NAME} LANGUAGES C CXX)
include(cmake/dev_linker.cmake)   # DEV_LINKER: has to come after it

# --- for every target -----------------------------------------------------------

# These initialise properties of the targets created below, so they have to be
# set before add_subdirectory() and add_executable().

# raylib as a static library, linked into your executable: one file to ship.
set(BUILD_SHARED_LIBS OFF)

# MSVC: the static C runtime in every configuration, so the .exe runs on a
# machine without the Visual C++ redistributable. Every other compiler ignores
# it.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

# build/compile_commands.json, for clangd and clang-tidy.
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ccache, if you have it.
find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
  set(CMAKE_C_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
  set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
endif()

# --- raylib ---------------------------------------------------------------------

# Which backend raylib is built on. PLATFORM is raylib's own setting; here it is
# a plain variable, not a cache entry, so it is worked out again from
# config.cmake on every configure and a backend you switched away from cannot
# linger in the cache. GLFW ("Desktop") is the default everywhere.
set(PLATFORM "Desktop")
if(EMSCRIPTEN)
  set(PLATFORM "Web")
elseif(WIN32 AND WINDOWS_BACKEND STREQUAL "win32")
  # raylib 6.0 ships the native Win32 backend but no CMake switch for it. The
  # switch is a local patch to thirdparty/raylib (CMakeOptions.txt and
  # cmake/LibraryConfigurations.cmake), commented there. GLFW drops out on its
  # own: it is only built when PLATFORM is "Desktop".
  set(PLATFORM "Win32")
elseif(WIN32 AND WINDOWS_BACKEND STREQUAL "rgfw")
  set(PLATFORM "RGFW")
elseif(UNIX AND NOT APPLE AND LINUX_BACKEND STREQUAL "rgfw")
  set(PLATFORM "RGFW")
endif()
message(STATUS "raylib backend: ${PLATFORM}")

# Linux with GLFW: X11 or native Wayland, from LINUX_WAYLAND.
set(_wayland OFF)
if(PLATFORM STREQUAL "Desktop" AND UNIX AND NOT APPLE)
  set(_wayland ${LINUX_WAYLAND})
  if(_wayland)
    set(GLFW_BUILD_WAYLAND ON)
    set(GLFW_BUILD_X11 OFF)
  else()
    set(GLFW_BUILD_WAYLAND OFF)
    set(GLFW_BUILD_X11 ON)
  endif()
endif()

# SYSTEM: raylib's headers count as system headers in your code, so your
# warnings and clang-tidy stay about your code.
add_subdirectory(thirdparty/raylib SYSTEM)

# raylib's CMake tells raylib's own sources about X11 (_GLFW_X11) but never
# about Wayland, so with Wayland on, raylib's Wayland code — the HiDPI scaling
# fix, GetWindowHandle() — would be compiled out.
if(_wayland)
  target_compile_definitions(raylib PRIVATE _GLFW_WAYLAND)
endif()

# RAYLIB_DISABLED_MODULES. Every switch in raylib 6.0's config.h sits inside an
# #ifndef, so turning a module off is one definition and nothing else.
foreach(module IN LISTS RAYLIB_DISABLED_MODULES)
  string(TOUPPER "${module}" module)
  target_compile_definitions(raylib PRIVATE "SUPPORT_MODULE_${module}=0")
endforeach()
if(RAYLIB_DISABLED_MODULES)
  message(STATUS "raylib modules disabled: ${RAYLIB_DISABLED_MODULES}")
endif()

# raylib is compiled quietly. Its code is not yours to fix, and what it warns
# about changes with every compiler: an ignored return value under GCC's -O3,
# miniaudio's deprecated Emscripten macros, a pointer comparison in stb_vorbis
# that is tautological on some targets. Silenced, none of it can bury the
# warnings that ARE yours. -w silences warnings, not errors: raylib's own
# -Werror=... flags still stop the build.
if(MSVC)
  target_compile_options(raylib PRIVATE /w)
else()
  target_compile_options(raylib PRIVATE -w)
endif()

# --- your game ------------------------------------------------------------------

add_executable(${GAME_NAME})

# Every .cpp and .c under src/ is compiled. Adding a file needs no CMake edit:
# CONFIGURE_DEPENDS makes the build notice a new one on its own.
file(GLOB_RECURSE GAME_SOURCES CONFIGURE_DEPENDS src/*.cpp src/*.c)
target_sources(${GAME_NAME} PRIVATE ${GAME_SOURCES})
target_include_directories(${GAME_NAME} PRIVATE include)
target_compile_features(${GAME_NAME} PRIVATE cxx_std_20)

target_link_libraries(${GAME_NAME} PRIVATE raylib)

# raylib-cpp, the optional C++ wrapper. It is header-only, so an include path
# is all it takes: #include <raylib-cpp.hpp> when you want it, plain raylib
# otherwise.
target_include_directories(${GAME_NAME} SYSTEM PRIVATE thirdparty/raylib-cpp/include)

# Your warnings. raylib's are silenced above, so whatever shows up is yours.
if(MSVC)
  target_compile_options(${GAME_NAME} PRIVATE /W4)
else()
  target_compile_options(${GAME_NAME} PRIVATE -Wall -Wextra)
endif()

# MinGW links libstdc++ and libgcc as DLLs by default, so the moment your code
# uses std::string the .exe stops starting on any machine without MSYS2.
# -static puts them inside it.
if(MINGW)
  target_link_options(${GAME_NAME} PRIVATE -static)
endif()

# RESOURCES_PATH is how your code finds resources/. In development it is an
# absolute path, so the game loads its assets whatever directory you launch it
# from. In a production build it is relative, and resources/ travels with the
# game: copied next to the executable, or bundled into the web build.
if(PRODUCTION_BUILD)
  set(RESOURCES_PATH "./resources/")
else()
  set(RESOURCES_PATH "${CMAKE_CURRENT_SOURCE_DIR}/resources/")
endif()
target_compile_definitions(${GAME_NAME} PRIVATE RESOURCES_PATH="${RESOURCES_PATH}")

# --- production builds: the release and web presets ----------------------------

if(PRODUCTION_BUILD)
  target_compile_definitions(${GAME_NAME} PRIVATE PRODUCTION_BUILD=1)

  # Windows: no console window behind the game. CMake turns this into
  # /SUBSYSTEM:WINDOWS or -mwindows, and every other system ignores it. MSVC
  # also has to be told the entry point, so that a plain main() still works.
  set_target_properties(${GAME_NAME} PROPERTIES WIN32_EXECUTABLE ON)
  if(MSVC)
    target_link_options(${GAME_NAME} PRIVATE /ENTRY:mainCRTStartup)
  endif()

  if(EMSCRIPTEN)
    # -Oz, not -O3: on the web what costs the player is the download. For
    # linking too, because that is where wasm-opt runs.
    target_compile_options(${GAME_NAME} PRIVATE -Oz)
    target_compile_options(raylib PRIVATE -Oz)
    target_link_options(${GAME_NAME} PRIVATE -Oz)
  else()
    # Link-time optimisation, checked rather than assumed: clang with the system
    # linker needs a plugin that is not always installed, and a missing plugin
    # should cost some speed, not the build.
    include(CheckIPOSupported)
    check_ipo_supported(RESULT LTO_SUPPORTED OUTPUT LTO_ERROR LANGUAGES C CXX)
    if(LTO_SUPPORTED)
      set_property(TARGET ${GAME_NAME} raylib PROPERTY INTERPROCEDURAL_OPTIMIZATION ON)
    else()
      message(STATUS "No link-time optimisation here: ${LTO_ERROR}")
    endif()

    # Let the linker drop whatever nothing calls. MSVC does it on its own in a
    # release build.
    if(NOT MSVC)
      target_compile_options(${GAME_NAME} PRIVATE -ffunction-sections -fdata-sections)
      target_compile_options(raylib PRIVATE -ffunction-sections -fdata-sections)
      if(APPLE)
        target_link_options(${GAME_NAME} PRIVATE -Wl,-dead_strip)
      else()
        target_link_options(${GAME_NAME} PRIVATE -Wl,--gc-sections)
      endif()
    endif()

    # resources/ next to the executable, where "./resources/" finds it when the
    # game is started from its own folder — a double click does exactly that.
    # The folder that holds the executable is the folder you ship. Copied on
    # every build, so an edited asset is never stale.
    add_custom_target(copy_resources ALL
      COMMAND "${CMAKE_COMMAND}" -E copy_directory
              "${CMAKE_CURRENT_SOURCE_DIR}/resources"
              "$<TARGET_FILE_DIR:${GAME_NAME}>/resources")
    add_dependencies(${GAME_NAME} copy_resources)
  endif()
else()
  target_compile_definitions(${GAME_NAME} PRIVATE PRODUCTION_BUILD=0)
endif()

# --- web ------------------------------------------------------------------------

if(EMSCRIPTEN)
  set_target_properties(${GAME_NAME} PROPERTIES SUFFIX ".html")

  # -sASYNCIFY is what lets src/main.cpp keep an ordinary
  # `while (!WindowShouldClose())` loop in a browser, with no #if anywhere in
  # your code. That matters here: this template's whole point is that you write
  # plain raylib, and a platform fork in main() is the first crack in that.
  #
  # It is not free. A browser cannot be blocked, so the loop has to yield —
  # raylib's WindowShouldClose() does it with emscripten_sleep(). ASYNCIFY makes
  # a sleep inside an ordinary function possible by instrumenting every function
  # that could be on the stack when it happens, which is most of them, and you
  # pay in download size and a little speed whether or not anything suspends.
  # The alternative is emscripten_set_main_loop() plus an #if in main(), which
  # is what raylib_multiplatform does: it ships to fourteen targets and the
  # download matters there. Here, staying plain matters more.
  #
  # --preload-file bundles resources/ into a .data file next to the .html,
  # mounted at /resources, so RESOURCES_PATH resolves in the browser exactly as
  # it does on disk.
  target_link_options(${GAME_NAME} PRIVATE
    -sASYNCIFY
    -sINITIAL_MEMORY=67108864
    -sALLOW_MEMORY_GROWTH=1
    "SHELL:--preload-file \"${CMAKE_CURRENT_SOURCE_DIR}/resources@/resources/\"")

  # The bundle is made when linking, so a changed asset has to cause a relink.
  # The files themselves cover an edit. resources.txt, the list of them,
  # covers a new, deleted or renamed one: `mv` keeps a file's old timestamp, so
  # nothing would look newer than the bundle. file(CONFIGURE) only rewrites the
  # list when it changed.
  file(GLOB_RECURSE RESOURCE_FILES CONFIGURE_DEPENDS resources/*)
  file(CONFIGURE OUTPUT resources.txt CONTENT "${RESOURCE_FILES}" @ONLY)
  set_property(TARGET ${GAME_NAME} APPEND PROPERTY LINK_DEPENDS
    ${RESOURCE_FILES} "${CMAKE_CURRENT_BINARY_DIR}/resources.txt")
endif()

# --- run ------------------------------------------------------------------------

# cmake --build --preset debug --target run
# builds whatever changed, then starts the game. On the web it serves the page
# with emrun, which comes with the emsdk, and opens your browser.
if(EMSCRIPTEN)
  add_custom_target(run COMMAND emrun "$<TARGET_FILE:${GAME_NAME}>" USES_TERMINAL)
  add_dependencies(run ${GAME_NAME})
else()
  add_custom_target(run COMMAND ${GAME_NAME}
    WORKING_DIRECTORY "$<TARGET_FILE_DIR:${GAME_NAME}>" USES_TERMINAL)
endif()
