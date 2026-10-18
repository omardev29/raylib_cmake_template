# DEV_C_COMPILER and DEV_CPP_COMPILER from config.cmake. Debug preset only.
#
# Included BEFORE project(), because project() is where CMake picks the
# compilers and locks them into the build directory's cache. A plain variable
# set here only counts on the very first configure; after that the cache wins.
# So each choice is written into the cache with FORCE, which makes CMake notice
# the change, wipe the cache and configure again with the new compiler.
#
# What CMake cannot do is un-pick one. Going back to "default" in a directory
# that already has a compiler locked in stops with a message, rather than
# quietly carrying on with the old one.
#
# What project() then finds is held against these choices by
# cmake/compilers.cmake, by what each compiler turns out to be.

# Release, web and windows always build with the platform's defaults, and a
# toolchain file (the web's, the windows one's) brings its own compilers.
if(PRODUCTION_BUILD OR CMAKE_TOOLCHAIN_FILE)
  return()
endif()

# mingw and msvc only exist on Windows. A Linux box with the MinGW cross
# compiler installed would otherwise find it and quietly start producing .exe
# files in the debug build; `make win` is the way to those. Before project()
# these variables describe the machine you are on, not the target. MSYS and
# CYGWIN as well as WIN32, because in MSYS2's own shell CMake sets MSYS and not
# WIN32 — in the very shell that ships the compiler.
foreach(_setting IN ITEMS DEV_C_COMPILER DEV_CPP_COMPILER)
  if(${_setting} MATCHES "^(mingw|msvc)$" AND NOT (WIN32 OR MSYS OR CYGWIN))
    message(FATAL_ERROR
      "${_setting} ${${_setting}} only makes sense on Windows. Here, use clang, "
      "gcc or default — and `make win` for a Windows build.")
  endif()
endforeach()

# MSVC's objects link with MSVC's only, and the other way round: its C runtime
# and its C++ ABI are its own.
if((DEV_C_COMPILER STREQUAL "msvc" OR DEV_CPP_COMPILER STREQUAL "msvc")
    AND NOT (DEV_C_COMPILER STREQUAL "msvc" AND DEV_CPP_COMPILER STREQUAL "msvc"))
  message(FATAL_ERROR
    "msvc goes with msvc only: set both DEV_C_COMPILER and DEV_CPP_COMPILER to "
    "msvc, or neither.")
endif()

# tcc writes the object files of the system it runs on, and only Linux's are
# ones the rest of the toolchain can link: on Windows and macOS it writes ELF
# too, which their linkers do not read.
if(DEV_C_COMPILER STREQUAL "tcc" AND NOT CMAKE_HOST_LINUX)
  message(FATAL_ERROR
    "DEV_C_COMPILER tcc works on Linux only. Here, use clang, gcc or default.")
endif()

# Several names per compiler, because which one exists depends on how it was
# installed. MinGW is almost never a plain `gcc` on Windows: MSYS2 ships
# x86_64-w64-mingw32-gcc, and a stray `gcc` from a Git for Windows shell is how
# you get a build that asks for X11.
set(_dev_C_clang clang)
set(_dev_C_gcc gcc)
set(_dev_C_mingw x86_64-w64-mingw32-gcc gcc)
set(_dev_C_msvc cl)
set(_dev_C_tcc tcc)
set(_dev_CXX_clang clang++)
set(_dev_CXX_gcc g++)
set(_dev_CXX_mingw x86_64-w64-mingw32-g++ g++)
set(_dev_CXX_msvc cl)

foreach(_lang IN ITEMS C CXX)
  if(_lang STREQUAL "C")
    set(_setting DEV_C_COMPILER)
  else()
    set(_setting DEV_CPP_COMPILER)
  endif()
  set(_choice "${${_setting}}")

  if(_choice STREQUAL "default")
    if(${_setting}_LOCKED)
      message(FATAL_ERROR
        "${_setting} is back to \"default\", but this build directory is locked "
        "to ${CMAKE_${_lang}_COMPILER} and CMake cannot un-pick a compiler. "
        "Delete it (`make clean`) and configure again.")
    endif()
    continue()
  endif()

  find_program(_dev_${_lang} NAMES ${_dev_${_lang}_${_choice}} NO_CACHE)
  if(NOT _dev_${_lang})
    list(JOIN _dev_${_lang}_${_choice} " or " _names)
    message(FATAL_ERROR
      "${_setting} is ${_choice}, but ${_names} is not on PATH. Install it, or "
      "set ${_setting} to default.")
  endif()

  set(CMAKE_${_lang}_COMPILER "${_dev_${_lang}}" CACHE FILEPATH "${_lang} compiler, from ${_setting}" FORCE)
  set(${_setting}_LOCKED ON CACHE INTERNAL "${_setting} has picked this directory's ${_lang} compiler")
endforeach()
