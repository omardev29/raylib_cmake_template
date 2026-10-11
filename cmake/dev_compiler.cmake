# DEV_COMPILER from config.cmake. Debug preset only.
#
# Included BEFORE project(), because project() is where CMake picks the
# compiler and locks it into the build directory's cache. A plain variable set
# here only counts on the very first configure; after that the cache wins. So
# the choice is written into the cache with FORCE, which makes CMake notice the
# change, wipe the cache and configure again with the new compiler.
#
# What CMake cannot do is un-pick one. Going back to "default" in a directory
# that already has a compiler locked in stops with a message, rather than
# quietly carrying on with the old one.

if(PRODUCTION_BUILD)
  return() # release and web always build with the platform's default
endif()

if(DEV_COMPILER STREQUAL "default")
  if(DEV_COMPILER_LOCKED)
    message(FATAL_ERROR
      "DEV_COMPILER is back to \"default\", but this build directory is locked to "
      "${CMAKE_CXX_COMPILER} and CMake cannot un-pick a compiler. Delete it "
      "(`just clean`) and configure again.")
  endif()
  return()
endif()

# mingw and msvc only exist on Windows. A Linux box with the MinGW cross
# compiler installed would otherwise find it and quietly start producing .exe
# files. Before project() these variables describe the machine you are on, not
# the target. MSYS and CYGWIN as well as WIN32, because in MSYS2's own shell
# CMake sets MSYS and not WIN32 — in the very shell that ships the compiler.
if(DEV_COMPILER MATCHES "^(mingw|msvc)$" AND NOT (WIN32 OR MSYS OR CYGWIN))
  message(FATAL_ERROR
    "DEV_COMPILER ${DEV_COMPILER} only makes sense on Windows. Here, use clang, "
    "gcc or default.")
endif()

# Several names per compiler, because which one exists depends on how it was
# installed. MinGW is almost never a plain `gcc` on Windows: MSYS2 ships
# x86_64-w64-mingw32-gcc, and a stray `gcc` from a Git for Windows shell is how
# you get a build that asks for X11.
if(DEV_COMPILER STREQUAL "clang")
  set(_dev_c_names clang)
  set(_dev_cxx_names clang++)
elseif(DEV_COMPILER STREQUAL "gcc")
  set(_dev_c_names gcc)
  set(_dev_cxx_names g++)
elseif(DEV_COMPILER STREQUAL "mingw")
  set(_dev_c_names x86_64-w64-mingw32-gcc gcc)
  set(_dev_cxx_names x86_64-w64-mingw32-g++ g++)
else() # msvc
  set(_dev_c_names cl)
  set(_dev_cxx_names cl)
endif()

find_program(_dev_cc NAMES ${_dev_c_names} NO_CACHE)
find_program(_dev_cxx NAMES ${_dev_cxx_names} NO_CACHE)
if(NOT _dev_cc OR NOT _dev_cxx)
  message(FATAL_ERROR
    "DEV_COMPILER is ${DEV_COMPILER}, but ${_dev_c_names} / ${_dev_cxx_names} is "
    "not on PATH. Install it, or set DEV_COMPILER to default.")
endif()

set(CMAKE_C_COMPILER "${_dev_cc}" CACHE FILEPATH "C compiler, from DEV_COMPILER" FORCE)
set(CMAKE_CXX_COMPILER "${_dev_cxx}" CACHE FILEPATH "C++ compiler, from DEV_COMPILER" FORCE)
set(DEV_COMPILER_LOCKED ON CACHE INTERNAL "DEV_COMPILER has picked this directory's compiler")
