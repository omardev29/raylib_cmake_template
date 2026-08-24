# Justfile — the handful of commands you actually type.
#
#   just          list these
#   just run      play the game (builds first if it has to)
#   just web      build for the browser
#   just rel      the build you ship
#
# Needs: just (https://just.systems), cmake, ninja, and a C/C++ compiler.
# `just web` also needs the emsdk on PATH.

# The binary's name comes from [project] name in raylib.toml, so renaming your
# game does not break `just run`. The fallback keeps this file usable — without
# it a broken .toml would take out every recipe, including `just clean`.
project_name := shell('python3 tools/configure.py --print-name 2>/dev/null || echo game')

_default:
    @just --list --unsorted

# --- day to day -------------------------------------------------------------

# Compile the debug build.
dev:
    cmake --preset debug
    cmake --build build

# The test below is on the FILE, not on the run: written `run && game || build`,
# a game that exits non-zero — a crash, or your own error path — would trigger a
# rebuild and a second launch, which is a confusing thing to watch happen.

# Run the game. Only builds it if the binary is not there yet.
run:
    @[ -f build/{{ project_name }} ] || just dev
    ./build/{{ project_name }}

# Compile the build you ship: optimised, LTO, resources read from ./resources/.
rel:
    cmake --preset release
    cmake --build build

# Build for the browser. Needs the emsdk on PATH (EMSDK set).
web:
    cmake --preset web
    cmake --build --preset web
    @echo "build/web/{{ project_name }}.html — serve it, do not open the file directly:"
    @echo "  python3 -m http.server 8000 --directory build/web"

# Delete every build artefact and everything generated from raylib.toml.
clean:
    rm -rf build cmake/generated include/app_config.h
    @echo "clean. the next configure regenerates all of it."

# --- checks -----------------------------------------------------------------

# Check the config is valid and everything still compiles.
test:
    python3 tools/configure.py --check
    cmake --preset debug > /dev/null
    cmake --build build > /dev/null
    @echo "  ok    configuration valid and the build is clean"

# Format every file you own. `just fmt check` only reports.
fmt what="write":
    #!/usr/bin/env bash
    set -euo pipefail
    files=$(find src include -name '*.h' -o -name '*.cpp' -o -name '*.c' 2>/dev/null \
            | grep -v app_config.h | sort)
    [ -n "$files" ] || { echo "  nothing to format"; exit 0; }
    case "{{ what }}" in
      write) clang-format -i $files; echo "formatted $(echo "$files" | wc -w) files" ;;
      check)
        bad=0
        for f in $files; do
            clang-format "$f" | diff -q "$f" - >/dev/null || { echo "  unformatted  $f"; bad=1; }
        done
        if [ "$bad" -ne 0 ]; then echo; echo "FALLA: run \`just fmt\`."; exit 1; fi
        echo "  ok    every file is formatted"
        ;;
      *) echo "unknown: {{ what }} (write | check)"; exit 1 ;;
    esac

# Run clang-tidy over src/. Needs build/compile_commands.json, so it configures first.
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    cmake --preset debug > /dev/null
    mapfile -t files < <(find src -name '*.cpp' -o -name '*.c' | sort)
    clang-tidy -p build --quiet "${files[@]}"
    echo "  ok    no warnings"
