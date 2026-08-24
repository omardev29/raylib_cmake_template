# raylib_cmake_template

A raylib starter that gets out of your way. **raylib, statically linked, a CMake
build, and one config file** — and three targets you build from your own
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
just run          # builds if it has to, then plays
```

Or without `just`:

```bash
cmake --preset debug
cmake --build build
./build/game
```

`just` on its own lists everything. There are eight recipes and that is the
whole documentation:

| | |
|---|---|
| `just run` | play the game |
| `just dev` | compile the debug build |
| `just rel` | compile the build you ship |
| `just web` | compile for the browser |
| `just test` | the config is valid and everything compiles |
| `just fmt` | format `src/` and `include/` |
| `just lint` | clang-tidy over `src/` |
| `just clean` | delete the build and everything generated |

## The config

`raylib.toml` is the only non-code file you edit, and it is deliberately short.
**Anything you can set with a raylib call is not in there** — the window size
and its title are arguments to `InitWindow()`, so that is where they live. What
is left is the handful of things CMake has to know before your code exists.

```toml
[project]
name = "game"          # the binary's name, and the CMake target

[raylib]
disabled_modules = []  # rshapes | rtextures | rtext | rmodels | raudio

[dev]
compiler = "default"   # clang | gcc | default
linker   = "auto"      # auto (mold > lld > system) | mold | lld | default
```

Every value becomes something the build or your code can use, and **nothing
generated is committed**, so it cannot drift out of sync:

- `[project] name` → the CMake project and the executable. `just run` follows a
  rename on its own.
- `[raylib] disabled_modules` → modules you do not use are compiled out. A game
  with no sound drops `raudio` and its whole audio backend.
- `[dev]` → your local compiler and linker. **Development builds only**: the
  `release` and `web` presets are untouched by it, so nothing here can change
  what you ship. `mold` is worth having on PATH; it makes the link almost free.

`cmake --preset debug` regenerates all of it. You never run the generator by
hand.

## Resources

Put files in `resources/` and load them with `RESOURCES_PATH`:

```cpp
Texture2D player = LoadTexture(RESOURCES_PATH "player.png");
```

CMake defines that macro, and it differs between build types on purpose: in a
development build it is an **absolute** path, so the game finds its assets
whatever directory you launch it from; in a `release` or `web` build it is
`./resources/`, and you ship the folder next to the executable.

## The three targets

**Linux and Windows** are the same two commands on each machine. There is no
cross-compilation here: you build Windows on Windows.

```bash
cmake --preset release && cmake --build build
```

The Windows release links the static CRT, so the `.exe` runs on a machine with
no Visual C++ redistributable, and uses `/SUBSYSTEM:WINDOWS` so there is no
console window behind the game.

**The web** needs the [emsdk](https://emscripten.org/docs/getting_started/downloads.html)
on your PATH:

```bash
just web
python3 -m http.server 8000 --directory build/web
```

Serve it — do not open the `.html` from the filesystem, the browser will refuse
to load the `.data` file next to it.

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

## Layout

```
raylib.toml          your configuration — the only non-code file you edit
src/main.cpp         your game. Every .cpp and .c under src/ is compiled
include/             your headers
resources/           your assets
thirdparty/raylib/   raylib, vendored and built statically
tools/configure.py   turns the .toml into the CMake inputs and the header
cmake/               the configure hook, and cmake/generated/ (not committed)
Justfile             the eight commands above
```

Adding a source file needs **no CMake edit** — `src/` is globbed recursively,
and the build notices a new file on its own. Adding a *library* does: one
`add_subdirectory` and one name in `target_link_libraries`, both at the bottom
of `CMakeLists.txt`.

## What this is not

This template is deliberately small. If you want fourteen build targets from
one codebase — Android, iOS, macOS, the BSDs — with CI that boots each one and
checks it drew something, plus a UI layer, an asset packer and an ads layer,
that is a different project:
[raylib_multiplatform](https://github.com/omardev29/raylib_multiplatform).

This one is for when you just want to write raylib.

## Licence

This template is under the [zlib licence](LICENSE), the same as raylib. See
[THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md) for what is vendored.
