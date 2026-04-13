#!/usr/bin/env pwsh
# Updates .clangd with Android NDK include paths
# Run from project root: .\update_clangd.ps1

$ErrorActionPreference = "Stop"

$AndroidNdk = if ($env:ANDROID_NDK) { $env:ANDROID_NDK } else { "$env:ANDROID_HOME\ndk\26.1.10909125" }
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClangdPath = "$ProjectRoot\.clangd"

if (-not (Test-Path $AndroidNdk)) {
    Write-Warning "NDK not found at: $AndroidNdk"
    Write-Host "Set ANDROID_NDK environment variable to configure"
    exit 0
}

$NativeAppGluePath = "$AndroidNdk\sources\android\native_app_glue"
$Sysroot = "$AndroidNdk\toolchains\llvm\prebuilt\windows-x86_64\sysroot"

if (-not (Test-Path $NativeAppGluePath)) {
    Write-Error "native_app_glue not found at: $NativeAppGluePath"
}

if (-not (Test-Path $Sysroot)) {
    Write-Error "sysroot not found at: $Sysroot"
}

Write-Host "Updating .clangd with NDK configuration"
Write-Host "  - NDK: $AndroidNdk"
Write-Host "  - target: aarch64-linux-android24"
Write-Host "  - sysroot: $Sysroot"

$ClangdContent = @"
CompileFlags:
  CompilationDatabase:
    - build
    - build/android
    - raymob/.cxx/compile_commands
  Add:
    - "--target=aarch64-linux-android24"
    - "--sysroot=$($Sysroot -replace '\\', '/')"
    - "-I$($NativeAppGluePath -replace '\\', '/')"
  Remove:
    - "-fmodules-ts"
    - "-fmodule-mapper=*"
    - "-fdeps-format=*"
    - "-fno-fat-lto-objects"
    - "-flto=*"

If:
  PathMatch: .*
"@

Set-Content -Path $ClangdPath -Value $ClangdContent -NoNewline
Write-Host ".clangd updated successfully"
