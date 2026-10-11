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
just run          # builds what changed, then plays
```

Or without `just`, which is all it does:

```bash
cmake --preset debug
cmake --build --preset debug --target run
```

`just` on its own lists everything. There are seven recipes and that is the
whole documentation:

| | |
|---|---|
| `just run` | build what changed, then play |
| `just dev` | compile the debug build, into `build/` |
| `just rel` | compile the build you ship, into `build/release/` |
| `just web` | compile for the browser, into `build/web/` |
| `just fmt` | format `src/` and `include/` (`just fmt check` only reports) |
| `just lint` | clang-tidy over `src/`, failing on any warning |
| `just clean` | delete every build |

Each recipe is one or two CMake commands, so the `Justfile` doubles as a cheat
sheet.

**You need** CMake 3.25 or newer (Ubuntu 24.04's is fine), Ninja and a C/C++
compiler; [`just`](https://just.systems) is optional. On Debian and Ubuntu,
raylib also needs the X11 headers:

```bash
sudo apt install libx11-dev libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev libgl-dev
```

## The config

`config.cmake` is the only non-code file you edit, and it is deliberately short.
**Anything you can set with a raylib call is not in there** — the window size
and its title are arguments to `InitWindow()`, so that is where they live. What
is left is the handful of things CMake has to know before your code exists:

```cmake
set(GAME_NAME "game")            # the executable, and the CMake target
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

- `GAME_NAME` → the CMake project and the executable. `just run` goes through a
  CMake `run` target, so it follows a rename on its own.
- `RAYLIB_DISABLED_MODULES` → those modules are compiled out of raylib. A game
  with no sound drops `raudio`, and miniaudio with it.
- `WINDOWS_BACKEND`, `LINUX_BACKEND`, `LINUX_WAYLAND` → the window backend raylib
  is built on. GLFW everywhere by default; `win32` is raylib's own native Windows
  backend; RGFW is smaller and younger. Switching is safe in an existing build:
  the choice is worked out again on every configure.
- `DEV_COMPILER`, `DEV_LINKER` → your local compiler and linker, **debug preset
  only**. `release` and `web` build in directories of their own with the
  platform's defaults, so nothing here can change what you ship. `mold` is worth
  having on PATH on Linux; it makes the link almost free. Going back to
  `DEV_COMPILER "default"` needs a `just clean` — CMake cannot un-pick a
  compiler, and the build tells you so instead of quietly keeping the old one.

## Resources

Put files in `resources/` and load them with `RESOURCES_PATH`:

```cpp
Texture2D player = LoadTexture(RESOURCES_PATH "player.png");
```

CMake defines that macro, and it differs between build types on purpose: in a
development build it is an **absolute** path, so the game finds its assets
whatever directory you launch it from; in a `release` build it is
`./resources/`, and the build copies `resources/` next to the executable. The
web build bundles it into a `.data` file next to the page.

## The three targets

**Linux and Windows** are the same command on each machine. There is no
cross-compilation here: you build Windows on Windows.

```bash
just rel          # or: cmake --preset release && cmake --build --preset release
```

`build/release/` then holds the executable and its `resources/`: that folder is
what you ship. A Windows release has no console window behind the game, and runs
on a machine with nothing installed — the static C runtime with MSVC, and
`-static` with MinGW, so there is no `libstdc++-6.dll` to forget.

**The web** needs the [emsdk](https://emscripten.org/docs/getting_started/downloads.html)
activated:

```bash
just web
cmake --build --preset web --target run   # emrun serves it and opens your browser
```

Any static file server will do instead of emrun
(`python3 -m http.server 8000 --directory build/web`). Do not open the `.html`
from the filesystem: the browser will refuse to load the `.data` file next to
it.

### The web changes nothing about your code

That is the point, and it is bought deliberately. `while (!WindowShouldClose())`
runs in a browser here — there is no `#if` in `src/main.cpp` and there does not
need to be one in yours.

It works because the web build links with **`-sASYNCIFY`**. A browser cannot be
blocked, so the loop has to yield; raylib's `WindowShouldClose()` does that with
`emscripten_sleep()`, and ASYNCIFY is what makes a sleep inside a normal
function possible. It instruments every function that could be on the stack when
that happens — most of them — and you pay in download size (roughly +25 % on the
`.wasm`, measured) and a little speed, whether or not anything ever suspends.

That trade is right for this template and wrong for a bigger one. If you are
shipping to phones and the download matters, the other road is
`emscripten_set_main_loop()` plus an `#if` in `main()`, which is what
[raylib_multiplatform](https://github.com/omardev29/raylib_multiplatform) does.
Here, staying plain matters more.

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

## Layout

```
config.cmake            your settings — the only non-code file you edit
CMakeLists.txt          the build, written to be read top to bottom
cmake/                  DEV_COMPILER and DEV_LINKER, the two fiddly parts
src/main.cpp            your game. Every .cpp and .c under src/ is compiled
include/                your headers
resources/              your assets
thirdparty/raylib/      raylib 6.0, vendored and built statically
thirdparty/raylib-cpp/  raylib-cpp's headers, there if you want them
Justfile                the seven commands above
```

Adding a source file needs **no CMake edit** — `src/` is globbed recursively,
and the build notices a new file on its own. Adding a *library* does: one
`add_subdirectory` and one name in `target_link_libraries`, both in the
"your game" section of `CMakeLists.txt`.

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
- **Targets and their scopes.** `PRIVATE`, `SYSTEM` (raylib's headers count as
  system headers in your code, which keeps your warnings and clang-tidy about
  your code) and `target_compile_definitions` on `raylib` from the outside.
- **Generator expressions.** `$<CONFIG:Debug>` picks the MSVC runtime per
  configuration; `$<TARGET_FILE_DIR:...>` is where the executable ends up.
- **Presets.** `CMakePresets.json` is the three builds; each one gets its own
  directory, so switching between them never rebuilds the others.

## What this is not

This template is deliberately small. If you want fourteen build targets from
one codebase — Android, iOS, macOS, the BSDs — with CI that boots each one and
checks it drew something, plus a UI layer, an asset packer and an ads layer,
that is a different project:
[raylib_multiplatform](https://github.com/omardev29/raylib_multiplatform).

This one is for when you just want to write raylib.

## Licence

This template is under the [MIT licence](LICENSE). raylib and raylib-cpp are
under zlib; see [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md) for what is
vendored.
