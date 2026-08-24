// Your game. Ordinary raylib, and nothing else.
//
// The window, its size and its title are set right here, in code, because that
// is how raylib works and this template is not in the business of moving your
// decisions into a config file. The only thing it adds is RESOURCES_PATH, which
// CMake defines for you and which differs between a development build and a
// released one — see the README.
//
// There is no #if for the web. The `while` loop below runs in a browser too,
// because the web build links with -sASYNCIFY: see the note in CMakeLists.txt.

#include <raylib.h>

int main() {
    SetConfigFlags(FLAG_WINDOW_RESIZABLE);
    InitWindow(1280, 720, "My raylib game");
    SetTargetFPS(60);

    Texture2D rabbit = LoadTexture(RESOURCES_PATH "rabbit.png");

    while (!WindowShouldClose()) {
        BeginDrawing();
        ClearBackground(CLITERAL(Color){ 18, 18, 22, 255 });

        DrawTexture(rabbit, GetScreenWidth() / 2 - rabbit.width / 2,
                    GetScreenHeight() / 2 - rabbit.height / 2, WHITE);
        DrawFPS(20, 20);

        EndDrawing();
    }

    UnloadTexture(rabbit);
    CloseWindow();
    return 0;
}
