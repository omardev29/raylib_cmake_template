# Third-party licenses

Everything vendored in this repository, and the license it ships under.

## raylib

`thirdparty/raylib/` — <https://github.com/raysan5/raylib>

zlib/libpng license. Copyright (c) 2013-2026 Ramon Santamaria (@raysan5).
The full text is in `thirdparty/raylib/LICENSE`.

raylib bundles its own dependencies in `thirdparty/raylib/src/external/` —
GLFW, RGFW, miniaudio, the stb libraries, dr_libs, cgltf, par_shapes, qoi, qoa
and a few more — each under a permissive license of its own (zlib/libpng, MIT,
MIT-0, Apache-2.0 or public domain), whose notice is in its own file.

The vendored copy is upstream commit `c2ea6a3` (25 April 2026), two days after
the 6.0 release, without `examples/`, `projects/`, `tools/`, `logo/` and
`build.zig`. Its only local changes are marked `PATCHED`
(`grep -rn PATCHED thirdparty/raylib`): a `Win32` value for `PLATFORM` in
`CMakeOptions.txt` and `cmake/LibraryConfigurations.cmake`, the X11 extension
libraries RGFW needs to link on Linux, and, in `src/platforms/rcore_drm.c`, a
guard for the text console and no flow control while the game runs.

## raylib-cpp

`thirdparty/raylib-cpp/` — <https://github.com/RobLoach/raylib-cpp>, 6.0.3

zlib/libpng license. Copyright (c) Rob Loach (@RobLoach). The full text is in
`thirdparty/raylib-cpp/LICENSE`. Only its headers (`include/`) are vendored,
unmodified.

## resources/rabbit.png

See `resources/License.txt`.
