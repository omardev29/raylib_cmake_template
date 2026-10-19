# The compilers a build gets when nothing names them: every release, and the
# debug build with DEV_C_COMPILER and DEV_CPP_COMPILER at "default".
#
# Elsewhere that is CMake's own default. On Windows, CMake takes whichever
# compiler comes first on PATH, and never clang-cl, so this file picks: in
# Visual Studio's x64 prompt, clang-cl when "C++ Clang tools for Windows" is
# installed, and MSVC when it is not; anywhere else, MinGW. clang-cl and MSVC
# take Windows' headers and libraries from that prompt, so outside one neither
# is tried. README.md, "Setting up", has the prompt. make sanitize skips
# clang-cl for MSVC, whose AddressSanitizer a CMake build can link
# (cmake/sanitize.cmake).
#
# Before project(), which is where CMake picks the compilers, and only on a
# build directory's first configure: after that, its cache has them. CC and
# CXX in the environment, or -DCMAKE_C_COMPILER, still choose for themselves.

if(NOT CMAKE_HOST_WIN32 OR CMAKE_TOOLCHAIN_FILE OR CMAKE_GENERATOR MATCHES "^Visual Studio"
    OR DEFINED CACHE{CMAKE_C_COMPILER} OR DEFINED CACHE{CMAKE_CXX_COMPILER}
    OR DEFINED ENV{CC} OR DEFINED ENV{CXX})
  return()
endif()

# Visual Studio's prompts set VCINSTALLDIR, and the x64 one says so in
# VSCMD_ARG_TGT_ARCH: clang-cl builds 64-bit programs, and in a 32-bit prompt
# it would get 32-bit libraries. Visual Studio's own clang-cl sits under
# VCINSTALLDIR, where the prompt need not put it on PATH; LLVM's, installed on
# its own, is found on PATH first.
if(DEFINED ENV{VCINSTALLDIR})
  if("$ENV{VSCMD_ARG_TGT_ARCH}" STREQUAL "x64" AND NOT SANITIZE)
    file(TO_CMAKE_PATH "$ENV{VCINSTALLDIR}" _vc)
    find_program(_default_clang_cl NAMES clang-cl PATHS "${_vc}/Tools/Llvm/x64/bin" NO_CACHE)
  endif()
  find_program(_default_cl NAMES cl NO_CACHE)
endif()
find_program(_default_gcc NAMES x86_64-w64-mingw32-gcc gcc NO_CACHE)
find_program(_default_gxx NAMES x86_64-w64-mingw32-g++ g++ NO_CACHE)

if(_default_clang_cl)
  set(_default_c "${_default_clang_cl}")
  set(_default_cxx "${_default_clang_cl}")
elseif(_default_cl)
  set(_default_c "${_default_cl}")
  set(_default_cxx "${_default_cl}")
elseif(_default_gcc AND _default_gxx)
  set(_default_c "${_default_gcc}")
  set(_default_cxx "${_default_gxx}")
else()
  return() # none of them: CMake looks for itself, and says what it finds
endif()
set(CMAKE_C_COMPILER "${_default_c}" CACHE FILEPATH "C compiler")
set(CMAKE_CXX_COMPILER "${_default_cxx}" CACHE FILEPATH "C++ compiler")
