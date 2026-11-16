// Small anti-aliased software renderer for a 240 x 240 round display.
// Portable C++: the same code runs on the ESP32-S3 and in the desktop simulator (sim/).
// Everything is drawn into a 0x00RRGGBB frame buffer and dithered down to RGB565 on output.
#pragma once
#if defined(__GNUC__) && !defined(__clang__)
#pragma GCC optimize("O3")
#endif
#include <stdint.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>

namespace gfx {

constexpr int W = 240, H = 240;
constexpr float CX = 119.5f, CY = 119.5f;
constexpr float PI_F = 3.14159265f, TAU = 6.28318531f, DEG = PI_F / 180.0f;

static uint32_t* FB = nullptr;  // current render target, W * H pixels

struct Glyph { uint32_t off; uint8_t w, h; int8_t xo, yo; uint16_t adv; };  // adv in 1/16 px
struct Font { const uint8_t* bmp; const Glyph* gl; uint8_t first, last; uint8_t cap; };

// ---------------------------------------------------------------- maths
static inline float clampf(float v, float lo, float hi) { return v < lo ? lo : (v > hi ? hi : v); }
static inline int clampi(int v, int lo, int hi) { return v < lo ? lo : (v > hi ? hi : v); }
static inline float maxf(float a, float b) { return a > b ? a : b; }
static inline float minf(float a, float b) { return a < b ? a : b; }
static inline float lerpf(float a, float b, float t) { return a + (b - a) * t; }
static inline int ifloor(float x) { int i = (int)x; return i - (x < (float)i); }
static inline int iceil(float x) { int i = (int)x; return i + (x > (float)i); }
static inline float smooth(float t) { t = clampf(t, 0, 1); return t * t * (3 - 2 * t); }
static inline float approach(float cur, float target, float rate, float dt) {
  return cur + (target - cur) * (1.0f - expf(-rate * dt));
}

// Square root without a libm call: the ESP32-S3 FPU has no sqrt instruction.
static inline float fsqrt(float x) {
  if (x <= 1e-12f) return 0;
  union { float f; uint32_t i; } u = {x};
  u.i = 0x5f375a86u - (u.i >> 1);
  float y = u.f;
  y = y * (1.5f - 0.5f * x * y * y);
  y = y * (1.5f - 0.5f * x * y * y);
  return x * y;
}

// 1 / x for x > 0 without a divide: the ESP32-S3 has no float divide instruction.
static inline float frecip(float x) {
  union { float f; uint32_t i; } u = {x};
  u.i = 0x7EF311C7u - u.i;
  float y = u.f;
  y = y * (2.0f - x * y);
  y = y * (2.0f - x * y);
  return y;
}

// atan2 approximation, error below 0.0002 rad.
static inline float fatan2(float y, float x) {
  float ax = fabsf(x), ay = fabsf(y);
  float mx = ax > ay ? ax : ay, mn = ax > ay ? ay : ax;
  if (mx <= 1e-12f) return 0;
  float a = mn * frecip(mx), s = a * a;
  float r = ((-0.0464964749f * s + 0.15931422f) * s - 0.327622764f) * s * a + a;
  if (ay > ax) r = 1.57079637f - r;
  if (x < 0) r = 3.14159274f - r;
  return y < 0 ? -r : r;
}

// ---------------------------------------------------------------- colour
static inline uint32_t rgb(int r, int g, int b) { return ((uint32_t)r << 16) | ((uint32_t)g << 8) | (uint32_t)b; }

static inline uint32_t mixc(uint32_t a, uint32_t b, float t) {
  uint32_t k = (uint32_t)(clampf(t, 0, 1) * 256.0f);
  uint32_t rb = a & 0xFF00FF, g = a & 0x00FF00;
  rb += (((b & 0xFF00FF) - rb) * k) >> 8;
  g += (((b & 0x00FF00) - g) * k) >> 8;
  return (rb & 0xFF00FF) | (g & 0x00FF00);
}
static inline uint32_t dim(uint32_t c, float k) { return mixc(0, c, k); }

static inline uint32_t hsv(float h, float s, float v) {
  h -= floorf(h);
  float f = h * 6.0f;
  int i = (int)f;
  f -= i;
  float p = v * (1 - s), q = v * (1 - s * f), t = v * (1 - s * (1 - f));
  float r, g, b;
  switch (i % 6) {
    case 0: r = v; g = t; b = p; break;
    case 1: r = q; g = v; b = p; break;
    case 2: r = p; g = v; b = t; break;
    case 3: r = p; g = q; b = v; break;
    case 4: r = t; g = p; b = v; break;
    default: r = v; g = p; b = q; break;
  }
  return rgb((int)(r * 255), (int)(g * 255), (int)(b * 255));
}

// Piecewise-linear colour ramp over n evenly spaced stops.
static inline uint32_t ramp(const uint32_t* stops, int n, float t) {
  t = clampf(t, 0, 1) * (n - 1);
  int i = (int)t;
  if (i >= n - 1) return stops[n - 1];
  return mixc(stops[i], stops[i + 1], t - i);
}

// ---------------------------------------------------------------- pixels
static inline void blp(uint32_t& d, uint32_t c, int a) {  // a: 0..256
  uint32_t rb = d & 0xFF00FF, g = d & 0x00FF00;
  rb += (((c & 0xFF00FF) - rb) * (uint32_t)a) >> 8;
  g += (((c & 0x00FF00) - g) * (uint32_t)a) >> 8;
  d = (rb & 0xFF00FF) | (g & 0x00FF00);
}
static inline void addp(uint32_t& d, uint32_t c, int a) {  // additive, saturating
  uint32_t r = ((d >> 16) & 255) + ((((c >> 16) & 255) * a) >> 8);
  uint32_t g = ((d >> 8) & 255) + ((((c >> 8) & 255) * a) >> 8);
  uint32_t b = (d & 255) + (((c & 255) * a) >> 8);
  d = ((r > 255 ? 255 : r) << 16) | ((g > 255 ? 255 : g) << 8) | (b > 255 ? 255 : b);
}

static inline void clear(uint32_t c = 0) {
  if (c == 0) { memset(FB, 0, W * H * sizeof(uint32_t)); return; }
  for (int i = 0; i < W * H; i++) FB[i] = c;
}

// ---------------------------------------------------------------- shapes
// All shapes are anti-aliased. Coordinates are pixel centres, so (119.5, 119.5) is the middle.

static void circle(float cx, float cy, float r, uint32_t c, float alpha = 1) {
  if (r <= 0 || alpha <= 0) return;
  int A = (int)(clampf(alpha, 0, 1) * 256);
  float ro = r + 0.5f, ri = r - 0.5f, ro2 = ro * ro, ri2 = ri > 0 ? ri * ri : -1;
  int y0 = clampi(ifloor(cy - ro), 0, H - 1), y1 = clampi(iceil(cy + ro), 0, H - 1);
  for (int y = y0; y <= y1; y++) {
    float dy = y - cy, h2 = ro2 - dy * dy;
    if (h2 <= 0) continue;
    float hw = fsqrt(h2);
    int x0 = clampi(ifloor(cx - hw), 0, W - 1), x1 = clampi(iceil(cx + hw), 0, W - 1);
    uint32_t* row = FB + y * W;
    for (int x = x0; x <= x1; x++) {
      float dx = x - cx, d2 = dx * dx + dy * dy;
      if (d2 <= ri2) blp(row[x], c, A);
      else if (d2 < ro2) blp(row[x], c, (int)(minf(ro - fsqrt(d2), 1) * A));
    }
  }
}

// Soft additive glow that fades to nothing at radius r. Integer maths and a lookup table: glows
// cover a lot of pixels, so this is the hot loop of most scenes.
static void glow(float cx, float cy, float r, uint32_t c, float strength) {
  if (r < 2 || strength <= 0) return;
  uint32_t lut[257];
  int last = -1;
  for (int i = 0; i <= 256; i++) {
    float f = 1.0f - i * (1.0f / 256.0f);
    uint32_t a = (uint32_t)(minf(f * f * f * strength, 1) * 256.0f);
    lut[i] = ((((c & 0xFF00FF) * a) >> 8) & 0xFF00FF) | ((((c & 0x00FF00) * a) >> 8) & 0x00FF00);
    if (lut[i]) last = i;
  }
  if (last < 0) return;
  float r2 = r * r;
  int re2 = (int)(r2 * (last + 1) * (1.0f / 256.0f));  // beyond this the glow adds nothing
  uint32_t k = (uint32_t)(256.0f * 65536.0f / r2);
  int icx = (int)lroundf(cx), icy = (int)lroundf(cy), ir = (int)fsqrt((float)re2);
  int y0 = clampi(icy - ir, 0, H - 1), y1 = clampi(icy + ir, 0, H - 1);
  for (int y = y0; y <= y1; y++) {
    int dy = y - icy, rem = re2 - dy * dy;
    if (rem < 0) continue;
    int hw = (int)fsqrt((float)rem);
    int x0 = clampi(icx - hw, 0, W - 1), x1 = clampi(icx + hw, 0, W - 1);
    int dx = x0 - icx;
    uint32_t d2 = (uint32_t)(dx * dx + dy * dy);
    uint32_t* p = FB + y * W + x0;
    for (int x = x0; x <= x1; x++, p++) {
      uint32_t idx = (d2 * k) >> 16;
      d2 += (uint32_t)(2 * dx + 1);
      dx++;
      if (idx > 256) continue;
      uint32_t sc = lut[idx], d = *p;
      if (!d) { *p = sc; continue; }
      uint32_t rb = (d & 0xFF00FF) + (sc & 0xFF00FF), g = (d & 0x00FF00) + (sc & 0x00FF00);
      rb |= ((rb >> 8) & 0x010001) * 0xFF;  // saturate each channel that overflowed
      g |= ((g >> 8) & 0x000100) * 0xFF;
      *p = (rb & 0xFF00FF) | (g & 0x00FF00);
    }
  }
}

// Line with round ends ("capsule") of radius r.
static void capsule(float ax, float ay, float bx, float by, float r, uint32_t c, float alpha = 1) {
  if (alpha <= 0) return;
  if (r < 0.5f) { alpha *= r * 2; r = 0.5f; }
  int A = (int)(clampf(alpha, 0, 1) * 256);
  float ro = r + 0.5f, ri = r - 0.5f, ro2 = ro * ro, ri2 = ri > 0 ? ri * ri : -1;
  int x0 = clampi(ifloor(minf(ax, bx) - ro), 0, W - 1), x1 = clampi(iceil(maxf(ax, bx) + ro), 0, W - 1);
  int y0 = clampi(ifloor(minf(ay, by) - ro), 0, H - 1), y1 = clampi(iceil(maxf(ay, by) + ro), 0, H - 1);
  float bax = bx - ax, bay = by - ay, len2 = bax * bax + bay * bay;
  float inv = len2 > 1e-6f ? 1.0f / len2 : 0;
  bool slanted = fabsf(bay) > 0.01f;
  float invBay = slanted ? 1.0f / bay : 0;
  for (int y = y0; y <= y1; y++) {
    uint32_t* row = FB + y * W;
    float pay = y - ay;
    int xs = x0, xe = x1;
    if (slanted) {  // the part of the line within reach of this row
      float h1 = (pay - ro) * invBay, h2 = (pay + ro) * invBay;
      if (h1 > h2) { float t = h1; h1 = h2; h2 = t; }
      if (h1 < 0) h1 = 0;
      if (h2 > 1) h2 = 1;
      if (h1 > h2) continue;
      float xa = ax + h1 * bax, xb = ax + h2 * bax;
      xs = clampi(ifloor(minf(xa, xb) - ro), x0, x1);
      xe = clampi(iceil(maxf(xa, xb) + ro), x0, x1);
    }
    for (int x = xs; x <= xe; x++) {
      float pax = x - ax;
      float h = clampf((pax * bax + pay * bay) * inv, 0, 1);
      float ex = pax - bax * h, ey = pay - bay * h, d2 = ex * ex + ey * ey;
      if (d2 <= ri2) blp(row[x], c, A);
      else if (d2 < ro2) blp(row[x], c, (int)(minf(ro - fsqrt(d2), 1) * A));
    }
  }
}

// Fill any shape described by a signed distance function (negative inside).
template <class F>
static void fillSDF(float fx0, float fy0, float fx1, float fy1, uint32_t c, float alpha, F sdf) {
  if (alpha <= 0) return;
  int A = (int)(clampf(alpha, 0, 1) * 256);
  int x0 = clampi(ifloor(fx0), 0, W - 1), x1 = clampi(iceil(fx1), 0, W - 1);
  int y0 = clampi(ifloor(fy0), 0, H - 1), y1 = clampi(iceil(fy1), 0, H - 1);
  for (int y = y0; y <= y1; y++) {
    uint32_t* row = FB + y * W;
    for (int x = x0; x <= x1; x++) {
      float d = sdf((float)x, (float)y);
      if (d >= 0.5f) continue;
      blp(row[x], c, d <= -0.5f ? A : (int)((0.5f - d) * A));
    }
  }
}

static inline float sdRoundBox(float px, float py, float hw, float hh, float rad) {
  float qx = fabsf(px) - (hw - rad), qy = fabsf(py) - (hh - rad);
  if (qx > 0 && qy > 0) return fsqrt(qx * qx + qy * qy) - rad;
  return maxf(qx, qy) - rad;
}

static void rrect(float cx, float cy, float hw, float hh, float rad, uint32_t c, float alpha = 1) {
  rad = minf(rad, minf(hw, hh));
  fillSDF(cx - hw - 1, cy - hh - 1, cx + hw + 1, cy + hh + 1, c, alpha,
          [=](float x, float y) { return sdRoundBox(x - cx, y - cy, hw, hh, rad); });
}

// Arc of thickness th on radius r with round ends. Angles are radians, clockwise from 12 o'clock.
// colorAt(t) gives the colour at fraction t along the arc; gradient = false uses colorAt(0) throughout.
template <class ColorFn>
static void arcFn(float cx, float cy, float r, float th, float a0, float a1, bool gradient, ColorFn colorAt,
                  float alpha = 1) {
  if (a1 <= a0 || alpha <= 0) return;
  float half = (a1 - a0) * 0.5f;
  bool full = half >= PI_F - 1e-4f;
  if (full) half = PI_F;
  float mid = (a0 + a1) * 0.5f, sm = sinf(mid), cm = cosf(mid), sh = sinf(half), ch = cosf(half);
  float hw = th * 0.5f, ro = r + hw + 0.5f, ri = r - hw - 0.5f;
  float ro2 = ro * ro, ri2 = ri > 0 ? ri * ri : -1;
  float kOut = 0.5f / ro, kIn = ri > 0 ? 0.5f / ri : 0;  // edge coverage, linearised: no square root
  float capO = hw + 0.5f, capO2 = capO * capO, capI2 = hw > 0.5f ? (hw - 0.5f) * (hw - 0.5f) : -1;
  float tScale = 255.0f * 0.5f / half;
  uint32_t lut[256];
  uint32_t solid = colorAt(0.0f);
  if (gradient) for (int i = 0; i < 256; i++) lut[i] = colorAt(i * (1.0f / 255.0f));
  int A = (int)(clampf(alpha, 0, 1) * 256);
  int y0 = clampi(ifloor(cy - ro), 0, H - 1), y1 = clampi(iceil(cy + ro), 0, H - 1);
  for (int y = y0; y <= y1; y++) {
    float dy = y - cy, h2 = ro2 - dy * dy;
    if (h2 <= 0) continue;
    float xo = fsqrt(h2);
    int xa = clampi(ifloor(cx - xo), 0, W - 1), xb = clampi(iceil(cx + xo), 0, W - 1);
    int ha = 1, hb = 0;  // columns inside the hole of the ring, skipped
    float hi2 = ri2 - dy * dy;
    if (hi2 > 4) {
      float xi = fsqrt(hi2);
      ha = iceil(cx - xi) + 1;
      hb = ifloor(cx + xi) - 1;
    }
    uint32_t* row = FB + y * W;
    float dys = dy * sm, dyc = dy * cm;
    for (int x = xa; x <= xb; x++) {
      if (x >= ha && x <= hb) { x = hb; continue; }
      float dx = x - cx, d2 = dx * dx + dy * dy;
      if (d2 >= ro2 || d2 <= ri2) continue;
      float u = dx * cm + dys, v = dx * sm - dyc, au = fabsf(u), cov;
      if (!full && ch * au > sh * v) {  // past an end: the round cap
        float ex = au - sh * r, ey = v - ch * r, e2 = ex * ex + ey * ey;
        if (e2 >= capO2) continue;
        cov = e2 <= capI2 ? 1.0f : capO - fsqrt(e2);
      } else {
        cov = (ro2 - d2) * kOut;
        if (ri > 0) cov = minf(cov, (d2 - ri2) * kIn);
        if (cov > 1) cov = 1;
      }
      uint32_t c = solid;
      if (gradient) c = lut[clampi((int)(fatan2(u, v) * tScale + 127.5f), 0, 255)];
      blp(row[x], c, (int)(cov * A));
    }
  }
}

static void arc(float cx, float cy, float r, float th, float a0, float a1, uint32_t c, float alpha = 1) {
  arcFn(cx, cy, r, th, a0, a1, false, [c](float) { return c; }, alpha);
}
static void ring(float cx, float cy, float r, float th, uint32_t c, float alpha = 1) {
  arc(cx, cy, r, th, 0, TAU, c, alpha);
}

// A ring that never moves can be worked out once. A Band lists its pixels with their coverage and a
// value the caller derives from the angle (clockwise from 12 o'clock, as a fraction of a turn).
struct BandPx { uint16_t idx; uint16_t val; uint8_t cov; };
struct Band { BandPx* px = nullptr; int n = 0; };
static void* (*bigAlloc)(size_t) = malloc;  // the firmware points this at external RAM

// valueAt(turn) returns 0..65535, or -1 to leave the pixel out.
template <class F>
static void buildBand(Band& b, float cx, float cy, float ri, float ro, F valueAt) {
  for (int pass = 0; pass < 2; pass++) {
    int n = 0;
    for (int y = 0; y < H; y++)
      for (int x = 0; x < W; x++) {
        float dx = x - cx, dy = y - cy, d = sqrtf(dx * dx + dy * dy);
        float cov = minf(minf(ro + 0.5f - d, d - (ri - 0.5f)), 1);
        if (cov <= 0.004f) continue;
        float turn = atan2f(dx, -dy) * (1.0f / TAU);
        if (turn < 0) turn += 1;
        int v = valueAt(turn);
        if (v < 0) continue;
        if (pass) b.px[n] = {(uint16_t)(y * W + x), (uint16_t)v, (uint8_t)(cov * 255.0f + 0.5f)};
        n++;
      }
    if (!pass) { b.px = (BandPx*)bigAlloc(sizeof(BandPx) * (n ? n : 1)); b.n = b.px ? n : 0; if (!b.px) return; }
  }
}

// Point on a circle, angle clockwise from 12 o'clock.
static inline void polar(float cx, float cy, float r, float a, float& x, float& y) {
  x = cx + r * sinf(a);
  y = cy - r * cosf(a);
}

// ---------------------------------------------------------------- text
static float textWidth(const Font& f, const char* s, float track = 0) {
  float w = 0;
  int n = 0;
  for (; *s; s++, n++) {
    uint8_t ch = (uint8_t)*s;
    if (ch < f.first || ch > f.last) continue;
    w += f.gl[ch - f.first].adv * (1.0f / 16.0f) + track;
  }
  return n ? w - track : 0;
}

// align: 0 left, 1 centre, 2 right. y is the baseline.
static void text(const Font& f, float x, float y, const char* s, uint32_t c, int align = 1, float alpha = 1,
                 float track = 0) {
  if (alpha <= 0) return;
  if (align == 1) x -= textWidth(f, s, track) * 0.5f;
  else if (align == 2) x -= textWidth(f, s, track);
  int A = (int)(clampf(alpha, 0, 1) * 256);
  int by = (int)lroundf(y);
  for (; *s; s++) {
    uint8_t ch = (uint8_t)*s;
    if (ch < f.first || ch > f.last) continue;
    const Glyph& g = f.gl[ch - f.first];
    int gx = (int)lroundf(x) + g.xo, gy = by + g.yo;
    const uint8_t* src = f.bmp + g.off;
    for (int j = 0; j < g.h; j++, src += g.w) {
      int py = gy + j;
      if ((unsigned)py >= (unsigned)H) continue;
      uint32_t* row = FB + py * W;
      for (int i = 0; i < g.w; i++) {
        int px = gx + i;
        if (src[i] && (unsigned)px < (unsigned)W) blp(row[px], c, (src[i] * A + 128) >> 8);
      }
    }
    x += g.adv * (1.0f / 16.0f) + track;
  }
}

// ---------------------------------------------------------------- output
// Convert rows y0..y1-1 of the picture, as it will appear on the panel, to big-endian RGB565 with
// ordered dithering. rot turns the picture by that many quarter turns clockwise.
static void presentRows(uint16_t* dst, int y0, int y1, int rot) {
  static const uint8_t bayer[4][4] = {{0, 8, 2, 10}, {12, 4, 14, 6}, {3, 11, 1, 9}, {15, 7, 13, 5}};
  for (int oy = y0; oy < y1; oy++) {
    int idx, step;
    switch (rot & 3) {
      case 1: idx = (H - 1) * W + oy; step = -W; break;
      case 2: idx = (H - 1 - oy) * W + (W - 1); step = -1; break;
      case 3: idx = (W - 1 - oy); step = W; break;
      default: idx = oy * W; step = 1; break;
    }
    const uint32_t* src = FB + idx;
    const uint8_t* bay = bayer[oy & 3];
    for (int ox = 0; ox < W; ox++, src += step) {
      uint32_t c = *src;
      int t = bay[ox & 3];
      int r = (int)((c >> 16) & 255) + (t >> 1), g = (int)((c >> 8) & 255) + (t >> 2), b = (int)(c & 255) + (t >> 1);
      r = r > 255 ? 255 : r;
      g = g > 255 ? 255 : g;
      b = b > 255 ? 255 : b;
      uint32_t v = (uint32_t)(((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3));
      *dst++ = (uint16_t)((v << 8) | (v >> 8));
    }
  }
}
static void present565(uint16_t* dst, int rot) { presentRows(dst, 0, H, rot); }

}  // namespace gfx

#include "fonts.h"
