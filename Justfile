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

# --- day to day -------------------------------------------------------------

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

# --- checks -----------------------------------------------------------------

# Format every file you own. `just fmt check` only reports.
fmt what="write":
    #!/usr/bin/env bash
    set -euo pipefail
    files=$(find src include \( -name '*.c' -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp' \) | sort)
    [ -n "$files" ] || { echo "  nothing to format"; exit 0; }
    case "{{ what }}" in
      write) clang-format -i $files; echo "  formatted $(echo "$files" | wc -l | tr -d ' ') files" ;;
      check) clang-format --dry-run --Werror $files; echo "  ok    every file is formatted" ;;
      *) echo "unknown: {{ what }} (write | check)"; exit 1 ;;
    esac

# clang-tidy needs build/compile_commands.json, so this configures first.

# Run clang-tidy over src/, failing on any warning.
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    cmake --preset debug > /dev/null
    # Not mapfile: that is bash 4, and macOS ships bash 3.2 and is not going to
    # stop — it went GPLv3. This has to work on a Mac out of the box.
    files=()
    while IFS= read -r f; do
        files+=("$f")
    done < <(find src \( -name '*.c' -o -name '*.cpp' \) | sort)
    clang-tidy -p build --quiet --warnings-as-errors='*' "${files[@]}"
    echo "  ok    no warnings"
