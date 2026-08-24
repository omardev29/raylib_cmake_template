// Your game. This is ordinary raylib — there is no framework in the way.
//
// The only two things the template adds are the ones you would otherwise
// hardcode:
//
//   app_config.h    APP_WINDOW_TITLE and friends, generated from raylib.toml
//   RESOURCES_PATH  where resources/ is, which differs between a development
//                   build and a released one. CMake defines it for you.
//
// The `#if defined(PLATFORM_WEB)` split is not decoration. A browser cannot be
// blocked by a `while` loop: the page would freeze. Emscripten offers two ways
// out and this template takes the cheap one — hand the loop to the browser with
// emscripten_set_main_loop. The other one, `-s ASYNCIFY`, lets a real while
// loop work by instrumenting every function that might be on the stack when it
// suspends, and charges for it in download size and speed whether or not
// anything ever suspends.

#include <raylib.h>

#include <app_config.h>

<<<<<<< HEAD
  SetConfigFlags(FLAG_WINDOW_RESIZABLE);
  InitWindow(1280, 720, "a windoww loool");
  SetTargetFPS(FLAG_VSYNC_HINT);

  Texture2D rabbit = LoadTexture(RESOURCES_PATH "rabbit.png");
  while (!WindowShouldClose()) {

    BeginDrawing();

    DrawTexture(rabbit, 100, 800, BLACK);
    ClearBackground(BLACK);
    DrawText(TextFormat("windowww"), 500, 500, 26, WHITE);

    EndDrawing();
  }
  UnloadTexture(rabbit);
  CloseWindow();
=======
#if defined(PLATFORM_WEB)
#include <emscripten/emscripten.h>
#endif

static Texture2D rabbit;

// One frame. Everything you draw goes between BeginDrawing and EndDrawing.
static void frame() {
    BeginDrawing();
    ClearBackground(CLITERAL(Color){ 18, 18, 22, 255 });

    DrawTexture(rabbit, GetScreenWidth() / 2 - rabbit.width / 2,
                GetScreenHeight() / 2 - rabbit.height / 2, WHITE);
    DrawText(APP_WINDOW_TITLE, 24, 24, 24, RAYWHITE);
    DrawFPS(24, GetScreenHeight() - 34);

    EndDrawing();
}

int main() {
    SetConfigFlags(FLAG_WINDOW_RESIZABLE);
    InitWindow(APP_WINDOW_WIDTH, APP_WINDOW_HEIGHT, APP_WINDOW_TITLE);

    // RESOURCES_PATH comes from CMake, so this same line finds the file while
    // you develop and after you ship.
    rabbit = LoadTexture(RESOURCES_PATH "rabbit.png");

#if defined(PLATFORM_WEB)
    // 0 fps means requestAnimationFrame, which is what a browser wants — do
    // NOT call SetTargetFPS() here. The 1 is "simulate an infinite loop", so
    // main() never returns and nothing after this line runs.
    emscripten_set_main_loop(frame, 0, 1);
#else
    SetTargetFPS(60);
    while (!WindowShouldClose()) frame();

    UnloadTexture(rabbit);
    CloseWindow();
#endif
    return 0;
>>>>>>> 3fec2f4 (Un template de raylib, y solo eso)
}
