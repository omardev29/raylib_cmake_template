#include <raylib.h>

int main() {

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
}
