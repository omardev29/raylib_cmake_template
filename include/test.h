#pragma once
#include <raylib.h>

class GameAssets {
public:
  Texture2D rabbit;
  Image img;
};

inline GameAssets LoadGameAssets() {
  Image img = LoadImage(RESOURCES_PATH "rabbit.png");
  Texture2D tex = LoadTextureFromImage(img);
  return {tex, img};
}
