#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
BUILD_DIR="$PROJECT_ROOT/build"
ANDROID_BUILD_DIR="$BUILD_DIR/android"

echo "=== Generating compile_commands.json for raylib_cmake_template ==="

if [ -z "$ANDROID_NDK" ]; then
    echo "WARNING: ANDROID_NDK environment variable not set. Android compile_commands will be skipped."
    echo "To generate Android compile_commands, set ANDROID_NDK to your NDK path."
else
    echo "Using ANDROID_NDK: $ANDROID_NDK"

    mkdir -p "$ANDROID_BUILD_DIR"

    echo "Generating Android compile_commands..."
    cmake -S "$PROJECT_ROOT/raymob" \
          -B "$ANDROID_BUILD_DIR" \
          -G Ninja \
          -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK/build/cmake/android.ninja.cmake" \
          -DCMAKE_SYSTEM_NAME=Android \
          -DCMAKE_ANDROID_ARCH_ABI=arm64-v8a \
          -DCMAKE_C_STANDARD=99 \
          -DCMAKE_CXX_STANDARD=11 \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
          -DPLATFORM=Android

    echo "Android compile_commands generated at: $ANDROID_BUILD_DIR/compile_commands.json"
fi

echo "=== Done ==="
