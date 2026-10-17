# Third-party licenses

Everything vendored in this repository, and the license it ships under.

## raylib

`thirdparty/raylib/` — <https://github.com/raysan5/raylib>

zlib/libpng license. Copyright (c) 2013-2026 Ramon Santamaria (@raysan5).
The full text is in `thirdparty/raylib/LICENSE`.

raylib bundles its own dependencies in `thirdparty/raylib/src/external/` —
GLFW, RGFW, miniaudio, the stb libraries, dr_libs, cgltf, par_shapes, qoi, qoa,
pep and a few more — each under a permissive license of its own (zlib/libpng,
MIT, MIT-0, Apache-2.0, CC0 or public domain), whose notice is in its own file.

The vendored copy is raylib 6.2, as tagged on 15 October 2026 (`02566453`),
without `.github/`, `examples/`, `projects/`, `tools/`, `logo/`, `build.zig` and
`build.zig.zon`. Its only local changes are marked `PATCHED`
(`grep -rn PATCHED thirdparty/raylib`): the Xrandr library RGFW needs to link
on Linux; in `src/platforms/rcore_drm.c`, a guard for the text console and no
flow control while the game runs; fixes for what raylib's security audit left
open, in `src/external/tinyobj_loader_c.h`, `src/rcore.c` and
`src/platforms/rcore_web.c`; and three of raylib's own fixes from after 6.2,
brought back, in `src/external/tinyobj_loader_c.h` and `src/rtextures.c`.
README.md, "Updating raylib", lists them.

## raylib-cpp

`thirdparty/raylib-cpp/` — <https://github.com/RobLoach/raylib-cpp>, 6.0.3

zlib/libpng license. Copyright (c) Rob Loach (@RobLoach). The full text is in
`thirdparty/raylib-cpp/LICENSE`. Only its headers (`include/`) are vendored,
with one change marked `PATCHED` in `include/Functions.hpp`: `ChangeDirectory()`
returns true on success with raylib 6.2 too.

## resources/rabbit.png

See `resources/License.txt`.
