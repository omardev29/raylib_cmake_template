# Third-party licences

Everything vendored in this repository, and the licence it ships under.

## raylib

`thirdparty/raylib/` — <https://github.com/raysan5/raylib>

zlib/libpng licence. Copyright (c) 2013-2026 Ramon Santamaria (@raysan5).
The full text is in `thirdparty/raylib/LICENSE`.

raylib bundles its own dependencies, each with a permissive licence of its own:
GLFW (zlib), RGFW (zlib), miniaudio (public domain / MIT-0), stb_image,
stb_image_write, stb_truetype, stb_rect_pack, stb_vorbis (public domain / MIT),
dr_mp3, dr_wav, dr_flac (public domain / MIT-0), qoi (MIT), rprand and rres
(zlib). Their notices are in `thirdparty/raylib/src/external/`.

Two local patches, both commented in place: a `Win32` value for `PLATFORM` in
`CMakeOptions.txt` and `cmake/LibraryConfigurations.cmake`, and the X11
extension libraries RGFW needs to link on Linux.

## raylib-cpp

`thirdparty/raylib-cpp/` — <https://github.com/RobLoach/raylib-cpp>, 6.0.3

zlib/libpng licence. Copyright (c) Rob Loach (@RobLoach). The full text is in
`thirdparty/raylib-cpp/LICENSE`. Only its headers (`include/`) are vendored,
unmodified.

## resources/rabbit.png

See `resources/License.txt`.
