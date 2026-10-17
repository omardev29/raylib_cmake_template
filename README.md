# raylib_cmake_template

A raylib starter that gets out of your way. **raylib, statically linked, a CMake
build, and one short config file** — and three targets you build from your own
machine: **Windows, Linux and the web.**

There is no framework layer here. You write ordinary raylib:

```cpp
#include <raylib.h>

int main() {
    InitWindow(1280, 720, "My raylib game");
    SetTargetFPS(60);

    Texture2D rabbit = LoadTexture(RESOURCES_PATH "rabbit.png");

    while (!WindowShouldClose()) {
        BeginDrawing();
        ClearBackground(BLACK);
        DrawTexture(rabbit, 100, 100, WHITE);
        EndDrawing();
    }
    CloseWindow();
}
```

## Start

```bash
make run          # compiles what changed, then plays
```

Or without make, which is all it does:

```bash
cmake --preset debug
cmake --build --preset debug --target run
```

| | |
|---|---|
| `make` | compile the debug build, into `build/` |
| `make run` | compile what changed, then play |
| `make rel` | compile the build you ship, into `build/release/` |
| `make web` | compile for the browser, into `build/web/` |
| `make serve` | play the web build: emrun serves it and opens your browser |
| `make clean` | delete every build |

Every recipe is a single CMake command, so the `Makefile` doubles as a cheat
sheet. make configures only when a build directory is new or
`CMakePresets.json` changed; what to compile is up to Ninja, underneath CMake,
which compares every source, header and compiler flag with what it built last.
So `make run` after an edit compiles just what the edit touched and plays, and
with no edit it plays straight away.

## Setting up

You need CMake 3.25 or newer, Ninja, a C/C++ compiler and, for the commands
above, make — any make: GNU make, the old one macOS ships, or BSD make.

### Linux

A compiler and make, CMake and Ninja, and the X11 and OpenGL headers raylib
builds against. One line per family of distributions:

**Debian and Ubuntu**, and those built on them: Mint, Pop!_OS, and the Ubuntu
that WSL installs.

```bash
sudo apt install build-essential cmake ninja-build \
    libx11-dev libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev libgl-dev
```

**Fedora**:

```bash
sudo dnf install gcc gcc-c++ make cmake ninja-build \
    libX11-devel libXrandr-devel libXinerama-devel libXcursor-devel \
    libXi-devel mesa-libGL-devel
```

**Arch**, and those built on it: Manjaro, EndeavourOS. Arch's packages carry
their own headers, so there are no `-dev` names:

```bash
sudo pacman -S --needed base-devel cmake ninja \
    libx11 libxrandr libxinerama libxcursor libxi mesa
```

**openSUSE**, Tumbleweed and Leap 16:

```bash
sudo zypper install gcc gcc-c++ make cmake ninja \
    libX11-devel libXrandr-devel libXinerama-devel libXcursor-devel \
    libXi-devel Mesa-libGL-devel
```

**Alpine**, whose C library is musl rather than glibc — which raylib does not
mind: Alpine packages raylib and GLFW itself. `samurai` is Alpine's Ninja, and
`linux-headers` is there because GLFW's gamepad code includes kernel headers
that musl does not ship:

```bash
doas apk add build-base cmake samurai linux-headers \
    libx11-dev libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev mesa-dev
```

`LINUX_WAYLAND ON` needs a few more on top: the Wayland libraries, xkbcommon
for the keyboard, and pkg-config, which GLFW uses to find them. Arch's
`base-devel` and Alpine's `-dev` packages bring pkg-config already.

| | `LINUX_WAYLAND ON` also needs |
|---|---|
| Debian, Ubuntu | `libwayland-dev libxkbcommon-dev pkg-config` |
| Fedora | `wayland-devel libxkbcommon-devel pkgconf-pkg-config` |
| Arch | `wayland libxkbcommon` |
| openSUSE | `wayland-devel libxkbcommon-devel pkg-config` |
| Alpine | `wayland-dev libxkbcommon-dev` |

`LINUX_BACKEND "drm"`, for a text console with no desktop ("A text console
(DRM)" below), needs libdrm, GBM, EGL and OpenGL ES, and libatomic, which raylib
links there:

| | `LINUX_BACKEND "drm"` also needs |
|---|---|
| Debian, Ubuntu | `libdrm-dev libgbm-dev libegl-dev libgles-dev` |
| Fedora | `libdrm-devel mesa-libgbm-devel mesa-libEGL-devel libatomic` |
| Arch | nothing more: `mesa` brings them |
| openSUSE | `libdrm-devel libgbm-devel Mesa-libEGL-devel Mesa-libGLESv2-devel libatomic1` |
| Alpine | `libatomic`, as `mesa-dev` brings the rest |

Every current release of these ships CMake 3.25 or newer, except Ubuntu 22.04
(3.22), where `pip install cmake` gets a current one.

### macOS

The compiler and make come with Apple's command line tools, and CMake and Ninja
with [Homebrew](https://brew.sh):

```bash
xcode-select --install
brew install cmake ninja
```

That make is GNU make 3.81, from 2006, and the Makefile works with it. macOS is
not one of this template's three targets, but raylib supports it and the build
handles it.

### Windows

Each of these builds a native `.exe`, and the Makefile works in all of them,
typed in cmd.exe, PowerShell or MSYS2's shell alike: its recipes are cmake
commands and nothing else.

**Scoop and MinGW**, the shortest road. With [Scoop](https://scoop.sh):

```powershell
scoop install make cmake ninja mingw
make run
```

`mingw` is GCC for Windows.

**Visual Studio (MSVC).** Install Visual Studio, or just its Build Tools, with
the "Desktop development with C++" workload, which brings CMake and Ninja too.
Open **Developer PowerShell for VS** — that is what puts the compiler on PATH —
and run `make run` (after `scoop install make`) or the two cmake commands from
Start. Visual Studio can also open the folder directly, because it reads
`CMakePresets.json`.

**MSYS2.** In the **MSYS2 UCRT64** shell:

```bash
pacman -S --needed make mingw-w64-ucrt-x86_64-gcc \
    mingw-w64-ucrt-x86_64-cmake mingw-w64-ucrt-x86_64-ninja
make run
```

Use the UCRT64 shell and the `mingw-w64-ucrt-x86_64-` packages, which build
Windows programs. MSYS2's plain `cmake` package builds for MSYS2's own POSIX
layer instead of for Windows, which is not what you want.

**WSL.** Inside WSL you are on Linux, so you install what that distribution
needs — WSL's default is Ubuntu, so the Debian and Ubuntu line above — and
`make run` builds and runs the Linux version of the game, not a `.exe`. Its
window needs a display server, and current WSL comes with one: WSLg, on Windows
11 and on Windows 10 with WSL from the Microsoft Store (`wsl --update`). It
speaks both X11 and Wayland, so there is nothing else to install. An older WSL
needs an X server such as VcXsrv, with `DISPLAY` pointing at it. Keep the
project in WSL's own file system (under `~`), not under `/mnt/c`, where builds
are several times slower. For the `.exe`, use one of the ways above.

## The config

`config.cmake` is the only non-code file you edit, and it is deliberately short.
**Anything you can set with a raylib call is not in there** — the window size
and its title are arguments to `InitWindow()`, so that is where they live. What
is left is the handful of things CMake has to know before your code exists:

```cmake
set(GAME_NAME "game")            # the executable, and the CMake target
set(CMAKE_C_STANDARD 17)         # 99 | 11 | 17 | 23
set(CMAKE_CXX_STANDARD 20)       # 11 | 14 | 17 | 20 | 23 | 26
set(RAYLIB_DISABLED_MODULES "")  # any of: rshapes rtextures rtext rmodels raudio
set(WINDOWS_BACKEND "glfw")      # glfw | win32 | rgfw
set(LINUX_BACKEND "glfw")        # glfw | rgfw
set(LINUX_WAYLAND OFF)           # ON: GLFW's native Wayland backend
set(DEV_COMPILER "default")      # default | clang | gcc | mingw | msvc
set(DEV_LINKER "auto")           # auto | mold | lld | default
```

It is plain CMake, read by `CMakeLists.txt` before anything else. Edit it and
build: CMake notices the change and reconfigures on its own. There is no
generator and no other step, and every value is checked when CMake configures —
a typo stops the build with a message that names the setting.

- `GAME_NAME` → the CMake project and the executable. `make run` goes through a
  CMake `run` target, so it follows a rename on its own.
- `CMAKE_C_STANDARD`, `CMAKE_CXX_STANDARD` → the language standards your code is
  compiled with. See below.
- `RAYLIB_DISABLED_MODULES` → those modules are compiled out of raylib, so their
  functions are gone. A game with no sound drops `raudio`, and miniaudio with
  it. `rtext` needs `rtextures`: dropping `rtextures` means dropping both.
- `WINDOWS_BACKEND`, `LINUX_BACKEND`, `LINUX_WAYLAND` → the window backend raylib
  is built on. GLFW everywhere by default; `win32` is raylib's own native Windows
  backend, still young (`config.cmake` says what it lacks); RGFW is smaller and
  younger; `drm` runs on a text console with no desktop at all ("A text console
  (DRM)"). Switching is safe in an existing build: the choice is worked out
  again on every configure.
- `DEV_COMPILER`, `DEV_LINKER` → your local compiler and linker, **debug preset
  only**. `release` and `web` build in directories of their own with the
  platform's defaults, so nothing here can change what you ship. `mold` is worth
  having on PATH on Linux; it makes the link almost free. Going back to
  `DEV_COMPILER "default"` needs a `make clean` — CMake cannot un-pick a
  compiler, and the build tells you so instead of quietly keeping the old one.

### C and C++ standards

`CMAKE_C_STANDARD` and `CMAKE_CXX_STANDARD` are CMake's own variables: they set
the standard of every target that does not choose one itself — your game, and
any library you add. raylib and GLFW are C99 code and pin that themselves, so
these never reach them. You get exactly what you ask for, in the GNU flavor on
GCC and Clang (`-std=gnu++20`, CMake's default); if the compiler cannot do it,
the configure stops with CMake's own message rather than quietly using an older
standard.

| | GCC | Clang | MSVC | Emscripten |
|---|---|---|---|---|
| C 99, 11, 17 | yes | yes | yes (11 and 17 from VS 2019 16.8) | yes |
| C 23 | yes | yes | CMake 4.2+ and VS 2022 17.9+ | yes |
| C++ 11, 14, 17, 20 | yes | yes | yes (20 from VS 2019 16.11; there is no C++11 mode, you get 14) | yes |
| C++ 23 | 11+ | 12+ | only as `/std:c++latest`, a preview | yes |
| C++ 26 | 14+, with CMake 3.30+ | 17+, with CMake 3.27+ | no | CMake 3.27+ |

The "yes" entries for GCC, Clang and Emscripten were checked with GCC 13 (and
MinGW's GCC 13), Clang 18 and Emscripten 6.0, in C and in C++, with raylib-cpp
too. GCC 13 stops at C++26, as the table says it should. The MSVC column is
CMake's own table.

Below C99 and C++11, `raylib.h` refuses to compile (under C++98 it stops with
`#error`), so `config.cmake` does not accept them. raylib-cpp works from C++11
up. If you are unsure, keep the defaults, C17 and C++20: every compiler above
does them.

## Resources

Put files in `resources/` and load them with `RESOURCES_PATH`:

```cpp
Texture2D player = LoadTexture(RESOURCES_PATH "player.png");
```

CMake defines that macro, and it differs between build types on purpose: in a
development build it is an **absolute** path, so the game finds its assets
whatever directory you launch it from; in a `release` build it is
`./resources/`, and the build copies `resources/` next to the executable. The
web build bundles it into a `.data` file next to the page, and there it is
`./resources/` in every build. `PRODUCTION_BUILD` is defined too, `1` or `0`, if
your code needs to tell the two apart.

`./resources/` is relative to the folder the game was started in. Windows starts
a double-clicked program in its own folder, so there it just works. macOS's
Finder starts it in your home folder instead, and Linux file managers vary; if
you ship there, have the game move to its own folder first. raylib has both
halves of that, and it is one line at the top of `main()`:

```cpp
#if PRODUCTION_BUILD
    ChangeDirectory(GetApplicationDirectory());
#endif
```

## The three targets

**Linux and Windows** are the same command on each machine. There is no
cross-compilation here: you build Windows on Windows.

```bash
make rel          # or: cmake --preset release && cmake --build --preset release
```

`build/release/` then holds the executable and its `resources/`: that folder is
what you ship. A Windows release has no console window behind the game, and runs
on a machine with nothing installed — the static C runtime with MSVC, and
`-static` with MinGW, so there is no `libstdc++-6.dll` to forget. The copy of
`resources/` is refreshed on every build but never pruned: if you renamed or
deleted an asset since, `make clean` before `make rel`, or the old file ships
too.

**The web** needs the [emsdk](https://emscripten.org/docs/getting_started/downloads.html)
activated:

```bash
make web
make serve        # emrun serves it and opens your browser
```

Any static file server will do instead of emrun
(`python3 -m http.server 8000 --directory build/web`). Do not open the `.html`
from the filesystem: the browser will refuse to load the `.data` file next to
it.

### How optimized is a release build?

As far as a binary goes while it still runs on any machine of its kind:

| | Linux, MinGW, macOS | MSVC | Web |
|---|---|---|---|
| Optimization level | `-O3` | `/O2` | `-Oz`, for size |
| Link-time optimization | yes, where the toolchain supports it | yes | yes, full LTO |
| Unused code removed | `--gc-sections` (`-dead_strip` on macOS) | `/OPT:REF` | always |
| Symbols stripped | yes (not on macOS) | no `.pdb` in a release | yes |
| `assert()` | off | off | off |

raylib and GLFW get all of it too, not only your code. Measured on Linux, a
plain CMake Release build of this template is 1,225 KB once stripped, and the
`release` preset's is 451 KB; on the web, full LTO takes the `.wasm` from 127 KB
to 110 KB.

What is deliberately left off, because each one trades something away:

- **`-march=native`** builds for your CPU only; on an older one the game dies
  with an illegal instruction. If you know your players' machines,
  `-march=x86-64-v3` (AVX2: Intel from 2013, AMD from 2015) is the sensible
  step up: add it with `add_compile_options()` in the production part of
  `CMakeLists.txt`.
- **`-ffast-math`** speeds up floating point by breaking its rules (NaN,
  infinity, the order of operations), so results change.
- **Profile-guided optimization** needs a representative training run before
  every release. Worth it for a CPU-bound game; many raylib games are bound by
  the GPU and the frame cap instead.

## The web, and ASYNCIFY

`while (!WindowShouldClose())` runs in a browser here — there is no `#if` in
`src/main.cpp`, and there does not need to be one in yours. That is bought
deliberately, with **`-sASYNCIFY`**. A browser cannot be blocked, so the loop has
to yield; raylib's `WindowShouldClose()` does that with `emscripten_sleep()`, and
ASYNCIFY is what makes a sleep inside a normal function possible. It instruments
every function that could be on the stack when that happens — most of them — and
you pay in download size and a little speed, whether or not anything suspends.
Measured with this template: the `.wasm` is 110 KB with ASYNCIFY and 83 KB
without, a third more.

That trade is right for a template whose point is plain raylib. When the
download matters more, give the loop to the browser instead.

### The web without ASYNCIFY

Two changes: one in your code, one line in CMake. Nothing else in the build
depends on ASYNCIFY.

**1. `src/main.cpp`.** A frame becomes a function, and the web build hands it to
`emscripten_set_main_loop()`, which the browser then calls once per display
refresh:

```cpp
#include <raylib.h>
#if defined(__EMSCRIPTEN__)
#include <emscripten/emscripten.h>
#endif

// Everything a frame needs lives outside main(): on the web, main() hands the
// loop to the browser and its own locals are gone by the first frame.
static Texture2D rabbit;

static void UpdateDrawFrame() {
    BeginDrawing();
    ClearBackground(BLACK);
    DrawTexture(rabbit, (GetScreenWidth() - rabbit.width) / 2,
                (GetScreenHeight() - rabbit.height) / 2, WHITE);
    DrawFPS(20, 20);
    EndDrawing();
}

int main() {
    SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_VSYNC_HINT);
    InitWindow(1280, 720, "My raylib game");
    rabbit = LoadTexture(RESOURCES_PATH "rabbit.png");

#if defined(__EMSCRIPTEN__)
    // The browser calls UpdateDrawFrame once per display refresh (the 0), and
    // this call never returns (the 1).
    emscripten_set_main_loop(UpdateDrawFrame, 0, 1);
#else
    while (!WindowShouldClose()) {
        UpdateDrawFrame();
    }
#endif

    UnloadTexture(rabbit);
    CloseWindow();
}
```

**2. `CMakeLists.txt`.** In the web section, delete the `-sASYNCIFY` line.

That is all: this exact file was built for the web without ASYNCIFY and for
the desktop, and run in a browser and in a window. What changes in how you write
the game:

- **Never call `WindowShouldClose()` on the web path.** On the web, raylib's
  version yields with `emscripten_sleep()`, which only exists with ASYNCIFY.
  Call it anyway and the page stops with
  `Aborted(Please compile your program with async support in order to use asynchronous operations like emscripten_sleep)`.
- **State lives outside `main()`.** Globals or statics, as above, or a struct you
  pass with `emscripten_set_main_loop_arg()`. `main()` does not return the
  usual way — the call unwinds it — so its locals are gone. The same goes for
  raylib-cpp objects: create them after `InitWindow()`, for example inside a
  struct you allocate, not as globals built before `main()` starts.
- **No `SetTargetFPS()` on the web.** The browser paces the loop at the
  display's rate (the `0` in the call); raylib's frame limiter would busy-wait
  inside a frame instead.
- **Code after the call never runs in the browser.** No `UnloadTexture()` or
  `CloseWindow()` there, and nothing is lost: closing the tab frees everything.
  On the desktop it runs as before.

`__EMSCRIPTEN__` is defined by the compiler in every web build; raylib's own
`PLATFORM_WEB` works as well.

## A text console (DRM)

`LINUX_BACKEND "drm"` builds the game for Linux with no desktop running at all.
It takes over the whole screen of a text console through DRM/KMS, draws with
OpenGL ES 2.0, and reads the keyboard, mouse and gamepads straight from
`/dev/input`. That is how you develop on a machine with nothing but a console,
and how you ship to one: a kiosk, an arcade cabinet, a Raspberry Pi.

From a desktop, switch to a text console with **Ctrl+Alt+F3** (F2 to F6 work
too; the key your desktop is on, usually F1 or F2, brings it back), log in,
and:

```bash
make run          # compiles what changed, then plays on this console
```

It has to be a console: inside a desktop session the screen belongs to the
desktop, and the game cannot take it. A desktop left running on another console
is no problem.

**Permissions.** The game opens `/dev/dri/card*` for the screen and
`/dev/input/event*` for input, which a normal user cannot open. Either run it
with sudo — build as yourself, then `sudo build/game`, because `sudo make` would
leave files owned by root in `build/` — or add yourself to the groups that own
those devices, once, then log out and back in:

```bash
sudo usermod -aG video,input,render $USER
```

`video` is the screen, `input` the keyboard, mouse and gamepads, and `render`
the GPU on boards where it is a device of its own, like the Raspberry Pi. On
Alpine, it is `doas addgroup $USER video`, and the same for `input`. On
distributions with systemd, logging in at the console already lets you use the
screen and gamepads, but never the keyboard or mouse, so `input` is still
needed. While you are in `input`, every program you run can read every keyboard
on the machine: on a shared computer, prefer sudo.

**While it runs**, Esc quits, as raylib's default exit key (`SetExitKey()`
changes it), and Ctrl+C does nothing: raylib switches the console's signal keys
off. Nothing you type reaches the shell, however the game ends: Esc, a crash or
a kill. Next to the game, `ps` shows `raylib-console`, which minds the console
for it: it takes what the keyboard types into the console, and puts the console
back once the game is gone. It also lets only Ctrl+Alt+F1 to F12 switch to
another console, because Alt and an arrow, or Alt and an F key, would switch
too, and the game, which keeps the screen, would type its keys unseen into
whatever runs there.

**If the game hangs**, switch to another console with Ctrl+Alt+F2 and log in
without seeing what you type: the frozen game keeps the screen until it ends.
Then end it:

```bash
pkill -x game       # your GAME_NAME; pkill -9 -x game if it stays
```

or find it with `ps -u $USER` and `kill` its PID; `sudo pkill -x game` if it
runs with sudo. Leave `raylib-console` alone, as it puts the console back on its
way out — so not `kill -9 $(pidof game)`, which takes both. Ctrl+Alt+F3, or
whichever console the game was on, takes you back to the shell.

The game runs full screen, in the display mode closest to the size given to
`InitWindow()`; `InitWindow(0, 0, ...)` keeps the console's own. Shaders are
GLSL ES 1.00 (`#version 100`), the same as on the web. `make rel` builds a
release for the console like any other: run it from `build/release/`.

With more than one graphics card, raylib tries `/dev/dri/card1`, then `card0`
and `card2`. To pick one, add this to `CMakeLists.txt` after
`add_subdirectory(thirdparty/raylib SYSTEM)`:

```cmake
target_compile_definitions(raylib PRIVATE DEFAULT_GRAPHIC_DEVICE_DRM="/dev/dri/card0")
```

## raylib-cpp, if you want it

[raylib-cpp](https://github.com/RobLoach/raylib-cpp), the C++ wrapper, is
vendored and on the include path. Nothing uses it until you do, and it mixes
freely with plain raylib:

```cpp
#include <raylib-cpp.hpp>

int main() {
    raylib::Window window(1280, 720, "My raylib game");
    raylib::Texture rabbit(RESOURCES_PATH "rabbit.png"); // unloaded on its own

    while (!window.ShouldClose()) {
        window.BeginDrawing();
        window.ClearBackground(BLACK);
        rabbit.Draw(100, 100);
        window.EndDrawing();
    }
}
```

## Adding a library

`thirdparty/` is where vendored libraries live, but a folder there does nothing
by itself: CMake builds only what `CMakeLists.txt` names. Put the library in
`thirdparty/<name>/`, then add a few lines to the **your game** section of
`CMakeLists.txt`, next to raylib's. Which lines depends on what the library
ships.

**It has its own `CMakeLists.txt`** — most C and C++ libraries:

```cmake
set(SOMELIB_BUILD_TESTS OFF)                  # its options, if any, go first
add_subdirectory(thirdparty/somelib SYSTEM)
target_link_libraries(${GAME_NAME} PRIVATE somelib::somelib)
```

The target's name is in the library's README, or in its `CMakeLists.txt` as
`add_library(<name> ...)`, often with an alias like `somelib::somelib`. Linking
the target brings its headers along. `SYSTEM` keeps its warnings out of yours,
and `BUILD_SHARED_LIBS OFF` makes it a static library, so it ends up inside your
executable like raylib does.

**It is header-only** — raygui, raylib-cpp:

```cmake
target_include_directories(${GAME_NAME} SYSTEM PRIVATE thirdparty/raygui/src)
```

A single-header library like raygui carries its implementation inside the
header: define its switch before including it, in exactly one source file, and
include it normally everywhere else.

```cpp
// src/raygui.cpp
#define RAYGUI_IMPLEMENTATION
#include <raygui.h>
```

**It is just source files** — a `.c` and a `.h`, no build system:

```cmake
add_library(tinylib STATIC thirdparty/tinylib/tinylib.c)
target_include_directories(tinylib SYSTEM PUBLIC thirdparty/tinylib)
target_link_libraries(${GAME_NAME} PRIVATE tinylib)
```

Dropping them into `src/` and `include/` works too, since `src/` is globbed, but
then your `-Wall -Wextra` applies to someone else's code.

**A C library in C++ code.** Most C headers wrap themselves in `extern "C"`. If
one does not, the link fails on undefined symbols that carry a parameter list,
like `tiny_twice(int)`; wrap the include yourself:

```cpp
extern "C" {
#include <tinylib.h>
}
```

All three work for Linux, Windows (MinGW) and the web. If you would rather not
vendor, CMake's `FetchContent` downloads a library while it configures; this
template vendors so that a build never needs the network.

## Changing CMakeLists.txt

It is your build now, and all of it can change. Three rules of order are the
only things that are not negotiable:

1. **`project()` locks the compiler in.** Whatever picks a compiler goes before
   it (`cmake/dev_compiler.cmake`); whatever has to compile a test program —
   `check_linker_flag()`, `check_ipo_supported()` — goes after it.
2. **Settings that set up targets only reach targets created after them.** The
   `CMAKE_*` variables, `BUILD_SHARED_LIBS`, `add_compile_options()` and
   `add_link_options()` in the "for every target" section have to stay above
   `add_subdirectory()` and `add_executable()`.
3. **raylib reads its settings inside `add_subdirectory(thirdparty/raylib)`**, so
   `PLATFORM` and `GLFW_BUILD_*` are set before that line, and anything that
   changes the `raylib` target itself comes after it.

| Section | What it does | Changing it |
|---|---|---|
| top | reads `config.cmake`, checks it, defaults to a Debug build | New settings go in `config.cmake`, their checks in `cmake/check_config.cmake`. |
| toolchain | `DEV_COMPILER` and `DEV_LINKER` | Keep the order (rule 1). Never use them? Delete both includes, both files, and their settings and checks. |
| for every target | standards, static linking, the MSVC runtime, `compile_commands.json`, ccache, production optimization | Flags for every target go here (rule 2). ccache can go. |
| raylib | backend, Wayland, disabled modules, raylib's warnings | Tied to `config.cmake` and to raylib's own CMake — see "Updating raylib". |
| your game | sources, `include/`, libraries, warnings, MinGW `-static`, `RESOURCES_PATH`, no console on Windows, copying `resources/` | Where your additions go. Keep `RESOURCES_PATH` while your code uses it. |
| web | `.html` output, ASYNCIFY, memory, the resources bundle | ASYNCIFY is tied to `main.cpp` (see above); the bundle to `RESOURCES_PATH`. |
| run | the `run` target | Can go; then take `run` and `serve` out of the Makefile too. |

Some things look removable and are not:

- **`SYSTEM` on raylib and on raylib-cpp's include path.** Both are clean under
  `-Wall -Wextra` today, but add `-Wshadow` and, without `SYSTEM`, raylib-cpp's
  headers produce 326 warnings the moment you include them. raylib's own
  `SYSTEM` is the same insurance, for the next flag or compiler.
- **`_GLFW_WAYLAND`.** Without it, a Wayland build compiles raylib's own Wayland
  code out.
- **`-static` on MinGW**, and **`CMAKE_MSVC_RUNTIME_LIBRARY`**: without them the
  release needs DLLs that a player's machine does not have.

## Updating raylib

`thirdparty/raylib/` is raylib's own source, copied in: raylib 6.2, as tagged on
15 October 2026 (`02566453`), without `.github/`, `examples/`, `projects/`,
`tools/`, `logo/`, `build.zig` and `build.zig.zon`. Its only local changes, and
the one in raylib-cpp, are marked `PATCHED`:

```bash
grep -rn PATCHED thirdparty
```

| File | The change | It can go once raylib |
|---|---|---|
| `cmake/LibraryConfigurations.cmake` | links Xrandr, without which RGFW does not link on Linux | links it itself |
| `src/platforms/rcore_drm.c` | the console guard, and no flow control ("A text console (DRM)") | restores the console after a crash too, and turns flow control off |
| `src/external/tinyobj_loader_c.h` | drops an OBJ face of more than 16 vertices, which overflowed the stack | bounds that loop |
| `src/rcore.c` | drops a replayed automation event whose values are out of range | checks them in `PlayAutomationEvent()` |
| `src/platforms/rcore_web.c` | `OpenURL()` on the web refuses quotes and anything but `http(s)://`, as it does on the desktop | does the same in this backend |
| raylib-cpp's `Functions.hpp` | `raylib::ChangeDirectory()` returns true on success again | raylib-cpp follows raylib 6.2 |

The tinyobj, automation and `OpenURL()` ones close what raylib 6.2's security
audit left open: raylib says it addressed "most" of what the audit found.

To move to a newer raylib:

1. Download it: a release from <https://github.com/raysan5/raylib/releases>, or
   any commit.
2. **Delete `thirdparty/raylib/` first**, then copy the new one in, without the
   folders and files above. Copying over the old folder leaves behind every
   file the new version removed.
3. For each `PATCHED` block, check whether the new raylib still needs it, and
   re-apply it if so.
4. Build every preset you use — `make`, `make rel`, `make web` — and run them.
5. Update raylib-cpp too, once a release for the new raylib is out. It is
   header-only, so that is copying `include/`. Its version does not have to
   match raylib's: the 6.0.3 here works with raylib 6.2.

What `CMakeLists.txt` relies on, which is where a new raylib could break it:

| The build uses | Where it lives in raylib |
|---|---|
| a target called `raylib` | `src/CMakeLists.txt`, `add_library(raylib ...)` |
| `PLATFORM` values `Desktop`, `Web`, `RGFW`, `Win32`, `DRM` | `CMakeOptions.txt`, `enum_option(PLATFORM ...)` |
| the `GLFW_BUILD_WAYLAND` and `GLFW_BUILD_X11` options | `CMakeOptions.txt` |
| every `SUPPORT_MODULE_*` inside an `#ifndef` | `src/config.h` |
| raylib *not* defining `_GLFW_WAYLAND` for its own sources | `src/CMakeLists.txt` — if a new raylib does, the `_GLFW_WAYLAND` block in `CMakeLists.txt` can go |

raylib's CMake still builds an X11-only GLFW unless told otherwise, so
`LINUX_WAYLAND` still matters.

When a newer raylib makes one of these workarounds unnecessary, delete it: it is
your code now.

## Layout

```
config.cmake            your settings — the only non-code file you edit
CMakeLists.txt          the build, written to be read top to bottom
CMakePresets.json       the three builds: debug, release and web
cmake/                  check_config.cmake, and DEV_COMPILER and DEV_LINKER
src/main.cpp            your game. Every .cpp and .c under src/ is compiled
include/                your headers
resources/              your assets
thirdparty/raylib/      raylib 6.2, plus the changes marked PATCHED
thirdparty/raylib-cpp/  raylib-cpp's headers, there if you want them
Makefile                the six commands above
```

Adding a source file needs **no CMake edit**: `src/` is globbed recursively, and
the build notices a new file on its own.

## Learning CMake from it

`CMakeLists.txt` runs in the order CMake needs things, and the comments say why
at each step. The parts worth slowing down for:

- **Before and after `project()`.** The compiler is chosen before it, because
  `project()` is where CMake locks the compiler in (`cmake/dev_compiler.cmake`).
  The linker is chosen after it, because checking that a linker works means
  compiling a test program (`cmake/dev_linker.cmake`).
- **Normal variables and the cache.** raylib's `PLATFORM` is set as a plain
  variable, recomputed on every configure, so a backend you switched away from
  cannot linger. The compiler is the opposite case: only a cache entry set with
  `FORCE` can change it in an existing build.
- **Variables that set up targets.** `CMAKE_CXX_STANDARD`,
  `CMAKE_INTERPROCEDURAL_OPTIMIZATION` and friends set a property on every target
  created after them — which is why they come first, and why one line reaches
  raylib, GLFW and your game alike.
- **Targets and their scopes.** `PRIVATE`, `SYSTEM`, and
  `target_compile_definitions()` on `raylib` from the outside.
- **Generator expressions.** `$<CONFIG:Debug>` picks the MSVC runtime per
  configuration, `$<BOOL:...>` turns `ON`/`OFF` into the `1`/`0` your code
  sees, and `$<TARGET_FILE_DIR:...>` is where the executable ends up.
- **Presets.** `CMakePresets.json` is the three builds; each gets its own
  directory, so switching between them never rebuilds the others.

## What this is not

This template is deliberately small. If you want fourteen build targets from
one codebase — Android, iOS, macOS, the BSDs — with CI that boots each one and
checks it drew something, plus a UI layer, an asset packer and an ads layer,
that is a different project:
[raylib_multiplatform](https://github.com/omardev29/raylib_multiplatform).

This one is for when you just want to write raylib.

## License

This template is under the [MIT license](LICENSE). raylib and raylib-cpp are
under zlib; see [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md) for what is
vendored.
