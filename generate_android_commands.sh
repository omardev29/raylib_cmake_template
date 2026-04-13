#!/bin/bash
# Generates compile_commands.json for Android using NDK toolchain
# Run from project root: ./generate_android_commands.sh

set -e

ANDROID_NDK="${ANDROID_NDK:-$ANDROID_HOME/ndk/26.1.10909125}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAYMOB_DIR="$PROJECT_ROOT/raymob"
BUILD_DIR="$RAYMOB_DIR/.cxx"

echo "Using NDK: $ANDROID_NDK"
echo "Project root: $PROJECT_ROOT"

mkdir -p "$BUILD_DIR"

cmake -S "$RAYMOB_DIR/app/src/main/cpp" \
    -B "$BUILD_DIR/compile_commands" \
    -G Ninja \
    -D CMAKE_TOOLCHAIN_FILE="$ANDROID_NDK/build/cmake/android.toolchain.cmake" \
    -D ANDROID_ABI="arm64-v8a" \
    -D ANDROID_PLATFORM="android-24" \
    -D PROJECT_ROOT="$PROJECT_ROOT" \
    -D RAYMOB_DIR="$RAYMOB_DIR" \
    --export-compile-commands="."

echo "compile_commands.json generated at: $BUILD_DIR/compile_commands/compile_commands.json"
