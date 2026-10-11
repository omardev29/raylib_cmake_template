# DEV_LINKER from config.cmake. Debug preset only.
#
# Included AFTER project(): choosing a linker means checking that it links, and
# checking means compiling a test program, which needs a compiler.

if(PRODUCTION_BUILD OR DEV_LINKER STREQUAL "default")
  return()
endif()
if(MSVC)
  message(STATUS "DEV_LINKER: MSVC always links with its own link.exe")
  return()
endif()

# mold writes ELF and nothing else: no PE/COFF, no Mach-O. Asked for by name
# where it cannot work, it is refused here, with the reason — the linker's own
# error would be about `ld` and never mention mold.
if(DEV_LINKER STREQUAL "mold" AND NOT CMAKE_EXECUTABLE_FORMAT STREQUAL "ELF")
  message(FATAL_ERROR
    "DEV_LINKER mold cannot work on ${CMAKE_SYSTEM_NAME}: mold links ELF only. "
    "Use lld, or auto to let the build pick whatever actually links here.")
endif()

if(DEV_LINKER STREQUAL "auto")
  set(_dev_linkers mold lld)
else()
  set(_dev_linkers ${DEV_LINKER})
endif()

# check_linker_flag() links a test program with the flag, which is the question
# that matters: finding the binary is not enough. GCC's -fuse-ld=lld wants an
# `ld.lld` on PATH, not just `lld`, and MSYS2 ships one without the other.
include(CheckLinkerFlag)
foreach(_ld IN LISTS _dev_linkers)
  if(_ld STREQUAL "mold" AND NOT CMAKE_EXECUTABLE_FORMAT STREQUAL "ELF")
    continue()
  endif()
  check_linker_flag(CXX "-fuse-ld=${_ld}" DEV_LINKER_${_ld}_WORKS)
  if(DEV_LINKER_${_ld}_WORKS)
    add_link_options("-fuse-ld=${_ld}")
    message(STATUS "DEV_LINKER: ${_ld}")
    return()
  endif()
endforeach()

# Nothing usable here. auto is a speed setting, and a speed setting that stops a
# build is worse than a slow build. An explicit choice warns instead, so you
# know you did not get it.
if(DEV_LINKER STREQUAL "auto")
  message(STATUS "DEV_LINKER: the platform default (no faster one links here)")
else()
  message(WARNING "DEV_LINKER ${DEV_LINKER} cannot link here; using the platform default.")
endif()
