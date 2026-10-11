# config.cmake — what the BUILD needs to know, in one place.
#
# Plain CMake: CMakeLists.txt reads this file before anything else, and each
# setting is one set(NAME value). Edit it and build — CMake notices the change
# and reconfigures on its own.
#
# Deliberately short. Anything you can set with a raylib call belongs in your
# code, not here: the window size and its title are arguments to InitWindow().
# What is left is the handful of things CMake has to know before your code
# exists.

# The executable's name, and the CMake target's. Letters, digits, _ and -.
set(GAME_NAME "game")

# raylib modules you do not use, e.g. set(RAYLIB_DISABLED_MODULES raudio rmodels)
#   rshapes  rtextures  rtext  rmodels  raudio
# rcore and rlgl are mandatory and are not listed on purpose; rtext needs
# rtextures, so dropping rtextures means dropping rtext too. A disabled module's
# functions are gone, so your code cannot call them. The win is mostly build
# time and dependencies: a game with no sound drops raudio, and miniaudio with
# it. The released binary changes less than you would think, because its linker
# already drops whatever nothing calls.
set(RAYLIB_DISABLED_MODULES "")

# The window backend raylib is built on, per system.
#
#   WINDOWS_BACKEND  glfw | win32 | rgfw
#   LINUX_BACKEND    glfw | rgfw
#
# glfw is the default and the safe choice. win32 is raylib's own native backend,
# with no GLFW at all. win32 and rgfw are smaller and younger: gamepads,
# multi-monitor and the clipboard are thinner — fine for a simple game, wrong as
# a default. On Linux, rgfw is X11-only.
set(WINDOWS_BACKEND "glfw")
set(LINUX_BACKEND "glfw")

# Linux with glfw: ON | OFF.
#   OFF  builds GLFW against X11, so on a Wayland desktop the game runs through
#        XWayland — an extra hop, and the reason fractional scaling and
#        per-monitor DPI misbehave there.
#   ON   builds GLFW's native Wayland backend instead, and needs libwayland-dev,
#        wayland-protocols and libxkbcommon-dev. Wayland has no window position,
#        by design: GetWindowPosition() and SetWindowPosition() do not work there.
set(LINUX_WAYLAND OFF)

# Your machine, for the debug preset only. The release and web presets always
# build with the platform's defaults, so nothing here can change what you ship.
#
#   DEV_COMPILER  default | clang | gcc | mingw | msvc
#                 mingw looks for MSYS2's x86_64-w64-mingw32-gcc before a plain
#                 gcc. mingw and msvc refuse to run off Windows.
#
#   DEV_LINKER    auto | mold | lld | default
#                 auto tries mold, then lld, keeps the first one that actually
#                 links, and otherwise uses the system linker: it is a speed
#                 setting, so it never fails a build. mold is Linux and the BSDs
#                 only — it writes ELF and nothing else. lld works wherever the
#                 toolchain can reach it. On macOS the system linker is already
#                 fast, and MSVC always uses its own.
set(DEV_COMPILER "default")
set(DEV_LINKER "auto")
