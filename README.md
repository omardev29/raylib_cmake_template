# RaylibCmakeSetup ORIGINAL README

---

## What is it?

I already set up a Raylib project for you! Take it and enjoy! You don't need to know CMake!

![image](https://github.com/meemknight/raylibCmakeSetup/assets/36445656/c50ab777-0cde-4d80-8df6-a0fd483f169d)


<p>Opening the Solution:</p> 

<img src="https://raw.githubusercontent.com/meemknight/photos/master/llge1.gif" width="350">

Or

<img src="https://raw.githubusercontent.com/meemknight/photos/master/llge2.gif" width="500">

Running the setup

Go to CMakeLists.txt, <kbd>CTRL + S</kbd> to make sure the solution was built.

Then, from this dropdown select mygame.exe

<img src="https://raw.githubusercontent.com/meemknight/photos/master/llge3.gif" width="200">

<kbd>Ctrl + F5</kbd> to build (<kbd>F5</kbd> oppens the debugger, you usually want to press <kbd>Ctrl + F5</kbd> because it oppens faster like this.

<p>Adding files:<br>
You should add .cpp in src/ and .h in include/ Whenever you add a new file CMake will ask you if you want to add that thing, say NO every time! I am already adding all of the things automatically!
If you accidentally say YES, just remove that file from the CMake.lists
</p>

<p>Refreshing your changes:<br>
After you add a file, the changes should be automatically added but if you want to be sure, you can refresh changes by saving the CMake file. If you want to make a hard refresh (you might have to do that sometimes) close Visual Studio, delete the out folder, reopen VS, <kbd>CTRL + S</kbd> on CMakeLists.txt</p>


# IMPORTANT!
  To ship the game: 
  In Cmakelists.txt, set the PRODUCTION_BUILD flag to ON to build a shippable version of your game. This will change the file paths to be relative to your exe (RESOURCES_PATH macro), will remove the console, and also will change the asserts to not allow people to debug them. To make sure the changes take effect I recommend deleting the out folder to make a new clean build!


  Also, if you read the CMAKE, even if you don't know CMAKE you should understand what happens with the comments there and you can add libraries and also remove the console from there if you need to! (there is a commented line for that!)


# NEW INFO
# raylib CMake Template

A batteries-included C++20 project template that handles all the boilerplate of linking [raylib](https://www.raylib.es/), [Dear ImGui](https://github.com/ocornut/imgui) (docking branch), and [rlImGui](https://github.com/raylib-extras/rlImGui) statically via CMake. Clone, configure, and start writing game code immediately.

Based on [meemknight/raylibCmakeSetup](https://github.com/meemknight/raylibCmakeSetup).

---

## Table of Contents

- [Project Structure](#project-structure)
- [How the Linking Works](#how-the-linking-works)
- [Dependencies](#dependencies)
- [Building](#building)
  - [Windows — Visual Studio 2022](#windows--visual-studio-2022)
  - [Windows — Command Line (MinGW/Ninja)](#windows--command-line-mingwninja)
  - [Linux](#linux)
  - [macOS](#macos)
- [Production Build](#production-build)
- [RESOURCES_PATH](#resources_path)
- [Editor Setup](#editor-setup)
  - [Visual Studio 2022](#visual-studio-2022)
  - [VSCode / VSCodium](#vscode--vscodium)
  - [CLion](#clion)
  - [Neovim (clangd)](#neovim-clangd)
- [Adding New Source Files](#adding-new-source-files)
- [Adding New Libraries](#adding-new-libraries)
- [FAQ](#faq)

---

## Project Structure

```
.
├── CMakeLists.txt              # Main build configuration
├── CMakeSettings.json          # Visual Studio CMake profile (Windows only)
├── .clangd                     # clangd LSP configuration (Neovim/Helix/etc.)
├── include/                    # Your project headers
├── src/                        # Your project source files (.cpp)
│   └── main.cpp
├── resources/                  # Game assets (textures, sounds, fonts, etc.)
└── thirdparty/
    ├── raylib-5.5/             # raylib source
    ├── imgui-docking/          # Dear ImGui (docking branch) source
    └── rlImGui/                # rlImGui source
```

---

## How the Linking Works

This template compiles all three libraries **from source** and links them **statically** into your executable. There are no `.dll` or `.so` files to ship alongside your game — everything ends up in a single binary.

### The CMake chain

```
your exe (ray_test)
  ├── raylib_static   ← compiled from thirdparty/raylib-5.5/
  ├── imgui           ← compiled from thirdparty/imgui-docking/
  └── rlimgui         ← compiled from thirdparty/rlImGui/
```

Each library is pulled in as a **CMake subdirectory**:

```cmake
add_subdirectory(thirdparty/raylib-5.5)
add_subdirectory(thirdparty/imgui-docking)
add_subdirectory(thirdparty/rlImGui)
```

`add_subdirectory` tells CMake to process that folder's own `CMakeLists.txt`, which defines its build targets. After this, those targets (`raylib_static`, `imgui`, `rlimgui`) become available in the parent scope.

Then they're linked into your executable with:

```cmake
target_link_libraries("${CMAKE_PROJECT_NAME}" PRIVATE
    raylib_static imgui rlimgui
)
```

`PRIVATE` means the libraries are linked but their include paths are not propagated to anything that links against your exe — appropriate since this is a final binary, not a library itself.

### Why static linking

`BUILD_SHARED_LIBS` is forced to `OFF`:

```cmake
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build Raylib as static libraries" FORCE)
```

This ensures raylib (and the other libs) don't produce `.dll`/`.so` files. The result is a self-contained executable you can copy and run anywhere without redistributing shared libraries.

### Include paths

Your own headers in `include/` are exposed via:

```cmake
target_include_directories("${CMAKE_PROJECT_NAME}" PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include/")
```

The third-party headers (raylib.h, imgui.h, rlImGui.h) are exposed transitively by each library's own `CMakeLists.txt` when you link against them. This is why you can write `#include "raylib.h"` in your source without manually specifying `-I` paths — CMake handles it.

### Source file discovery

All `.cpp` files under `src/` are picked up automatically:

```cmake
file(GLOB_RECURSE MY_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp")
```

`CONFIGURE_DEPENDS` tells CMake to re-scan this glob when you run a build, so adding a new `.cpp` file to `src/` is picked up without manually re-running `cmake`.

### Compile-time definitions

The CMakeLists sets several `#define`s that are available in your code:

| Macro | Value | Description |
|---|---|---|
| `RESOURCES_PATH` | Absolute path (dev) or `"./resources/"` (production) | Path to your assets folder |
| `PRODUCTION_BUILD` | `0` or `1` | Whether this is a production build |

Use them in code like:

```cpp
Texture2D tex = LoadTexture(RESOURCES_PATH "player.png");
```

### LTO (Link Time Optimization)

```cmake
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
```

This enables LTO globally, which allows the linker to optimize across translation units. It produces smaller, faster binaries at the cost of longer link times. It's active in all build types. If compile times become a problem during development you can temporarily set it to `FALSE`.

### MSVC-specific flags

When compiling with Visual Studio's compiler (`cl.exe`):

- AVX2 SIMD instructions are enabled (`/arch:AVX2`)
- The CRT is linked statically (`MultiThreaded` instead of `MultiThreadedDLL`) — this means you don't need to ship the Visual C++ Redistributable
- In production builds, the console window is hidden (`/SUBSYSTEM:WINDOWS /ENTRY:mainCRTStartup`)

---

## Dependencies

You need the following installed before building:

| Tool | Required | Notes |
|---|---|---|
| CMake | ≥ 3.30 | [cmake.org](https://cmake.org/download/) |
| A C++20 compiler | Yes | MSVC, GCC, or Clang |
| Ninja | Recommended | Faster builds, required for `compile_commands.json` on Windows |
| Git | For cloning | Submodules must be initialized |

The three libraries (raylib, imgui, rlImGui) are included directly in `thirdparty/` as part of the repo — no package manager needed.

---

## Building

### Windows — Visual Studio 2022

Open the folder directly in VS 2022 (File → Open → Folder). VS will detect `CMakeSettings.json` and configure automatically using the `x64-Debug` profile. Press F5 to build and run.

The `CMakeSettings.json` uses the `msvc_x64_x64` environment, meaning it compiles with `cl.exe` via the VS toolchain. Build output goes to `out\build\x64-Debug\`.

To switch to a release build, select the `x86-Release` configuration from the dropdown.

> **Note:** If you change the `PRODUCTION_BUILD` option, delete the `out/` folder before rebuilding. VS doesn't always detect this change and won't rebuild correctly otherwise.

### Windows — Command Line (MinGW/Ninja)

If you have MinGW (`gcc`/`g++`) and Ninja installed:

```powershell
# Configure
cmake -B build -S . -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# Build
cmake --build build

# Or directly with ninja
ninja -C build
```

The executable will be at `build/ray_test.exe`.

### Linux

Make sure you have the required system libraries:

```bash
# Debian/Ubuntu
sudo apt install libgl1-mesa-dev libx11-dev libxrandr-dev libxi-dev libxcursor-dev libxinerama-dev

# Arch
sudo pacman -S mesa libx11 libxrandr libxi libxcursor libxinerama
```

Then build:

```bash
cmake -B build -S . -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
cmake --build build
./build/ray_test
```

### macOS

```bash
cmake -B build -S . -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
cmake --build build
./build/ray_test
```

On macOS, raylib uses the Cocoa/OpenGL backend automatically. No extra system libraries needed beyond Xcode Command Line Tools.

---

## Production Build

To make a distributable build:

```bash
cmake -B build -S . -G Ninja -DPRODUCTION_BUILD=ON
cmake --build build --config Release
```

What changes in a production build:

- `RESOURCES_PATH` becomes `"./resources/"` (relative to the executable) instead of the absolute source path. You must ship the `resources/` folder next to the executable.
- `PRODUCTION_BUILD` is defined as `1` in your code, so you can `#if PRODUCTION_BUILD` to strip debug features.
- On MSVC, the console window is hidden.

> **Important:** After toggling `PRODUCTION_BUILD`, delete the build folder and reconfigure. CMake cached values may not reflect the change otherwise.

---

## RESOURCES_PATH

During development, `RESOURCES_PATH` expands to the absolute path of your `resources/` folder in the source tree. This means you can run the executable from any working directory and asset loading will still work.

In production, it becomes `"./resources/"`, so the folder must be next to the `.exe`. A typical distribution layout:

```
game/
├── ray_test.exe
└── resources/
    ├── textures/
    ├── sounds/
    └── fonts/
```

Use it in code like this:

```cpp
Texture2D tex  = LoadTexture(RESOURCES_PATH "textures/player.png");
Sound     shot = LoadSound(RESOURCES_PATH "sounds/shoot.wav");
```

---

## Editor Setup

### Visual Studio 2022

No setup needed. Open the folder, VS reads `CMakeSettings.json` and handles everything.

### VSCode / VSCodium

Install the **CMake Tools** extension. Open the folder, select a kit (MSVC or GCC) when prompted, and click Build. `compile_commands.json` is generated automatically if you add `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON` to the CMake configure args in the extension settings, or add it to `CMakeSettings.json`.

For IntelliSense, also install the **clangd** extension and point it at the `build/` folder.

### CLion

CLion detects `CMakeLists.txt` automatically. Set the CMake profile generator to Ninja in Settings → Build → CMake, and CLion will generate `compile_commands.json` and configure clangd on its own.

### Neovim (clangd)

clangd requires a `compile_commands.json` to understand your project. Generate it with:

```bash
cmake -B build -S . -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

> **Why Ninja?** The Visual Studio generator (`-G "Visual Studio 17 2022"`) does not support `CMAKE_EXPORT_COMPILE_COMMANDS`. Ninja does.

Then make `compile_commands.json` visible at the project root. Two options:

**Symlink (recommended — stays up to date automatically):**

```powershell
# Windows PowerShell (run as administrator, or enable Developer Mode)
New-Item -ItemType SymbolicLink -Path compile_commands.json -Target build\compile_commands.json
```

```bash
# Linux / macOS
ln -s build/compile_commands.json compile_commands.json
```

**Copy (simpler, but manual after CMake changes):**

```powershell
# Windows
cp build\compile_commands.json compile_commands.json
```

```bash
# Linux / macOS
cp build/compile_commands.json compile_commands.json
```

The `.clangd` file at the project root filters out GCC-specific flags that clangd doesn't understand (`-fmodules-ts`, `-fmodule-mapper`, etc.):

```yaml
CompileFlags:
  CompilationDatabase: build
  Remove:
    - "-fmodules-ts"
    - "-fmodule-mapper=*"
    - "-fdeps-format=*"
    - "-fno-fat-lto-objects"
    - "-flto=*"
```

Without this, clangd would report `unknown argument` errors even though the build itself works fine. These flags are GCC's C++ modules implementation details — clangd has its own and doesn't accept GCC's.

After setup, restart the LSP in Neovim:

```
:LspRestart
```

To rebuild after CMake changes:

```bash
cmake --build build
# if you used a symlink, compile_commands.json updates automatically
# if you copied, re-copy:
cp build\compile_commands.json compile_commands.json
```

---

## Adding New Source Files

Drop any `.cpp` file into `src/` (or a subfolder of `src/`). The `GLOB_RECURSE` in `CMakeLists.txt` picks it up on the next build automatically thanks to `CONFIGURE_DEPENDS`.

Headers can go in `include/` — that directory is already on the include path.

---

## Adding New Libraries

To add another library from source (same pattern as the existing ones):

1. Add it to `thirdparty/`
2. Add `add_subdirectory(thirdparty/yourlibrary)` in `CMakeLists.txt`
3. Add its target name to `target_link_libraries`:

```cmake
target_link_libraries("${CMAKE_PROJECT_NAME}" PRIVATE
    raylib_static imgui rlimgui yourlibrary_target_name
)
```

The target name depends on what the library's own `CMakeLists.txt` defines — check its source or documentation.

---

## FAQ

**Q: The project builds in VS but clangd shows errors in Neovim.**  
A: You need to generate `compile_commands.json` separately using the Ninja generator. See [Neovim setup](#neovim-clangd).

**Q: I changed `PRODUCTION_BUILD` and the build is wrong.**  
A: Delete the build folder entirely and reconfigure. CMake caches this value and VS in particular doesn't always detect the change.

**Q: Can I use this on Linux/macOS?**  
A: Yes. The CMake setup is cross-platform. On Linux you need a few system GL/X11 libraries (listed in the [Linux](#linux) section). The `CMakeSettings.json` is VS-specific and ignored on other platforms.

**Q: Do I need to ship any DLLs with the game?**  
A: No. Everything is linked statically. On Windows with MSVC, even the CRT is static, so no Visual C++ Redistributable is needed.

**Q: What's the `.cache/` folder?**  
A: That's clangd's local index cache. It's safe to delete and is regenerated automatically. It's already in `.gitignore`.
