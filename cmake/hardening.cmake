# HARDENING from config.cmake: the compiler's and the linker's protections
# against memory bugs, in the build you ship. Release builds only — the
# release, windows and windows-clang-cl presets — and every target in them:
# raylib, GLFW, your game and any library you add. README.md, "How hardened
# is a release build?", says what each one stops.
#
# Each flag is tried on a test program first, so a compiler too old for one
# builds without it rather than failing, and the configure says which:
#
#   -- HARDENING: -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS -fstack-protector-strong ...
#
# Included after project(), because the tests need the compilers, and before
# raylib and the game, because these settings only reach targets created
# after them.

# The web is left as it is. WebAssembly keeps return addresses out of the
# program's own memory and checks every indirect call, so most of this has
# nothing to protect there, and the browser's sandbox does the rest.
if(NOT (PRODUCTION_BUILD AND HARDENING) OR EMSCRIPTEN)
  return()
endif()

include(CheckCCompilerFlag)
include(CheckCXXCompilerFlag)
include(CheckCSourceCompiles)
include(CheckCXXSourceCompiles)
set(CMAKE_REQUIRED_QUIET ON)
set(_hardening "")         # what is on, for the message at the end
set(_hardening_missing "") # what this compiler cannot do

# A compile flag for every target, if the C and C++ compilers take it. When
# only one of them does, its own language still gets it. A warning counts as a
# no: Clang takes some flags it can do nothing with on a given processor, such
# as -fstack-clash-protection on RISC-V, and then warns about them in every
# file it compiles.
function(harden flag)
  string(MAKE_C_IDENTIFIER "HARDENING${flag}" var)
  if(MSVC)
    set(CMAKE_REQUIRED_FLAGS /WX)
  else()
    set(CMAKE_REQUIRED_FLAGS -Werror)
  endif()
  check_c_compiler_flag("${flag}" ${var}_C)
  check_cxx_compiler_flag("${flag}" ${var}_CXX)
  if(${var}_C AND ${var}_CXX)
    add_compile_options("${flag}")
    set(_hardening ${_hardening} "${flag}" PARENT_SCOPE)
    return()
  endif()
  if(${var}_C)
    add_compile_options("$<$<COMPILE_LANGUAGE:C>:${flag}>")
  elseif(${var}_CXX)
    add_compile_options("$<$<COMPILE_LANGUAGE:CXX>:${flag}>")
  endif()
  set(_hardening_missing ${_hardening_missing} "${flag}" PARENT_SCOPE)
endfunction()

if(MSVC)
  # MSVC and clang-cl. The stack canary (/GS), ASLR and DEP are on in every
  # build already.
  #
  # Control Flow Guard: an indirect call — a function pointer, a virtual
  # function — may only land at the start of a real function, not wherever an
  # overwritten pointer says. The compiler marks the calls, the linker lists
  # the functions.
  add_compile_options(/guard:cf)
  add_link_options(/guard:cf)
  list(APPEND _hardening /guard:cf)

  # The shadow stack: the processor keeps its own copy of every return address
  # and stops the game when the one on the stack no longer matches it. Windows
  # 10 and 11 on Intel's 11th generation or AMD's Zen 3 and later; elsewhere
  # the mark is ignored. 64-bit x86 only.
  if(CMAKE_C_COMPILER_ARCHITECTURE_ID STREQUAL "x64")
    add_link_options(/CETCOMPAT)
    list(APPEND _hardening /CETCOMPAT)
  endif()

  # The C++ library's own checks: an index out of range, front() of an empty
  # vector and the like stop the game, rather than read or write past the
  # end. From Visual Studio 2022 17.14, whose headers know the switch.
  check_cxx_source_compiles([[
    #include <vector>
    #ifndef _MSVC_STL_HARDENING
    #error older than Visual Studio 2022 17.14
    #endif
    int main() { return 0; }
  ]] HARDENING_MSVC_STL)
  if(HARDENING_MSVC_STL)
    add_compile_definitions($<$<COMPILE_LANGUAGE:CXX>:_MSVC_STL_HARDENING=1>)
    list(APPEND _hardening -D_MSVC_STL_HARDENING=1)
  else()
    list(APPEND _hardening_missing -D_MSVC_STL_HARDENING=1)
  endif()

  # clang-cl can also start every local at zero (below); MSVC cannot.
  if(CMAKE_C_COMPILER_ID STREQUAL "Clang")
    harden(-ftrivial-auto-var-init=zero)
  endif()
else()
  # GCC and Clang, MinGW and macOS included.
  #
  # _FORTIFY_SOURCE: memcpy(), strcpy(), sprintf() and dozens more check the
  # size of their destination wherever the compiler knows it, and stop the game
  # rather than write past it. Level 3 also knows sizes that exist only while
  # the game runs, like malloc(n)'s, which takes GCC 12 or Clang 9; older ones
  # get level 2. -U first, because some distributions' compilers (Ubuntu's)
  # define it already.
  check_c_source_compiles(
    "int main(void) { char b[4]; return (int)__builtin_dynamic_object_size(b, 0); }"
    HARDENING_DYNAMIC_OBJECT_SIZE)
  if(HARDENING_DYNAMIC_OBJECT_SIZE)
    set(_fortify 3)
  else()
    set(_fortify 2)
  endif()
  add_compile_options(-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=${_fortify})
  list(APPEND _hardening -D_FORTIFY_SOURCE=${_fortify})

  # The C++ library's own checks, an index out of range and the like, each
  # library through its own switch: libc++, Clang's on macOS, from LLVM 18;
  # libstdc++, GCC's, which Clang uses too on Linux and with MinGW.
  check_cxx_source_compiles([[
    #include <cstddef>
    #ifndef _LIBCPP_VERSION
    #error not libc++
    #endif
    int main() { return 0; }
  ]] HARDENING_LIBCXX)
  if(HARDENING_LIBCXX)
    check_cxx_source_compiles([[
      #include <cstddef>
      #if _LIBCPP_VERSION < 180000
      #error older than LLVM 18
      #endif
      int main() { return 0; }
    ]] HARDENING_LIBCXX_18)
    set(_stl _LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_FAST)
    set(_stl_ok ${HARDENING_LIBCXX_18})
  else()
    set(_stl _GLIBCXX_ASSERTIONS) # libstdc++, which has had it for years
    set(_stl_ok ON)
  endif()
  if(_stl_ok)
    add_compile_definitions($<$<COMPILE_LANGUAGE:CXX>:${_stl}>)
    list(APPEND _hardening -D${_stl})
  else()
    list(APPEND _hardening_missing -D${_stl})
  endif()

  # The stack canary: a value next to the return address, checked before the
  # function returns, in every function with an array or a local whose address
  # is taken. A buffer overflow that reaches the return address stops the game
  # instead of jumping wherever the overflow says.
  harden(-fstack-protector-strong)

  # Locals with no initializer start at zero instead of at whatever was on the
  # stack before: a forgotten initialization is a plain bug, not a way to read
  # old data. GCC 12, Clang 16.
  harden(-ftrivial-auto-var-init=zero)

  if(CMAKE_EXECUTABLE_FORMAT STREQUAL "ELF") # Linux and the BSDs
    # A huge local array or alloca() cannot jump over the guard page below the
    # stack into other memory. Windows programs probe their stack anyway.
    harden(-fstack-clash-protection)

    # Return addresses and indirect jumps checked by the processor itself,
    # where the processor, the kernel and the C library support it: Intel's
    # CET on x86, PAC and BTI on 64-bit ARM.
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|AMD64|amd64|i[3-6]86)$")
      harden(-fcf-protection=full)
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64|ARM64)$")
      harden(-mbranch-protection=standard)
    endif()

    # A position-independent executable, which the system loads at a new
    # address every time (ASLR); most distributions' compilers make one
    # already. RELRO and BIND_NOW: the table of the shared libraries' functions
    # is filled in at start and then made read-only, so it cannot be
    # overwritten to redirect a call. And a stack that holds data, never code.
    add_compile_options(-fPIE)
    add_link_options(-pie -Wl,-z,relro -Wl,-z,now -Wl,-z,noexecstack)
    list(APPEND _hardening -fPIE -pie -Wl,-z,relro,-z,now,-z,noexecstack)
  endif()

  if(MINGW)
    # What the canary and _FORTIFY_SOURCE call when they catch an overflow is
    # in a current mingw-w64's own runtime, so the flags above go to the
    # compiler only: at the link, GCC would add its own copy, libssp, as well.
    # A mingw-w64 without them gets the flag at the link too, and libssp with
    # it, linked in statically like the rest of the runtime.
    set(CMAKE_REQUIRED_DEFINITIONS -O2 -D_FORTIFY_SOURCE=2 -fstack-protector-strong)
    check_c_source_compiles([[
      #include <string.h>
      int main(int argc, char **argv) { char b[8]; memcpy(b, argv[0], (size_t)argc); return b[0]; }
    ]] HARDENING_MINGW_RUNTIME)
    unset(CMAKE_REQUIRED_DEFINITIONS)
    if(NOT HARDENING_MINGW_RUNTIME)
      add_link_options(-fstack-protector-strong)
    endif()

    # ASLR and DEP, which binutils turns on by itself from its version 2.36.
    add_link_options(-Wl,--dynamicbase -Wl,--high-entropy-va -Wl,--nxcompat)
    list(APPEND _hardening -Wl,--dynamicbase,--high-entropy-va,--nxcompat)
  endif()
endif()

list(JOIN _hardening " " _hardening)
message(STATUS "HARDENING: ${_hardening}")
if(_hardening_missing)
  list(JOIN _hardening_missing " " _hardening_missing)
  message(STATUS "HARDENING: not available with this compiler: ${_hardening_missing}")
endif()
