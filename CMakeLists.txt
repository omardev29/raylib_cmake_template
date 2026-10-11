cmake_minimum_required(VERSION 3.25)

# Everything you would want to change lives in config.cmake. This file is how
# those settings become a build, and it reads top to bottom. README.md has a map
# of every section and of what is safe to change.
include(config.cmake)
include(cmake/check_config.cmake) # a typo in config.cmake stops here, by name

option(PRODUCTION_BUILD "Optimised build that reads resources/ next to the executable" OFF)

# The presets always name a build type. Plain `cmake -B build` gets Debug rather
# than none at all, which would mean no optimisation and no debug info.
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Debug CACHE STRING "Debug or Release" FORCE)
endif()

# --- toolchain ------------------------------------------------------------------

include(cmake/dev_compiler.cmake) # DEV_COMPILER: has to come before project()
project(${GAME_NAME} LANGUAGES C CXX)
include(cmake/dev_linker.cmake)   # DEV_LINKER: has to come after it

# --- for every target -----------------------------------------------------------

# These set up every target created further down — raylib, GLFW, your game and
# any library you add — so they have to come before all of them.

# config.cmake's C and C++ standards, exactly: an error instead of a quiet
# fallback to an older one when the compiler cannot do them.
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Static libraries, linked into the executable: one file to ship.
set(BUILD_SHARED_LIBS OFF)

# MSVC: the static C runtime, so the .exe runs on a machine without the Visual
# C++ redistributable. Every other compiler ignores it.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

# build/compile_commands.json, which editors read to understand your code.
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ccache, if you have it.
find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
  set(CMAKE_C_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
  set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
endif()

# Production builds (the release and web presets): optimised as far as a binary
# can go and still run on any machine — README.md says what is on and what is
# deliberately left off. -O3 itself comes from the Release build type.
if(PRODUCTION_BUILD)
  if(EMSCRIPTEN)
    # Size first: on the web, the download is what the player waits for. So -Oz
    # rather than -O3, and full LTO rather than the ThinLTO CMake would pick
    # here, which takes twice as much off the .wasm.
    add_compile_options(-Oz -flto)
    add_link_options(-Oz -flto)
  else()
    # Link-time optimisation, checked rather than assumed: clang with the
    # system linker needs a plugin that is not always installed, and a missing
    # plugin should cost some speed, not the build.
    include(CheckIPOSupported)
    check_ipo_supported(RESULT LTO_SUPPORTED OUTPUT LTO_ERROR)
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ${LTO_SUPPORTED})
    if(NOT LTO_SUPPORTED)
      message(STATUS "No link-time optimisation here: ${LTO_ERROR}")
    endif()

    # Drop whatever nothing calls, and the symbol table nobody reads. MSVC does
    # both on its own in a release build.
    if(NOT MSVC)
      add_compile_options(-ffunction-sections -fdata-sections)
      if(APPLE)
        add_link_options(-Wl,-dead_strip)
      else()
        add_link_options(-Wl,--gc-sections -s)
      endif()
    endif()
  endif()
endif()

# --- raylib ---------------------------------------------------------------------

# The backend raylib is built on, from config.cmake. PLATFORM is raylib's own
# setting. Here it is a plain variable, not a cache entry, so it is worked out
# again on every configure and a backend you switched away from cannot linger.
# GLFW ("Desktop") is the default on every desktop.
set(PLATFORM "Desktop")
if(EMSCRIPTEN)
  set(PLATFORM "Web")
elseif(WIN32)
  if(WINDOWS_BACKEND STREQUAL "win32")
    set(PLATFORM "Win32") # needs a local patch to raylib 6.0: README.md, "Updating raylib"
  elseif(WINDOWS_BACKEND STREQUAL "rgfw")
    set(PLATFORM "RGFW")
  endif()
elseif(UNIX AND NOT APPLE) # Linux and the BSDs
  if(LINUX_BACKEND STREQUAL "rgfw")
    set(PLATFORM "RGFW")
  endif()
  # GLFW's display server: native Wayland, or X11 — which a Wayland desktop
  # then runs through XWayland.
  if(LINUX_WAYLAND)
    set(GLFW_BUILD_WAYLAND ON)
    set(GLFW_BUILD_X11 OFF)
  else()
    set(GLFW_BUILD_WAYLAND OFF)
    set(GLFW_BUILD_X11 ON)
  endif()
endif()
message(STATUS "raylib backend: ${PLATFORM}")

# SYSTEM: raylib's headers count as system headers in your code, so -Wall and
# -Wextra below stay about your code.
add_subdirectory(thirdparty/raylib SYSTEM)

# raylib's CMake tells raylib's own sources about X11 but never about Wayland,
# so its Wayland code — the HiDPI fix, GetWindowHandle() — would be left out.
if(GLFW_BUILD_WAYLAND)
  target_compile_definitions(raylib PRIVATE _GLFW_WAYLAND)
endif()

# RAYLIB_DISABLED_MODULES. Every switch in raylib 6.0's config.h sits inside an
# #ifndef, so turning a module off is one definition and nothing else.
foreach(module IN LISTS RAYLIB_DISABLED_MODULES)
  string(TOUPPER "${module}" module)
  target_compile_definitions(raylib PRIVATE "SUPPORT_MODULE_${module}=0")
endforeach()

# raylib is compiled quietly: what it warns about changes with every compiler,
# is not yours to fix, and would bury the warnings that are. -w silences
# warnings, not errors — raylib's own -Werror=... flags still stop the build.
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

# Libraries. raylib is a CMake target, so linking it brings its headers along.
# raylib-cpp is header-only, so an include path is all it takes:
# #include <raylib-cpp.hpp> when you want it. Libraries you add go here too —
# README.md, "Adding a library".
target_link_libraries(${GAME_NAME} PRIVATE raylib)
target_include_directories(${GAME_NAME} SYSTEM PRIVATE thirdparty/raylib-cpp/include)

# Your warnings. raylib's are silenced above, so whatever shows up is yours.
if(MSVC)
  target_compile_options(${GAME_NAME} PRIVATE /W4)
else()
  target_compile_options(${GAME_NAME} PRIVATE -Wall -Wextra)
endif()

# MinGW links libstdc++ and libgcc as DLLs by default, so the moment your code
# uses std::string the .exe stops starting on any machine without MSYS2.
if(MINGW)
  target_link_options(${GAME_NAME} PRIVATE -static)
endif()

# PRODUCTION_BUILD and RESOURCES_PATH, for your code. In development
# RESOURCES_PATH is absolute, so the game finds its assets whatever directory
# you start it from. In production it is relative, and resources/ travels with
# the game: copied next to the executable below, or bundled into the web build.
if(PRODUCTION_BUILD)
  target_compile_definitions(${GAME_NAME} PRIVATE
    PRODUCTION_BUILD=1 RESOURCES_PATH="./resources/")
else()
  target_compile_definitions(${GAME_NAME} PRIVATE
    PRODUCTION_BUILD=0 RESOURCES_PATH="${CMAKE_CURRENT_SOURCE_DIR}/resources/")
endif()

if(PRODUCTION_BUILD AND NOT EMSCRIPTEN)
  # Windows: no console window behind the game. CMake turns this into
  # /SUBSYSTEM:WINDOWS or -mwindows, and every other system ignores it. MSVC
  # also has to be told the entry point, so that a plain main() still works.
  set_target_properties(${GAME_NAME} PROPERTIES WIN32_EXECUTABLE ON)
  if(MSVC)
    target_link_options(${GAME_NAME} PRIVATE /ENTRY:mainCRTStartup)
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

# --- web ------------------------------------------------------------------------

if(EMSCRIPTEN)
  set_target_properties(${GAME_NAME} PROPERTIES SUFFIX ".html")
  target_link_options(${GAME_NAME} PRIVATE
    # Lets src/main.cpp keep an ordinary `while (!WindowShouldClose())` loop in
    # the browser, at a cost in download size and some speed. README.md, "The
    # web without ASYNCIFY", shows the other way — and that dropping this one
    # line is all it asks of CMake.
    -sASYNCIFY
    -sINITIAL_MEMORY=67108864
    -sALLOW_MEMORY_GROWTH=1
    # resources/ bundled into a .data file next to the .html and mounted at
    # /resources, so RESOURCES_PATH resolves in the browser as it does on disk.
    "SHELL:--preload-file \"${CMAKE_CURRENT_SOURCE_DIR}/resources@/resources/\"")

  # The bundle is made when linking, so a changed asset has to cause a relink.
  # The files cover an edit. resources.txt, their list, covers a new, deleted or
  # renamed one: `mv` keeps the old timestamp, so nothing would look newer than
  # the bundle. file(CONFIGURE) rewrites the list only when it changes.
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
