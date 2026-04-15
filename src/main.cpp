#include <raylib.h>
#include <raymob.h>
#include <test.h>

int main() {

  const int screen_x{GetScreenWidth()};
  const int screen_y{GetScreenHeight()};
  UnloadImage(imagen);

#ifdef __ANDROID__
  Vibrate(2);
#endif

  SetConfigFlags(FLAG_WINDOW_RESIZABLE);
  InitWindow(800, 450, "raylib [core] example - basic window");

  while (!WindowShouldClose()) {
    BeginDrawing();
    ClearBackground(ALICEBLUE);

    DrawTexture(textura, screen_x / 2 - textura.width / 2,
                screen_y / 2 - textura.height / 2, WHITE);

    DrawText("Omar's raylib template!", 190, 200, 20, LIGHTGRAY);

    EndDrawing();
  }
  UnloadTexture(textura);
  CloseWindow();

  return 0;
}
