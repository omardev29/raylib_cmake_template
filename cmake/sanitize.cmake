# make sanitize: the debug build with AddressSanitizer (ASan) and
# UndefinedBehaviorSanitizer (UBSan) compiled into every target — raylib,
# GLFW, your game and any library you add. ASan stops the game at the first
# read or write out of bounds, use after free or double free, and at exit
# lists the memory never freed. UBSan reports undefined behavior — a signed
# overflow, a shift too far, a null or misaligned pointer — and lets the game
# run on. Every report names the file and the line. README.md, "Finding memory
# bugs: make sanitize".
#
# Everything else is the debug build's: DEV_C_COMPILER, DEV_CPP_COMPILER and
# DEV_LINKER apply here too.

if(NOT SANITIZE)
  return()
endif()

if(PRODUCTION_BUILD)
  message(FATAL_ERROR
    "SANITIZE is for the debug build, and this one is a release: the "
    "sanitizers make a game two to four times as slow and are not meant to "
    "ship. The sanitize preset, `make sanitize`, is the build they are for.")
endif()

# The compilers that have no sanitizers to offer here, each with the reason.
foreach(lang IN ITEMS C CXX)
  if(COMPILER_NAME_${lang} STREQUAL "TCC")
    message(FATAL_ERROR
      "make sanitize: tcc has no sanitizers. The sanitize build reads the same "
      "DEV_C_COMPILER as the debug build: set it to default, gcc or clang.")
  elseif(COMPILER_NAME_${lang} STREQUAL "MINGW")
    message(FATAL_ERROR
      "make sanitize: MinGW's GCC has no AddressSanitizer for Windows. In "
      "Visual Studio's x64 Native Tools Command Prompt, make sanitize builds "
      "with MSVC and its own.")
  elseif(COMPILER_NAME_${lang} STREQUAL "CLANG-CL")
    message(FATAL_ERROR
      "make sanitize: clang-cl only brings its sanitizers' libraries along "
      "when it links the program itself, and CMake links with lld-link. Set "
      "DEV_C_COMPILER and DEV_CPP_COMPILER to default or msvc: in Visual "
      "Studio's prompt, make sanitize then builds with MSVC and its own "
      "AddressSanitizer.")
  endif()
endforeach()

if(MSVC)
  # MSVC has AddressSanitizer and no UBSan. Its runtime is a DLL next to
  # cl.exe, from the Visual Studio Installer's "C++ AddressSanitizer", which
  # comes ticked with the C++ workload. CMakeLists.txt copies it next to the
  # game, so the game also starts outside the prompt.
  get_filename_component(_cl_dir "${CMAKE_CXX_COMPILER}" DIRECTORY)
  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(_asan_dll clang_rt.asan_dynamic-x86_64.dll)
  else()
    set(_asan_dll clang_rt.asan_dynamic-i386.dll)
  endif()
  find_file(SANITIZE_RUNTIME ${_asan_dll} PATHS "${_cl_dir}" NO_DEFAULT_PATH NO_CACHE)
  if(NOT SANITIZE_RUNTIME)
    message(FATAL_ERROR
      "make sanitize: MSVC's AddressSanitizer is not installed: there is no "
      "${_asan_dll} next to ${CMAKE_CXX_COMPILER}. Add it in the Visual Studio "
      "Installer: Modify, then \"C++ AddressSanitizer\" under Individual "
      "components (\"MSVC AddressSanitizer\" in Visual Studio 2026).")
  endif()
  add_compile_options(/fsanitize=address)

  # Two of CMake's Debug flags are ones Microsoft documents as incompatible
  # with ASan: /RTC1, MSVC's own checks of the stack and of uninitialized
  # variables, and /INCREMENTAL, faster relinking, which link.exe ignores with
  # a warning on every link.
  foreach(lang IN ITEMS C CXX)
    string(REGEX REPLACE "/RTC[1csu]+" "" CMAKE_${lang}_FLAGS_DEBUG "${CMAKE_${lang}_FLAGS_DEBUG}")
  endforeach()
  string(REGEX REPLACE "/INCREMENTAL(:YES)?( |$)" "/INCREMENTAL:NO\\2"
    CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG}")
  return()
endif()

# GCC and Clang. Their sanitizers' runtime is a library of its own, which not
# every distribution installs with the compiler: a test program finds out,
# before anything is built.
include(CheckCSourceCompiles)
include(CheckCXXSourceCompiles)
set(CMAKE_REQUIRED_QUIET ON)
set(CMAKE_REQUIRED_FLAGS -fsanitize=address,undefined)
check_c_source_compiles("int main(void) { return 0; }" SANITIZE_C_LINKS)
check_cxx_source_compiles("int main() { return 0; }" SANITIZE_CXX_LINKS)
unset(CMAKE_REQUIRED_FLAGS)
foreach(lang IN ITEMS C CXX)
  if(NOT SANITIZE_${lang}_LINKS)
    if(CMAKE_${lang}_COMPILER_ID STREQUAL "GNU")
      string(CONCAT _package "Debian and Ubuntu install it with GCC. Fedora "
        "has it as libasan and libubsan")
    else()
      string(REGEX MATCH "^[0-9]+" _major "${CMAKE_${lang}_COMPILER_VERSION}")
      string(CONCAT _package "Debian and Ubuntu have it as "
        "libclang-rt-${_major}-dev. Elsewhere, look for LLVM's compiler-rt")
    endif()
    # Both tried again on the next configure, once it is installed.
    unset(SANITIZE_C_LINKS CACHE)
    unset(SANITIZE_CXX_LINKS CACHE)
    message(FATAL_ERROR
      "make sanitize: ${CMAKE_${lang}_COMPILER} cannot link a program with "
      "AddressSanitizer and UndefinedBehaviorSanitizer: their runtime is not "
      "installed. ${_package}. README.md, \"Finding memory bugs: make "
      "sanitize\".")
  endif()
endforeach()

# -fno-omit-frame-pointer keeps every report's call stack whole, should the
# debug build ever optimize. _FORTIFY_SOURCE's checked functions, which some
# distributions turn on whenever there is optimization, would bypass ASan's
# own checks of the same calls.
add_compile_options(-fsanitize=address,undefined -fno-omit-frame-pointer -U_FORTIFY_SOURCE)
add_link_options(-fsanitize=address,undefined)
