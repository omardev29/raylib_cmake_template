# Checks config.cmake. A typo there stops the configure here, with a message
# that names the setting, instead of surfacing later as a compiler, raylib or
# linker error that never mentions it.

# First, the one thing about the project's folder that CMake itself cannot
# take: a # or a ; anywhere in its path, as in "Game #2". The configure would
# stop much later, in GLFW's files, with a message that never says why.
if(CMAKE_SOURCE_DIR MATCHES "[#;]" OR CMAKE_BINARY_DIR MATCHES "[#;]")
  message(FATAL_ERROR
    "The project is in \"${CMAKE_SOURCE_DIR}\", and CMake cannot build in a "
    "folder whose path has a # or a ; in it. Rename the folder, or move the "
    "project to another one.")
endif()

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
if(GAME_NAME MATCHES "^(raylib|glfw|run|copy_resources|banner|tcc_runtime)$")
  message(FATAL_ERROR
    "config.cmake: GAME_NAME \"${GAME_NAME}\" is the name of a target the build "
    "already has. Pick another one.")
endif()

# The floor is raylib.h's own: under C++98 it stops with #error, and its
# colors are compound literals, which C89 does not have.
expect_one_of(CMAKE_C_STANDARD 99 11 17 23)
expect_one_of(CMAKE_CXX_STANDARD 11 14 17 20 23 26)

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
# builds its fonts with rtextures. Without this check the link fails on
# functions like GenImageColor that your code never called.
if("rtextures" IN_LIST RAYLIB_DISABLED_MODULES AND NOT "rtext" IN_LIST RAYLIB_DISABLED_MODULES)
  message(FATAL_ERROR
    "config.cmake: rtext needs rtextures, so disabling rtextures means disabling "
    "rtext too. Add rtext to RAYLIB_DISABLED_MODULES, or keep rtextures.")
endif()

expect_one_of(WINDOWS_BACKEND glfw win32 rgfw)
expect_one_of(LINUX_BACKEND glfw rgfw drm)
expect_one_of(LINUX_WAYLAND ON OFF)
# Each valid on its own, together a contradiction: RGFW on Linux is X11-only, so
# the build would quietly produce X11 while config.cmake said Wayland.
if(LINUX_BACKEND STREQUAL "rgfw" AND LINUX_WAYLAND)
  message(FATAL_ERROR
    "config.cmake: LINUX_BACKEND rgfw is X11-only, so it cannot be combined with "
    "LINUX_WAYLAND ON. Use glfw for native Wayland, or set LINUX_WAYLAND OFF.")
endif()

expect_one_of(HARDENING ON OFF)

expect_one_of(DEV_C_COMPILER default clang clang-cl gcc mingw msvc tcc)
expect_one_of(DEV_CPP_COMPILER default clang clang-cl gcc mingw msvc)
expect_one_of(DEV_LINKER auto mold lld default)
