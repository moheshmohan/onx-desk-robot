// Desktop simulator: runs the same scene code as the firmware and writes frames as PPM images.
// The frames are what the panel receives: RGB565 after dithering.
//
// Build:  clang++ -O2 -std=c++17 -I.. sim.cpp -o sim        (g++ works too)
// Run:    ./sim shots <out_dir>                    eight stills of every scene: s<scene>_f<n>.ppm
//         ./sim frames <out_dir> <scene> <seconds> <fps>   an image sequence of one scene: f0000.ppm ...
//         ./sim bench                              drawing time per scene on this computer
//
// In every mode the scenes are driven by the firmware's own self-running demo, so the knob moves.
// tools/make_media.py turns the output into PNG sheets and GIFs.
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <string>
#include "scenes.h"

static const float DT = 1.0f / 60;
static app::App a;

static void dump(const std::string& path) {
  static uint16_t out[gfx::W * gfx::H];
  gfx::present565(out, 0);
  FILE* f = fopen(path.c_str(), "wb");
  if (!f) { fprintf(stderr, "cannot write %s\n", path.c_str()); exit(1); }
  fprintf(f, "P6\n%d %d\n255\n", gfx::W, gfx::H);
  for (int i = 0; i < gfx::W * gfx::H; i++) {
    uint16_t v = (uint16_t)((out[i] << 8) | (out[i] >> 8));
    uint8_t px[3] = {(uint8_t)(((v >> 11) & 31) * 255 / 31), (uint8_t)(((v >> 5) & 63) * 255 / 63),
                     (uint8_t)((v & 31) * 255 / 31)};
    fwrite(px, 1, 3, f);
  }
  fclose(f);
}

static void step(bool click = false) {
  app::Input in;
  in.dt = DT;
  in.click = click;
  a.frame(in);
}

// Start fresh and click through to a scene, leaving it at the moment the scene appears.
static void enterScene(int scene) {
  a = app::App();
  app::T = 0;
  app::rngState = 0x2545F491u;
  a.init();
  a.attractAfter = 1e9f;  // no self-running demo while we walk there
  for (int i = 0; i < scene; i++) {
    step(true);
    if (i < scene - 1) for (int k = 0; k < 45; k++) step();
  }
  a.attractAfter = 0;  // from here on the demo turns the knob
  a.idle = 1;
  a.sceneT = 0;
}

int main(int argc, char** argv) {
  std::string mode = argc > 1 ? argv[1] : "";
  gfx::FB = (uint32_t*)calloc(gfx::W * gfx::H, 4);
  app::PREV = (uint32_t*)calloc(gfx::W * gfx::H, 4);
  char name[64];

  if (mode == "shots" && argc > 2) {
    const float shots[8] = {0.20f, 0.36f, 1.0f, 2.0f, 3.0f, 4.0f, 5.4f, 6.6f};
    for (int scene = 0; scene < app::App::N; scene++) {
      enterScene(scene);
      float t = 0;
      for (int next = 0; next < 8 && a.cur == scene;) {
        step();
        t += DT;
        if (t >= shots[next]) {
          snprintf(name, sizeof name, "/s%d_f%d.ppm", scene, next++);
          dump(std::string(argv[2]) + name);
        }
      }
    }
  } else if (mode == "frames" && argc > 5) {
    int scene = atoi(argv[3]), every = 60 / atoi(argv[5]);
    int total = (int)(atof(argv[4]) * 60);
    enterScene(scene);
    for (int i = 0, n = 0; i < total && a.cur == scene; i++) {
      step();
      if (i % every == 0) {
        snprintf(name, sizeof name, "/f%04d.ppm", n++);
        dump(std::string(argv[2]) + name);
      }
    }
  } else if (mode == "bench") {
    for (int scene = 0; scene < app::App::N; scene++) {
      enterScene(scene);
      for (int k = 0; k < 60; k++) step();
      auto t0 = std::chrono::steady_clock::now();
      int n = 0;
      for (; n < 300 && a.cur == scene; n++) step();
      double ms = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count() / n;
      printf("scene %d (%s): %.3f ms per frame on this computer\n", scene, a.name(scene), ms);
    }
  } else {
    fprintf(stderr, "usage: sim shots <dir> | sim frames <dir> <scene> <seconds> <fps> | sim bench\n");
    return 1;
  }
  return 0;
}
