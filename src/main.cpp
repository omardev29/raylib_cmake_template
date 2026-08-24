#include <raylib.h>

int main() {

  SetConfigFlags(FLAG_WINDOW_RESIZABLE);
  InitWindow(1280, 720, "a windoww loool");
  while (!WindowShouldClose()) {
    BeginDrawing();
    ClearBackground(BLACK);
    DrawText(TextFormat("windowww"), 500, 500, 26, WHITE);
    EndDrawing();
  }
  CloseWindow();
}
