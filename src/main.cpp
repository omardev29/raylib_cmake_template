#include "raylib.h"
#include <iostream>

int main(void)
{

	SetConfigFlags(FLAG_WINDOW_RESIZABLE);
	InitWindow(800, 450, "raylib [core] example - basic window");



	while (!WindowShouldClose())
	{
		BeginDrawing();
		ClearBackground(RAYWHITE);
		DrawRectangle(300, 100, 100, 100, BLUE);


		DrawText("Congrats! You created your first window!", 190, 200, 20, LIGHTGRAY);



		EndDrawing();
	}





	CloseWindow();

	return 0;
}