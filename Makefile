# Makefile — the handful of commands you actually type.
#
#   make          compile the debug build, into build/
#   make run      compile what changed, then play
#   make rel      compile the build you ship, into build/release/
#   make web      compile for the browser, into build/web/ (needs the emsdk)
#   make serve    play the web build: emrun serves it and opens your browser
#   make win      compile the Windows build you ship, on Linux, into
#                 build/windows/ (needs MinGW-w64)
#   make win-run  play that Windows build here, under Wine
#   make win-clang-cl      the same Windows build with clang-cl, into
#                          build/windows-clang-cl/ (needs LLVM and xwin)
#   make win-clang-cl-run  play that one under Wine
#   make clean    delete every build
#
# Every recipe is plain CMake underneath, so this file doubles as a cheat
# sheet. And because the recipes are cmake commands and nothing else, sh and
# cmd.exe run them alike, so any make works — GNU make on Linux, on Windows and
# in MSYS2, the 3.81 that macOS ships, or BSD make. Not nmake.
#
# The quotes around "cmake" are not decoration, though you can drop them when
# you type a command yourself. GNU make 4.3, the one in Ubuntu 22.04 and 24.04
# and in Debian 12, looks an unquoted command up on PATH by itself and stops at
# anything named cmake, folders included. The emsdk puts a folder named cmake
# on PATH, so once it is activated every target fails with "cmake: Permission
# denied". Quoted, the command goes through the shell, which skips folders.
# Make 4.4 fixed it.

# Compiling is left to CMake, which drives Ninja: Ninja compares every source,
# header and compiler flag with what it built last, compiles only what changed,
# and does nothing at all when nothing did. So `make run` compiles and plays
# after an edit, and just plays when there was none.
dev: build/build.ninja
	"cmake" --build --preset debug

run: build/build.ninja
	"cmake" --build --preset debug --target run

rel: build/release/build.ninja
	"cmake" --build --preset release

web: build/web/build.ninja
	"cmake" --build --preset web

serve: build/web/build.ninja
	"cmake" --build --preset web --target run

win: build/windows/build.ninja
	"cmake" --build --preset windows

win-run: build/windows/build.ninja
	"cmake" --build --preset windows --target run

win-clang-cl: build/windows-clang-cl/build.ninja
	"cmake" --build --preset windows-clang-cl

win-clang-cl-run: build/windows-clang-cl/build.ninja
	"cmake" --build --preset windows-clang-cl --target run

clean:
	"cmake" -E rm -rf build

# Configuring is make's own job. build.ninja is a real file, so make compares
# dates and configures only when a build directory is new or CMakePresets.json
# changed since. Any other change — config.cmake, CMakeLists.txt, a new source
# file — the build notices by itself. CMake writes build.ninja only when
# configuring succeeded, so a configure that failed is simply tried again.
build/build.ninja: CMakePresets.json
	"cmake" --preset debug

build/release/build.ninja: CMakePresets.json
	"cmake" --preset release

build/web/build.ninja: CMakePresets.json
	"cmake" --preset web

build/windows/build.ninja: CMakePresets.json
	"cmake" --preset windows

build/windows-clang-cl/build.ninja: CMakePresets.json
	"cmake" --preset windows-clang-cl

.PHONY: dev run rel web serve win win-run win-clang-cl win-clang-cl-run clean
