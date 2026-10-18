# The compilers project() found, by what they really are rather than by their
# names: a name can be another compiler entirely. On macOS `gcc` is Apple's
# Clang, and `cc` can be anything. project() finds out by compiling a test file
# with each one, into CMAKE_C_COMPILER_ID and CMAKE_CXX_COMPILER_ID, and this
# file holds those against config.cmake and announces them first thing in every
# build:
#
#   ===INITIALIZING DEBUG BUILD WITH GCC===
#   ===INITIALIZING DEBUG BUILD WITH TCC (C) AND GCC (C++)===
#
# Included right after project(), so a mismatch stops the configure before
# anything is built with the wrong compiler.

# The name the build gives a compiler. MinGW is GCC for Windows, and
# Emscripten, Clang for the web.
function(compiler_name lang out)
  set(id "${CMAKE_${lang}_COMPILER_ID}")
  if(EMSCRIPTEN)
    set(name "EMSCRIPTEN")
  elseif(id STREQUAL "GNU" AND MINGW)
    set(name "MINGW")
  elseif(id STREQUAL "GNU")
    set(name "GCC")
  elseif(id STREQUAL "TinyCC")
    set(name "TCC")
  elseif(id STREQUAL "AppleClang")
    set(name "APPLE CLANG")
  else()
    string(TOUPPER "${id}" name) # CLANG, MSVC
  endif()
  set(${out} "${name}" PARENT_SCOPE)
endfunction()

compiler_name(C COMPILER_NAME_C)
compiler_name(CXX COMPILER_NAME_CXX)

# DEV_C_COMPILER and DEV_CPP_COMPILER, held against what project() found. Only
# the debug preset reads them (cmake/dev_compiler.cmake), so only it is held.
# Apple's Clang counts as clang, and MinGW as gcc on Windows, where it is the
# only GCC there is.
#
# Not while a compiler is changing. Right after config.cmake names another one,
# this configure still runs with the old, and CMake starts over with the new
# one once it ends ("You have changed variables that require your cache to be
# deleted"). The cache already holds the new one, which is how to tell.
if(NOT ("$CACHE{CMAKE_C_COMPILER}" STREQUAL "${CMAKE_C_COMPILER}"
        AND "$CACHE{CMAKE_CXX_COMPILER}" STREQUAL "${CMAKE_CXX_COMPILER}"))
  set(_compiler_changing ON)
endif()
if(NOT (PRODUCTION_BUILD OR CMAKE_TOOLCHAIN_FILE OR _compiler_changing))
  foreach(lang IN ITEMS C CXX)
    if(lang STREQUAL "C")
      set(setting DEV_C_COMPILER)
    else()
      set(setting DEV_CPP_COMPILER)
    endif()
    string(TOUPPER "${${setting}}" wanted)
    set(found "${COMPILER_NAME_${lang}}")
    if(wanted STREQUAL "DEFAULT" OR found STREQUAL wanted
        OR (wanted STREQUAL "CLANG" AND found STREQUAL "APPLE CLANG")
        OR (wanted STREQUAL "GCC" AND found STREQUAL "MINGW"))
      continue()
    endif()
    message(FATAL_ERROR
      "${setting} is ${${setting}}, but ${CMAKE_${lang}_COMPILER} turned out to "
      "be ${CMAKE_${lang}_COMPILER_ID} ${CMAKE_${lang}_COMPILER_VERSION} — "
      "another compiler under that name. Put the real one first on PATH, or "
      "pick another ${setting}.")
  endforeach()
endif()

# tcc is for development only: it optimizes nothing. The release, web and
# windows builds never read DEV_C_COMPILER, but CMake's own default follows
# the CC environment variable, so CC=tcc in your shell would bring tcc into a
# release build all the same.
if(PRODUCTION_BUILD AND COMPILER_NAME_C STREQUAL "TCC")
  message(FATAL_ERROR
    "This is a release build, and its C compiler is tcc (${CMAKE_C_COMPILER}), "
    "which optimizes nothing — is CC set to it in your environment? Unset it, "
    "delete ${CMAKE_BINARY_DIR}, and build again.")
endif()

# The announcement. It is a target, so it runs on every build rather than only
# when CMake configures, and raylib, GLFW and your game wait for it
# (CMakeLists.txt), so it comes before their first line. Ninja's own line for
# it, just above, gives each compiler's path. $<CONFIG> is the build type, also
# where it is only picked at build time, as in Visual Studio.
if(COMPILER_NAME_C STREQUAL COMPILER_NAME_CXX)
  set(_with "${COMPILER_NAME_C}")
else()
  set(_with "${COMPILER_NAME_C} (C) AND ${COMPILER_NAME_CXX} (C++)")
endif()
add_custom_target(banner
  COMMAND "${CMAKE_COMMAND}" -E echo "===INITIALIZING $<UPPER_CASE:$<CONFIG>> BUILD WITH ${_with}==="
  COMMENT "C: ${CMAKE_C_COMPILER}, C++: ${CMAKE_CXX_COMPILER}"
  VERBATIM)
