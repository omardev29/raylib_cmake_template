#!/bin/bash
# Updates .clangd with Android NDK include paths
# Run from project root: ./update_clangd.sh

set -e

ANDROID_NDK="${ANDROID_NDK:-$ANDROID_HOME/ndk/26.1.10909125}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLANGD_PATH="$PROJECT_ROOT/.clangd"

if [ ! -d "$ANDROID_NDK" ]; then
  echo "NDK not found at: $ANDROID_NDK"
  echo "Set ANDROID_NDK environment variable to configure"
  exit 1
fi

NATIVE_APP_GLUE_PATH="$ANDROID_NDK/sources/android/native_app_glue"
SYSROOT="$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot"

if [ ! -d "$NATIVE_APP_GLUE_PATH" ]; then
  echo "native_app_glue not found at: $NATIVE_APP_GLUE_PATH"
  exit 1
fi

if [ ! -d "$SYSROOT" ]; then
  echo "sysroot not found at: $SYSROOT"
  exit 1
fi

echo "Updating .clangd with NDK configuration"
echo "  - NDK: $ANDROID_NDK"
echo "  - target: aarch64-linux-android24"
echo "  - sysroot: $SYSROOT"

cat >"$CLANGD_PATH" <<EOF
CompileFlags:
  CompilationDatabase:
    - build
    - raymob/.cxx/compile_commands
  Add:
    - "--target=aarch64-linux-android24"
    - "--sysroot=$SYSROOT"
    - "-I$NATIVE_APP_GLUE_PATH"
  Remove:
    - "-fmodules-ts"
    - "-fmodule-mapper=*"
    - "-fdeps-format=*"
    - "-fno-fat-lto-objects"
    - "-flto=*"

If:
  PathMatch: .*
EOF

echo ".clangd updated successfully"
