#include <raylib.h>
#ifdef __ANDROID__

#include <raymob.h>
#endif // __ANDROID__
#include <test.h>

int main() {

#ifdef __ANDROID__
  Vibrate(2);
#endif

  SetConfigFlags(FLAG_WINDOW_RESIZABLE);
  InitWindow(800, 450, "raylib [core] example - basic window");

  GameAssets assets = LoadGameAssets();

  while (!WindowShouldClose()) {
    int screen_x = GetScreenWidth();
    int screen_y = GetScreenHeight();

    BeginDrawing();
    ClearBackground(ALICEBLUE);

    DrawTexture(assets.rabbit, screen_x / 2 - assets.rabbit.width / 2,
                screen_y / 2 - assets.rabbit.height / 2, WHITE);

    DrawText("Omar's raylib template!", 190, 200, 20, LIGHTGRAY);

    EndDrawing();
  }
  UnloadTexture(assets.rabbit);
  UnloadImage(assets.img);
  CloseWindow();

  return 0;
}
