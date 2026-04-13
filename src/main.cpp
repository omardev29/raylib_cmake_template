#include <raylib.h>
#ifdef __ANDROID__
#include <raymob.h>
#endif

int main(void) {

#ifdef __ANDROID__
  Vibrate(2);
#endif

  SetConfigFlags(FLAG_WINDOW_RESIZABLE);
  InitWindow(800, 450, "raylib [core] example - basic window");

  while (!WindowShouldClose()) {
    BeginDrawing();
    ClearBackground(ALICEBLUE);
    DrawRectangle(300, 100, 100, 100, GIORNOGOLD);

    DrawText("Omar's raylib template!", 190, 200, 20, LIGHTGRAY);

    EndDrawing();
  }

  CloseWindow();

  return 0;
}
