#include <raylib.h>

int main() {
    SetConfigFlags(FLAG_WINDOW_RESIZABLE);
    InitWindow(1280, 720, "My raylib game");
    SetTargetFPS(60);

    Texture2D rabbit = LoadTexture(RESOURCES_PATH "rabbit.png");

    int screen_width{ GetScreenWidth() };
    int screen_height{ GetScreenHeight() };

    while (!WindowShouldClose()) {
        BeginDrawing();
        ClearBackground(BLACK);

        DrawTexture(rabbit, (screen_width / 2) - (rabbit.width / 2),
                    (screen_height / 2) - (rabbit.height / 2), WHITE);
        DrawFPS(screen_width / 16, screen_height / 16);

        EndDrawing();
    }

    UnloadTexture(rabbit);
    CloseWindow();
    return 0;
}
