// The six showcase scenes and the app that switches between them.
// Portable C++ (no Arduino calls): shared by the firmware and the desktop simulator.
#pragma once
#include <stdio.h>
#include "gfx.h"

namespace app {
using namespace gfx;

struct Input {
  int delta = 0;       // knob steps since the last frame, clockwise positive
  bool click = false;  // knob was pressed and released
  float dt = 1.0f / 60;
};

static double T = 0;               // seconds since start
static uint32_t* PREV = nullptr;   // snapshot of the outgoing scene, for the transition
static double clockBase = 10 * 3600 + 9 * 60 + 30;  // time of day at T = 0, seconds
static char dateText[8] = "NOV 15";

static uint32_t rngState = 0x2545F491u;
static inline uint32_t rnd() {
  rngState ^= rngState << 13;
  rngState ^= rngState >> 17;
  rngState ^= rngState << 5;
  return rngState;
}
static inline float frand() { return (rnd() >> 8) * (1.0f / 16777216.0f); }
static inline float frange(float a, float b) { return a + (b - a) * frand(); }

// ============================================================ 1. Face
struct Face {
  float lookX = 0, lookY = 0, tlx = 0, tly = 0;
  float open = 0, happy = 0, tHappy = 0, lid = 0, tLid = 0, dizzy = 0;
  float vel = 0, spin = 0, age = 0;
  float dizzyLeft = 0, blinkT = -1;
  double nextBlink = 0, nextLook = 0, nextMood = 0, moodEnd = 0;
  int extraBlinks = 0;

  void enter() {
    open = 0; age = 0; happy = tHappy = 0; lid = tLid = 0; dizzy = 0; dizzyLeft = 0; spin = 0; vel = 0;
    lookX = lookY = tlx = tly = 0;
    blinkT = -1;
    nextBlink = T + 1.6; nextLook = T + 1.4; nextMood = T + 4.5;
  }

  void update(const Input& in) {
    float dt = in.dt;
    age += dt;
    vel = approach(vel, in.delta / maxf(dt, 1e-3f), 9, dt);
    spin = (spin + fabsf((float)in.delta)) * expf(-1.6f * dt);

    bool wasDizzy = dizzyLeft > 0;
    if (spin > 9) dizzyLeft = 2.4f;
    if (dizzyLeft > 0) dizzyLeft -= dt;
    if (wasDizzy && dizzyLeft <= 0) {  // recovered: blink it off and look pleased
      extraBlinks = 1; blinkT = 0; tHappy = 1; tLid = 0; moodEnd = T + 2.0; nextMood = T + 6;
    }
    dizzy = approach(dizzy, dizzyLeft > 0 ? 1 : 0, 9, dt);

    if (fabsf(vel) > 1.0f) {  // follow the knob
      tlx = clampf(vel * 2.4f, -20, 20); tly = -3; tLid = 0;
      nextLook = T + 0.9;
    } else if (T > nextLook) {
      if (frand() < 0.5f) { tlx = 0; tly = 0; }
      else { tlx = frange(-18, 18); tly = frange(-9, 7); }
      nextLook = T + frange(0.7, 2.4);
    }
    lookX = approach(lookX, tlx, 13, dt);
    lookY = approach(lookY, tly, 13, dt);

    if (blinkT < 0 && T > nextBlink) blinkT = 0;
    if (blinkT >= 0) {
      blinkT += dt;
      if (blinkT > 0.17f) {
        blinkT = -1;
        if (extraBlinks > 0) { extraBlinks--; nextBlink = T + 0.1; }
        else nextBlink = T + frange(1.6, 4.5);
      }
    }

    if (T > nextMood && dizzyLeft <= 0 && fabsf(vel) < 0.5f) {
      float r = frand();
      if (r < 0.6f) { tHappy = 1; moodEnd = T + 2.3; }
      else if (r < 0.85f) { tLid = 0.48f; moodEnd = T + 2.6; }
      else { extraBlinks = 1; blinkT = 0; moodEnd = T; }
      nextMood = T + frange(5.5, 9);
    }
    if (T > moodEnd) { tHappy = 0; tLid = 0; }
    happy = approach(happy, tHappy, 9, dt);
    lid = approach(lid, tLid, 7, dt);
    open = approach(open, age > 0.45f ? 1 : 0, 8, dt);
  }

  void draw() {
    const uint32_t C = 0x38E8FF;
    clear();
    float blink = blinkT < 0 ? 1 : clampf(fabsf(blinkT - 0.075f) / 0.075f, 0, 1);
    float openness = open * blink;
    float face = 1 - dizzy;
    for (int side = -1; side <= 1; side += 2) {
      float sc = 1 + 0.07f * side * (lookX / 20);
      float ex = CX + side * 50 + lookX, ey = CY - 2 + lookY;
      float hw = 25 * sc, hh = maxf(36 * sc * openness * (1 - 0.22f * happy), 2.8f);
      float rad = minf(17, minf(hw, hh));
      glow(ex, ey, 72, C, 0.20f * (0.35f + 0.65f * openness));
      if (face > 0.02f) {
        float hp = happy, ld = lid;
        const float R = 42;
        float ccy = ey - 0.12f * hh + R + (1 - hp) * hh * 1.5f;
        float cut = ey - hh + ld * 2 * hh;
        fillSDF(ex - hw - 1, ey - hh - 1, ex + hw + 1, ey + hh + 1, C, face, [=](float x, float y) {
          float d = sdRoundBox(x - ex, y - ey, hw, hh, rad);
          if (hp > 0.01f) {  // carve a circle out of the bottom: a smiling arch
            float dx = x - ex, dy = y - ccy;
            d = maxf(d, R - fsqrt(dx * dx + dy * dy));
          }
          if (ld > 0.01f) d = maxf(d, cut - y);  // half-closed lid
          return d;
        });
      }
      if (dizzy > 0.02f) {  // spinning spiral
        float rot = (float)fmod(T * 9.0, (double)TAU) * side;
        float px = 0, py = 0;
        for (int i = 0; i <= 44; i++) {
          float t = i / 44.0f, a = t * 2.3f * TAU + rot, rr = 2 + t * 24;
          float x = ex + rr * cosf(a), y = ey + rr * sinf(a);
          if (i) capsule(px, py, x, y, 2.6f, C, dizzy);
          px = x; py = y;
        }
      }
    }
    float h = happy * face;
    if (h > 0.02f) {
      circle(CX - 84 + lookX * 0.4f, CY + 46, 10, 0xFF5C8A, 0.6f * h);
      circle(CX + 84 + lookX * 0.4f, CY + 46, 10, 0xFF5C8A, 0.6f * h);
      arc(CX + lookX * 0.6f, CY + 42 + lookY * 0.5f, 14, 4.5f, 118 * DEG, 242 * DEG, C, h);
    }
  }
};

// ============================================================ 2. Thermostat
struct Thermo {
  float target = 22.5f, shown = 16, cur = 21.0f;
  static uint32_t col(float f) {
    static const uint32_t stops[] = {0x2F7BFF, 0x22D3EE, 0x7CE38B, 0xFFD23F, 0xFF8A2A, 0xFF3B30};
    return ramp(stops, 6, f);
  }
  void update(const Input& in) {
    target = clampf(target + in.delta * 0.5f, 16, 30);
    shown = approach(shown, target, 10, in.dt);
    cur = approach(cur, target, 0.06f, in.dt);
  }
  void draw() {
    const float a0 = -135 * DEG, a1 = 135 * DEG, R = 104;
    float f = clampf((shown - 16) / 14, 0, 1), aEnd = a0 + f * (a1 - a0);
    uint32_t tc = col(f);
    clear();
    glow(CX, CY + 6, 120, tc, 0.13f);
    // The track and the coloured part share one cached band; val is the position along the arc.
    static Band band;
    static uint32_t lut[256];
    if (!band.px) {
      buildBand(band, CX, CY, R - 5.5f, R + 5.5f, [](float turn) {
        float af = turn + 0.375f;  // the arc starts at 225 degrees
        if (af >= 1) af -= 1;
        af *= 360.0f / 270.0f;
        return af > 1 ? -1 : (int)(af * 65535.0f);
      });
      for (int i = 0; i < 256; i++) lut[i] = col(i / 255.0f);
    }
    const uint32_t track = 0x1E222A;
    uint32_t lit = f > 0.004f ? (uint32_t)(f * 65535.0f) : 0;
    for (int i = 0; i < band.n; i++) {
      const BandPx& b = band.px[i];
      blp(FB[b.idx], (b.val < lit) ? lut[b.val >> 8] : track, b.cov + (b.cov >> 7));
    }
    float ex, ey;
    polar(CX, CY, R, a0, ex, ey);
    circle(ex, ey, 5.5f, lit ? lut[0] : track);
    polar(CX, CY, R, a1, ex, ey);
    circle(ex, ey, 5.5f, f > 0.998f ? lut[255] : track);
    for (int i = 0; i <= 28; i++) {
      float tf = i / 28.0f, a = a0 + tf * (a1 - a0), x0, y0, x1, y1;
      bool major = (i % 2) == 0;
      polar(CX, CY, major ? 84 : 86.5f, a, x0, y0);
      polar(CX, CY, 90, a, x1, y1);
      capsule(x0, y0, x1, y1, major ? 1.1f : 0.8f, tf <= f + 0.002f ? col(tf) : 0x3A404B);
    }
    float kx, ky;
    polar(CX, CY, R, aEnd, kx, ky);
    glow(kx, ky, 26, tc, 0.55f);
    circle(kx, ky, 9, 0xFFFFFF);
    circle(kx, ky, 4.5f, tc);

    text(FS, CX, 72, "TARGET", 0x8B94A5, 1, 1, 2.5f);
    char buf[16];
    int tenths = (int)lroundf(target * 10);
    snprintf(buf, sizeof buf, "%d.%d", tenths / 10, tenths % 10);
    float w = textWidth(FX, buf);
    float nx = CX - 9;
    text(FX, nx, CY + 24, buf, 0xFFFFFF);
    text(FM, nx + w * 0.5f + 3, CY + 24 - FX.cap + FM.cap, "\x7f" "C", 0xB6BECB, 0);

    const char* status = "HOLDING";
    uint32_t sc = 0x8B94A5;
    if (target > cur + 0.25f) { status = "HEATING"; sc = 0xFF8A2A; }
    else if (target < cur - 0.25f) { status = "COOLING"; sc = 0x4DA3FF; }
    float sw = textWidth(FS, status, 2.5f);
    circle(CX - sw * 0.5f - 9, 173.5f, 3.2f, sc);
    text(FS, CX + 4, 179, status, sc, 1, 1, 2.5f);
    int ct = (int)lroundf(cur * 10);
    snprintf(buf, sizeof buf, "NOW %d.%d\x7f", ct / 10, ct % 10);
    text(FS, CX, 201, buf, 0x6B7483, 1, 1, 1);
  }
};

// ============================================================ 3. Music
struct Music {
  static constexpr int N = 48;
  float vol = 64, shown = 0, bars[N] = {0}, beat = 0;
  static uint32_t col(float f) {
    static const uint32_t stops[] = {0xFF2D95, 0xB14CFF, 0x5B8CFF, 0x22D3EE};
    return ramp(stops, 4, f);
  }
  void update(const Input& in) {
    vol = clampf(vol + in.delta * 2, 0, 100);
    shown = approach(shown, vol, 12, in.dt);
    float t = (float)fmod(T, 600.0);
    beat = expf(-5.5f * (float)fmod(T * 2.0, 1.0));
    float level = 0.12f + 0.88f * shown / 100;
    for (int i = 0; i < N; i++) {
      int k = i <= N / 2 ? i : N - i;
      float x = k / (float)(N / 2);
      float n1 = 0.5f + 0.5f * sinf(t * (3.1f + 1.7f * k) + k * 1.3f);
      float n2 = 0.5f + 0.5f * sinf(t * (5.3f + 0.9f * k) + k * 2.1f);
      float sweep = 0.5f + 0.5f * sinf(t * 1.3f + x * 6);
      float v = 0.10f + 0.50f * n1 * n2 + 0.22f * sweep + beat * (1 - x) * (1 - x) * 0.8f;
      v = clampf(v, 0, 1) * level;
      bars[i] = approach(bars[i], v, v > bars[i] ? 45.0f : 9.0f, in.dt);
    }
  }
  void draw() {
    clear();
    float level = shown / 100;
    glow(CX, CY, 84, 0x7A3CFF, 0.10f + 0.16f * beat * level);
    for (int i = 0; i < N; i++) {
      int k = i <= N / 2 ? i : N - i;
      float a = i * TAU / N, x0, y0, x1, y1;
      polar(CX, CY, 91, a, x0, y0);
      polar(CX, CY, 91 + 2 + bars[i] * 25, a, x1, y1);
      capsule(x0, y0, x1, y1, 2.3f, col(k / (float)(N / 2)));
    }
    ring(CX, CY, 79, 3, 0x242830);
    if (level > 0.004f) {
      float aEnd = level * TAU * 0.9999f, kx, ky;
      arc(CX, CY, 79, 4, 0, aEnd, 0xFFFFFF);
      polar(CX, CY, 79, aEnd, kx, ky);
      glow(kx, ky, 16, 0xFFFFFF, 0.45f);
      circle(kx, ky, 4.5f, 0xFFFFFF);
    }
    text(FS, CX, CY - 31, "VOLUME", 0x8B94A5, 1, 1, 2.5f);
    char buf[8];
    snprintf(buf, sizeof buf, "%d", (int)lroundf(vol));
    text(FX, CX, CY + 23, buf, 0xFFFFFF);
    text(FS, CX, CY + 49, "LO-FI RADIO", 0xC084FC, 1, 1, 1.5f);
  }
};

// ============================================================ 4. Clock
struct Clock {
  float offset = 0, shown = 0;
  void update(const Input& in) {
    offset += in.delta * 60.0f;
    shown = approach(shown, offset, 8, in.dt);
  }
  static void hand(float a, float r0, float r1, float w, uint32_t c) {
    float x0, y0, x1, y1;
    polar(CX, CY, r0, a, x0, y0);
    polar(CX, CY, r1, a, x1, y1);
    capsule(x0, y0, x1, y1, w + 1.6f, 0x000000, 0.55f);
    capsule(x0, y0, x1, y1, w, c);
  }
  void draw() {
    clear();
    glow(CX, CY, 112, 0x2B3550, 0.32f);
    for (int i = 0; i < 60; i++) {
      float a = i * TAU / 60, x0, y0, x1, y1;
      if (i % 5) {
        polar(CX, CY, 112, a, x0, y0);
        circle(x0, y0, 1.0f, 0x596273);
      } else if (i % 15) {
        polar(CX, CY, 101, a, x0, y0);
        polar(CX, CY, 113, a, x1, y1);
        capsule(x0, y0, x1, y1, 1.6f, 0xC9D1DD);
      }
    }
    text(FM, CX, CY - 96 + FM.cap, "12", 0xFFFFFF);
    text(FM, CX, CY + 110, "6", 0xFFFFFF);
    text(FM, CX + 102, CY + FM.cap * 0.5f, "3", 0xFFFFFF);
    text(FM, CX - 102, CY + FM.cap * 0.5f, "9", 0xFFFFFF);
    text(FS, CX, CY - 40, "ONX", 0x8B94A5, 1, 1, 4);
    text(FS, CX, CY + 54, dateText, 0xFF7A33, 1, 1, 1.5f);

    double t = clockBase + T + shown;
    t = fmod(t, 43200.0);
    if (t < 0) t += 43200.0;
    float ah = (float)(t / 43200.0) * TAU, am = (float)(fmod(t, 3600.0) / 3600.0) * TAU;
    float as = (float)(fmod(t, 60.0) / 60.0) * TAU;
    hand(ah, 0, 52, 4.0f, 0xFFFFFF);
    hand(am, 0, 84, 2.8f, 0xFFFFFF);
    float x0, y0, x1, y1;
    polar(CX, CY, -22, as, x0, y0);
    polar(CX, CY, 98, as, x1, y1);
    capsule(x0, y0, x1, y1, 1.2f, 0xFF6A2B);
    circle(CX, CY, 6.5f, 0xFF6A2B);
    circle(CX, CY, 2.6f, 0x101216);
  }
};

// ============================================================ 5. Colour
struct Colour {
  float hue = 24, shown = -40;
  void update(const Input& in) {
    hue += in.delta * 6.0f;
    shown = approach(shown, hue, 9, in.dt);
  }
  void draw() {
    clear();
    float h = shown / 360.0f;
    h -= floorf(h);
    uint32_t c = hsv(h, 1, 1);
    float pulse = 0.5f + 0.5f * sinf((float)fmod(T * 2.2, (double)TAU));
    glow(CX, CY, 97, c, 0.42f + 0.14f * pulse);

    static Band wheel;  // hue wheel: fixed, so worked out once
    static uint32_t hueLut[256];
    if (!wheel.px) {
      buildBand(wheel, CX, CY, 97, 116, [](float turn) { return (int)(turn * 65535.0f); });
      for (int i = 0; i < 256; i++) hueLut[i] = hsv(i / 256.0f, 1, 1);
    }
    for (int i = 0; i < wheel.n; i++) {
      const BandPx& b = wheel.px[i];
      blp(FB[b.idx], hueLut[b.val >> 8], b.cov + (b.cov >> 7));
    }

    float orb = 47 + 1.5f * pulse, invR2 = 1.0f / (orb * orb);  // shaded orb
    for (int y = (int)(CY - orb - 1); y <= (int)(CY + orb + 1); y++) {
      uint32_t* row = FB + y * W;
      for (int x = (int)(CX - orb - 1); x <= (int)(CX + orb + 1); x++) {
        float dx = x - CX, dy = y - CY, d2 = dx * dx + dy * dy;
        if (d2 >= (orb + 0.5f) * (orb + 0.5f)) continue;
        float lx = dx + 15, ly = dy + 17;
        float light = 1.12f - 0.55f * (lx * lx + ly * ly) * invR2;
        uint32_t pc = light > 1 ? mixc(c, 0xFFFFFF, (light - 1) * 2.2f) : dim(c, maxf(light, 0.45f));
        if (d2 <= (orb - 0.5f) * (orb - 0.5f)) { row[x] = pc; continue; }
        blp(row[x], pc, (int)(minf(orb + 0.5f - fsqrt(d2), 1) * 256));
      }
    }

    float sx, sy;  // selector on the wheel
    polar(CX, CY, 106.5f, h * TAU, sx, sy);
    circle(sx, sy, 14, 0x000000, 0.35f);
    circle(sx, sy, 12.5f, 0xFFFFFF);
    circle(sx, sy, 9, c);

    char buf[12];
    snprintf(buf, sizeof buf, "#%06X", (unsigned)c);
    float lum = (0.299f * ((c >> 16) & 255) + 0.587f * ((c >> 8) & 255) + 0.114f * (c & 255)) / 255;
    text(FS, CX, CY + FS.cap * 0.5f, buf, lum > 0.5f ? 0x101216 : 0xFFFFFF, 1, 1, 1);
  }
};

// ============================================================ 6. Warp
struct Warp {
  static constexpr int N = 120;
  struct Star { float x, y, z, px, py; bool has; uint8_t tint; };
  Star s[N];
  float speed = 0.6f, boost = 0;
  void spawn(Star& st, float z) {
    float a = frange(0, TAU), r = 0.16f + 0.84f * fsqrt(frand());
    st.x = r * cosf(a); st.y = r * sinf(a); st.z = z; st.has = false; st.tint = rnd() & 3;
  }
  void init() { for (int i = 0; i < N; i++) spawn(s[i], frange(0.05f, 1)); }
  void update(const Input& in) {
    boost = clampf(boost + in.delta * 0.45f, -5, 5);
    boost = approach(boost, 0, 0.45f, in.dt);
    speed = approach(speed, 0.6f + boost, 6, in.dt);
    for (int i = 0; i < N; i++) {
      Star& st = s[i];
      st.z -= speed * in.dt * 0.45f;
      if (st.z < 0.035f) spawn(st, 1);
      else if (st.z > 1) spawn(st, 0.05f);
    }
  }
  void draw() {
    static const uint32_t tints[4] = {0xFFFFFF, 0xBFD9FF, 0xFFE9C4, 0x9FC2FF};
    clear();
    glow(CX, CY, 120, 0x1B2F8F, 0.40f);
    glow(CX, CY, 34, 0x6F8CFF, 0.16f + 0.04f * fabsf(speed));
    for (int i = 0; i < N; i++) {
      Star& st = s[i];
      float sx = CX + st.x / st.z * 46, sy = CY + st.y / st.z * 46;
      float dx = sx - CX, dy = sy - CY;
      if (dx * dx + dy * dy > 130 * 130) { if (speed > 0) spawn(st, 1); st.has = false; continue; }
      float b = clampf(1.25f - st.z, 0, 1);
      b *= b;
      float rr = 0.5f + 1.5f * (1 - st.z);
      if (st.has) capsule(st.px, st.py, sx, sy, rr, tints[st.tint], b);
      else circle(sx, sy, rr, tints[st.tint], b);
      st.px = sx; st.py = sy; st.has = true;
    }
    char buf[16];
    int w10 = (int)lroundf(fabsf(speed) * 10);
    snprintf(buf, sizeof buf, "WARP %d.%d", w10 / 10, w10 % 10);
    text(FS, CX, CY + 94, buf, 0xAFC4FF, 1, 0.8f, 3);
  }
};

// ============================================================ App
struct App {
  static constexpr int N = 6;
  Face face; Thermo thermo; Music music; Clock clock; Colour colour; Warp warp;
  int cur = 0;
  float trans = 1, sinceSwitch = 99, idle = 0, sceneT = 0, vAcc = 0;
  bool attract = false;
  float attractAfter = 15;  // seconds without input before the demo plays by itself

  const char* name(int i) const {
    static const char* names[N] = {"HELLO", "CLIMATE", "SOUND", "TIME", "COLOUR", "WARP"};
    return names[i];
  }

  void init() { warp.init(); face.enter(); }

  // Knob speed (steps per second) that the self-running demo applies in each scene.
  float demoVel(float p) const {
    switch (cur) {
      case 0: return (p > 1.6f && p < 2.4f) ? 7 : (p > 3.2f && p < 4.0f) ? -7 : (p > 5.0f && p < 5.9f) ? 30 : 0;
      case 1: return 7.5f * sinf(p * 1.15f);
      case 2: return 10 * sinf(p * 1.0f + 0.4f);
      case 3: return 16 * sinf(p * 0.9f);
      case 4: return 5.5f;
      default: return 9 * sinf(p * 0.85f);
    }
  }
  float demoLength() const { return cur == 0 ? 10.5f : 7.5f; }

  void frame(Input in) {
    T += in.dt;
    if (in.delta || in.click) { idle = 0; attract = false; }
    else idle += in.dt;
    if (!attract && idle > attractAfter) { attract = true; vAcc = 0; if (sceneT > 3) sceneT = 3; }
    sceneT += in.dt;
    if (attract) {
      vAcc += demoVel(sceneT) * in.dt;
      int d = (int)vAcc;
      vAcc -= d;
      in.delta = d;
      if (sceneT > demoLength()) in.click = true;
    }
    if (in.click && trans >= 1) {
      memcpy(PREV, FB, W * H * sizeof(uint32_t));
      cur = (cur + 1) % N;
      trans = 0; sinceSwitch = 0; sceneT = 0; vAcc = 0; in.delta = 0;
      if (cur == 0) face.enter();
    }
    switch (cur) {
      case 0: face.update(in); face.draw(); break;
      case 1: thermo.update(in); thermo.draw(); break;
      case 2: music.update(in); music.draw(); break;
      case 3: clock.update(in); clock.draw(); break;
      case 4: colour.update(in); colour.draw(); break;
      default: warp.update(in); warp.draw(); break;
    }
    if (sinceSwitch < 1.9f) toast();
    if (trans < 1) {
      trans += in.dt / 0.55f;
      if (trans < 1) iris(smooth(trans) * 126);
    }
    sinceSwitch += in.dt;
  }

  // Scene name and page dots, shown briefly after a switch.
  void toast() {
    float a = sinceSwitch < 1.4f ? clampf(sinceSwitch / 0.25f, 0, 1) : clampf((1.9f - sinceSwitch) / 0.5f, 0, 1);
    float y = CY + 62;
    rrect(CX, y, 57, 22, 22, 0x3A4150, 0.9f * a);
    rrect(CX, y, 56, 21, 21, 0x0D1014, 0.96f * a);
    text(FS, CX, y + 1, name(cur), 0xFFFFFF, 1, a, 2.5f);
    for (int i = 0; i < N; i++)
      circle(CX + (i - (N - 1) * 0.5f) * 9, y + 10.5f, i == cur ? 2.3f : 1.6f, i == cur ? 0xFFFFFF : 0x6B7483, a);
  }

  // Keep the outgoing scene outside a growing circle.
  void iris(float R) {
    for (int y = 0; y < H; y++) {
      float dy = y - CY, h2 = R * R - dy * dy;
      uint32_t* row = FB + y * W;
      const uint32_t* old = PREV + y * W;
      if (h2 <= 0) { memcpy(row, old, W * sizeof(uint32_t)); continue; }
      float hw = fsqrt(h2);
      int xl = clampi((int)floorf(CX - hw), 0, W), xr = clampi((int)ceilf(CX + hw) + 1, 0, W);
      memcpy(row, old, xl * sizeof(uint32_t));
      memcpy(row + xr, old + xr, (W - xr) * sizeof(uint32_t));
    }
    ring(CX, CY, R, 2.5f, 0xFFFFFF, 0.75f * (1 - trans));
  }
};

}  // namespace app
