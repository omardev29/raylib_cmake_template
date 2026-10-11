# Justfile — the handful of commands you actually type.
#
#   just          list these
#   just run      build what changed, then play
#   just web      build for the browser
#   just rel      the build you ship
#
# Every recipe is plain CMake underneath, so this file doubles as a cheat sheet:
# read a recipe to see the command it saves you typing.
#
# Needs: just (https://just.systems), cmake 3.25+, ninja and a C/C++ compiler.
# `just web` also needs the emsdk activated (EMSDK set).

_default:
    @just --list --unsorted

# Configuring again costs a fraction of a second when nothing changed, and it
# means a change to CMakePresets.json is never missed.

# Build what changed, then play.
run:
    cmake --preset debug
    cmake --build --preset debug --target run

# Compile the debug build, into build/.
dev:
    cmake --preset debug
    cmake --build --preset debug

# Optimised, LTO, resources/ copied next to the executable and, on Windows, no
# console window: build/release/ is the folder you ship.

# Compile the build you ship, into build/release/.
rel:
    cmake --preset release
    cmake --build --preset release

# Build for the browser, into build/web/. Needs the emsdk (EMSDK set).
web:
    cmake --preset web
    cmake --build --preset web
    @echo "play it: cmake --build --preset web --target run   (emrun serves it and opens your browser)"

# Delete every build.
clean:
    cmake -E rm -rf build
