cmake_minimum_required(VERSION 3.30)

include(cmake/configure_hook.cmake)
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/generated/project.cmake")

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

# [dev] compiler and linker, and only for development builds: the release and
# web presets are unaffected by anything in that section. Must precede
# project(), which is where CMake locks the compiler in.
if(NOT PRODUCTION_BUILD)
  include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/generated/dev_toolchain.cmake" OPTIONAL)
endif()

if(MSVC)
  # Static CRT in every configuration, so the .exe runs on a machine without
  # the Visual C++ redistributable.
  set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()

project(${TEMPLATE_PROJECT_NAME} LANGUAGES C CXX)
add_executable("${CMAKE_PROJECT_NAME}")

# --- raylib -----------------------------------------------------------------

# Which backend raylib is built against. Everything not named here is raylib's
# own default: Desktop/GLFW on the desktops, Web under Emscripten.
if(WIN32 AND TEMPLATE_WINDOWS_BACKEND STREQUAL "win32")
  # raylib 6.0 ships a native Win32 backend but never added a CMake branch for
  # it. That branch lives in thirdparty/raylib/cmake/LibraryConfigurations.cmake
  # as a local patch — see the comment there. GLFW drops out on its own,
  # because it is only built when PLATFORM matches "Desktop".
  set(PLATFORM "Win32" CACHE STRING "" FORCE)
  message(STATUS "=== WINDOWS BACKEND: native Win32, no GLFW ===")
elseif(WIN32 AND TEMPLATE_WINDOWS_BACKEND STREQUAL "rgfw")
  set(PLATFORM "RGFW" CACHE STRING "" FORCE)
  message(STATUS "=== WINDOWS BACKEND: RGFW ===")
elseif(UNIX AND NOT APPLE AND NOT EMSCRIPTEN AND TEMPLATE_LINUX_BACKEND STREQUAL "rgfw")
  set(PLATFORM "RGFW" CACHE STRING "" FORCE)
  message(STATUS "=== LINUX BACKEND: RGFW ===")
endif()

# [linux] wayland. By default GLFW is built against X11, so on a Wayland desktop
# the game runs through XWayland — an extra hop, and the reason fractional
# scaling and per-monitor DPI misbehave there. Turning it on builds GLFW's
# native Wayland backend, which needs libwayland-dev, wayland-protocols and
# libxkbcommon-dev.
#
# One difference you WILL see, and it is Wayland's design: there is no window
# position. GetWindowPosition() and SetWindowPosition() do not work.
if(UNIX AND NOT APPLE AND NOT EMSCRIPTEN AND NOT PLATFORM STREQUAL "RGFW")
  if(TEMPLATE_LINUX_WAYLAND)
    set(GLFW_BUILD_WAYLAND ON  CACHE BOOL "" FORCE)
    set(GLFW_BUILD_X11     OFF CACHE BOOL "" FORCE)
    message(STATUS "=== LINUX: native Wayland (no X11, no XWayland) ===")
  else()
    set(GLFW_BUILD_WAYLAND OFF CACHE BOOL "" FORCE)
    set(GLFW_BUILD_X11     ON  CACHE BOOL "" FORCE)
  endif()
endif()

add_subdirectory(thirdparty/raylib)

# [raylib] disabled_modules. raylib's own SUPPORT_* options are not used: they
# only take effect with CUSTOMIZE_BUILD=ON, and that flips roughly fifteen
# flags that are 0 in config.h to ON, because raylib's ParseConfigHeader.cmake
# maps any uncommented #define to ON without reading its value. The complete
# set through EXTERNAL_CONFIG_FLAGS is the only way to get what was asked for.
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/generated/raylib_flags.cmake")
target_compile_definitions(raylib PRIVATE ${RAYLIB_CONFIG_DEFS})

# Disabling a module only makes the binary smaller if the linker can drop what
# nobody calls. Without these two the code is compiled out of raylib but its
# dependencies are still dragged in, and disabled_modules saves nothing.
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

# --- optimisation, per build type -------------------------------------------

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

if(EMSCRIPTEN)
  set_target_properties("${CMAKE_PROJECT_NAME}" PROPERTIES
    SUFFIX ".html"
    # -sASYNCIFY is what lets src/main.cpp keep an ordinary
    # `while (!WindowShouldClose())` loop in a browser, with no #if anywhere in
    # your code. That matters here: this template's whole point is that you
    # write plain raylib, and a platform fork in main() is the first crack in
    # that promise.
    #
    # It is not free, and the trade is worth knowing. A browser cannot be
    # blocked, so the loop has to yield — raylib's WindowShouldClose() does it
    # with emscripten_sleep(). ASYNCIFY makes a sleep inside an ordinary
    # function possible by instrumenting every function that could be on the
    # stack when it happens, which is most of them, and you pay in download
    # size and a little speed whether or not anything ever suspends.
    #
    # The alternative is emscripten_set_main_loop() plus an #if in main(), and
    # it is what raylib_multiplatform does, because it ships to fourteen
    # targets and the download matters there. Here, staying plain matters more.
    #
    # --preload-file bundles resources/ into a .data file next to the .html, so
    # RESOURCES_PATH resolves in the browser's virtual filesystem exactly as it
    # does on disk.
    LINK_FLAGS "-sUSE_GLFW=3 -sASYNCIFY -sTOTAL_MEMORY=67108864 -sALLOW_MEMORY_GROWTH=1 \
--preload-file ${CMAKE_SOURCE_DIR}/resources@/resources/"
  )
endif()

target_link_libraries("${CMAKE_PROJECT_NAME}" PRIVATE raylib)
