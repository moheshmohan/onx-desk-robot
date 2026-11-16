// ONX2424G013 showcase: six animated scenes for the 1.28" round knob display.
//   Turn the knob  : play with the current scene
//   Press          : next scene
//   Hold 1 second  : rotate the picture a quarter turn (remembered)
//   Leave it alone : after 15 s it plays by itself
//
// Board: "ESP32S3 Dev Module", USB CDC On Boot: Enabled, PSRAM: OPI, Flash: 16MB. See build.sh.
// Pins are from Nextion's schematic and their ESPHome configuration for this board.
#define LGFX_USE_V1
#include <LovyanGFX.hpp>
#include <Preferences.h>
#include <driver/gpio.h>
#include <esp_heap_caps.h>
#include "scenes.h"

namespace pin {
constexpr int LCD_MOSI = 1, LCD_CS = 2, LCD_DC = 3, LCD_SCLK = 5, LCD_BL = 6, LCD_TE = 7, LCD_RST = 8;
constexpr int KEY = 9, ENC_B = 47, ENC_A = 48;
}

#ifndef LCD_WRITE_HZ
#define LCD_WRITE_HZ 80000000  // the factory firmware uses 40 MHz; see the self-test line at boot
#endif
constexpr int ENC_DIR = 1;     // set to -1 if clockwise counts down

class Display : public lgfx::LGFX_Device {
  lgfx::Panel_GC9A01 panel_;
  lgfx::Bus_SPI bus_;
  lgfx::Light_PWM light_;

 public:
  Display() {
    {
      auto c = bus_.config();
      c.spi_host = SPI2_HOST;
      c.spi_mode = 0;
      c.freq_write = LCD_WRITE_HZ;
      c.freq_read = 8000000;
      c.spi_3wire = true;  // the panel has one data line; it is also used to read back
      c.use_lock = false;
      c.dma_channel = SPI_DMA_CH_AUTO;
      c.pin_sclk = pin::LCD_SCLK;
      c.pin_mosi = pin::LCD_MOSI;
      c.pin_miso = -1;
      c.pin_dc = pin::LCD_DC;
      bus_.config(c);
      panel_.setBus(&bus_);
    }
    {
      auto c = panel_.config();
      c.pin_cs = pin::LCD_CS;
      c.pin_rst = pin::LCD_RST;
      c.pin_busy = -1;
      c.panel_width = c.memory_width = 240;
      c.panel_height = c.memory_height = 240;
      c.readable = true;
      c.invert = true;       // IPS panel, as in the factory configuration
      c.rgb_order = false;
      c.bus_shared = false;
      panel_.config(c);
    }
    {
      auto c = light_.config();
      c.pin_bl = pin::LCD_BL;  // drives an NPN transistor: high = on
      c.invert = false;
      c.freq = 20000;
      c.pwm_channel = 7;
      light_.config(c);
      panel_.setLight(&light_);
    }
    setPanel(&panel_);
  }
};

// Log to the USB serial port only when the whole line fits in its buffer right now. A plain
// Serial.print waits for the computer to read, and with nothing reading it stops the animation.
static void logf(const char* fmt, ...) {
  char line[200];
  va_list ap;
  va_start(ap, fmt);
  int n = vsnprintf(line, sizeof line, fmt, ap);
  va_end(ap);
  if (n <= 0) return;
  if (n >= (int)sizeof line) n = sizeof line - 1;
  if (Serial.availableForWrite() >= n) Serial.write((const uint8_t*)line, n);
}

static Display lcd;
static Preferences prefs;
static app::App A;
static uint8_t rotation = 0;

// ---------------------------------------------------------------- knob and button
// Both are sampled 1000 times a second by a small task, so they do not depend on the frame rate.
// The board already has RC filters on all three lines (10 k / 100 nF).
static volatile int32_t encQ = 0;        // quadrature transitions
static volatile uint32_t keyClicks = 0;  // short presses, counted on release
static volatile uint32_t keyHolds = 0;   // presses held for a second
static volatile uint8_t rawPins = 0;     // A, B, key levels for the log
static const int8_t QDEC[16] = {0, -1, 1, 0, 1, 0, 0, -1, -1, 0, 0, 1, 0, 1, -1, 0};

static inline uint8_t readAB() {
  return (uint8_t)((gpio_get_level((gpio_num_t)pin::ENC_A) << 1) | gpio_get_level((gpio_num_t)pin::ENC_B));
}

static void inputTask(void*) {
  uint8_t prev = readAB(), debounce = 0;
  bool down = false, held = false;
  uint32_t downAt = 0;
  for (;;) {
    uint8_t s = readAB();
    if (s != prev) { encQ = encQ + QDEC[(prev << 2) | s]; prev = s; }
    bool raw = gpio_get_level((gpio_num_t)pin::KEY) == 0;
    rawPins = (uint8_t)((s << 1) | (raw ? 0 : 1));
    if (raw != down) {
      if (++debounce >= 10) {
        down = raw; debounce = 0;
        if (down) { downAt = millis(); held = false; }
        else if (!held) keyClicks = keyClicks + 1;
      }
    } else debounce = 0;
    if (down && !held && millis() - downAt > 1000) { held = true; keyHolds = keyHolds + 1; }
    vTaskDelay(1);
  }
}

static inline int32_t floorDiv(int32_t a, int32_t b) { return (a >= 0) ? a / b : -((-a + b - 1) / b); }

// Transitions per detent are not documented, so they are learned: the knob can only rest on a detent,
// and where it rests (which quarter of the cycle) tells how many transitions one click makes.
static int encDiv = 4;
static int knobDelta() {
  static int32_t lastQ = 0, lastPos = 0;
  static uint32_t lastChange = 0;
  static bool restSeen = true;
  int32_t q = encQ;
  uint32_t now = millis();
  if (q != lastQ) { lastQ = q; lastChange = now; restSeen = false; }
  else if (!restSeen && now - lastChange > 250) {
    restSeen = true;
    int res = ((q % 4) + 4) % 4, want = encDiv;
    if (res == 2 && encDiv == 4) want = 2;
    else if ((res == 1 || res == 3) && encDiv > 1) want = 1;
    if (want != encDiv) {
      encDiv = want;
      prefs.putUChar("encdiv", (uint8_t)encDiv);
      lastPos = floorDiv(q + encDiv / 2, encDiv);
      logf("[knob] rest at quarter %d: using %d transition(s) per click\n", res, encDiv);
    }
  }
  int32_t pos = floorDiv(q + encDiv / 2, encDiv);
  int d = (int)(pos - lastPos);
  lastPos = pos;
  return d * ENC_DIR;
}

// ---------------------------------------------------------------- display output
// The panel raises its tearing-effect line for the length of each vertical blank.
static volatile uint32_t teCount = 0, teRiseUs = 0, tePeriodUs = 0, teHighUs = 0;
static void IRAM_ATTR teIsr() {
  uint32_t now = (uint32_t)esp_timer_get_time();
  if (gpio_get_level((gpio_num_t)pin::LCD_TE)) { tePeriodUs = now - teRiseUs; teRiseUs = now; teCount = teCount + 1; }
  else teHighUs = now - teRiseUs;
}

// Sending a frame takes about as long as the panel takes to scan one, and the scan itself is a
// little faster. Starting just after the scan has set off keeps the two from crossing: the scan
// stays ahead for this refresh and the write is ahead for the next. Starting around the vertical
// blank would let the scan overtake the write part-way down, which shows as a tear.
static void waitForSafeStart() {
  uint32_t period = tePeriodUs, blank = teHighUs;
  if (period < 5000 || period > 40000 || blank > period / 2) return;  // no usable signal
  uint32_t from = period - period / 16, to = blank + period / 32;
  for (int i = 0; i < 400; i++) {
    uint32_t phase = ((uint32_t)esp_timer_get_time() - teRiseUs) % period;
    if (phase >= to && phase < from) return;
    delayMicroseconds(50);
  }
}

// The picture is converted to RGB565 a strip at a time into two small buffers. While one strip is
// on its way to the panel by DMA, the next is being converted.
constexpr int STRIP_ROWS = 24;
static uint16_t* strip[2] = {nullptr, nullptr};
static void pushFrame() {
  lcd.setWindow(0, 0, gfx::W - 1, gfx::H - 1);
  for (int y = 0, i = 0; y < gfx::H; y += STRIP_ROWS, i ^= 1) {
    gfx::presentRows(strip[i], y, y + STRIP_ROWS, rotation);
    lcd.writePixelsDMA((lgfx::swap565_t*)strip[i], gfx::W * STRIP_ROWS);
  }
}

// Writes a register 256 times at the pixel clock and reads it back: checks the SPI link at that speed.
static void selfTest() {
  auto panel = lcd.getPanel();
  uint32_t id = panel->readCommand(0x04, 0, 4);
  int bad = 0;
  uint32_t sample = 0;
  for (int i = 0; i < 256; i++) {
    uint8_t v = (uint8_t)((i * 37) & 0xFC);  // memory access control: six mode bits
    lcd.startWrite();
    lcd.writeCommand(0x36);
    lcd.writeData(v);
    lcd.endWrite();
    uint32_t st = panel->readCommand(0x09, 0, 4);  // display status echoes those bits
    if (((st & 0x7E) != ((v >> 1) & 0x7E))) bad++;
    if (i == 3) sample = st;
  }
  lcd.setRotation(1);
  lcd.setRotation(0);
  logf("[selftest] panel id %08lX, write clock %d MHz, register echo errors %d of 256 (sample %08lX)\n",
                (unsigned long)id, (int)(LCD_WRITE_HZ / 1000000), bad, (unsigned long)sample);
}

static void setClockFromBuild() {
  const char* t = __TIME__;  // "hh:mm:ss"
  const char* d = __DATE__;  // "Mmm dd yyyy"
  app::clockBase = atoi(t) * 3600 + atoi(t + 3) * 60 + atoi(t + 6) + 25;
  snprintf(app::dateText, sizeof app::dateText, "%c%c%c %d", toupper(d[0]), toupper(d[1]), toupper(d[2]), atoi(d + 4));
}

void setup() {
  Serial.setTxBufferSize(2048);
  Serial.begin(115200);
  Serial.setTxTimeoutMs(1);  // see logf(): nothing here may wait for a listener
  pinMode(pin::ENC_A, INPUT_PULLUP);
  pinMode(pin::ENC_B, INPUT_PULLUP);
  pinMode(pin::KEY, INPUT_PULLUP);
  pinMode(pin::LCD_TE, INPUT);

  prefs.begin("onx", false);
  rotation = prefs.getUChar("rot", 0) & 3;
  encDiv = prefs.getUChar("encdiv", 4);
  if (encDiv != 1 && encDiv != 2 && encDiv != 4) encDiv = 4;

  // The big frame buffer goes into internal RAM first: PSRAM is several times slower.
  size_t largest = heap_caps_get_largest_free_block(MALLOC_CAP_INTERNAL);
  gfx::FB = (uint32_t*)heap_caps_malloc(gfx::W * gfx::H * 4, MALLOC_CAP_INTERNAL);
  bool fbInternal = gfx::FB != nullptr;
  if (!gfx::FB) gfx::FB = (uint32_t*)heap_caps_malloc(gfx::W * gfx::H * 4, MALLOC_CAP_SPIRAM);
  for (auto& b : strip) b = (uint16_t*)heap_caps_malloc(gfx::W * STRIP_ROWS * 2, MALLOC_CAP_DMA | MALLOC_CAP_INTERNAL);
  gfx::bigAlloc = [](size_t n) -> void* { return heap_caps_malloc(n, MALLOC_CAP_SPIRAM); };
  app::PREV = (uint32_t*)heap_caps_malloc(gfx::W * gfx::H * 4, MALLOC_CAP_SPIRAM);
  if (!app::PREV) app::PREV = (uint32_t*)malloc(gfx::W * gfx::H * 4);

  lcd.init();
  lcd.setRotation(0);
  lcd.setBrightness(0);
  lcd.fillScreen(0);

  delay(300);  // give a serial monitor time to attach
  bool ok = gfx::FB && strip[0] && strip[1] && app::PREV;
  logf("\n[boot] ONX showcase, built %s %s\n", __DATE__, __TIME__);
  logf("[boot] psram %u KB, largest internal block %u KB, frame buffer in %s RAM, buffers %s\n",
                (unsigned)(ESP.getPsramSize() / 1024), (unsigned)(largest / 1024), fbInternal ? "internal" : "PSRAM",
                ok ? "ok" : "FAILED");
  if (!ok) { while (true) delay(1000); }
  memset(gfx::FB, 0, gfx::W * gfx::H * 4);
  memset(app::PREV, 0, gfx::W * gfx::H * 4);

  selfTest();
  lcd.startWrite();  // the bus is ours alone: keep the transaction open

  xTaskCreatePinnedToCore(inputTask, "input", 3072, nullptr, 5, nullptr, 0);
  attachInterrupt(pin::LCD_TE, teIsr, CHANGE);
  uint8_t ab = readAB();
  logf("[boot] knob A%d B%d, key %s, rotation %d, %d transition(s) per click\n", ab >> 1, ab & 1,
                digitalRead(pin::KEY) == LOW ? "down" : "up", rotation, encDiv);

  setClockFromBuild();
  app::rngState ^= esp_random() | 1;
  A.init();
}

void loop() {
  static uint32_t lastUs = micros(), statAt = millis(), frames = 0, usDraw = 0, usPush = 0, lastTe = 0;
  static uint32_t seenClicks = 0, seenHolds = 0;
  static float light = 0;
  uint32_t now = micros();
  float dt = constrain((now - lastUs) * 1e-6f, 0.001f, 0.1f);
  lastUs = now;

  app::Input in;
  in.dt = dt;
  in.delta = knobDelta();
  uint32_t clicks = keyClicks, holds = keyHolds;
  in.click = clicks != seenClicks;
  seenClicks = clicks;
  if (in.delta) logf("[knob] %+d\n", in.delta);
  if (in.click) logf("[key] click\n");
  if (holds != seenHolds) {
    seenHolds = holds;
    rotation = (rotation + 1) & 3;
    prefs.putUChar("rot", rotation);
    A.idle = 0;
    A.attract = false;
    logf("[key] held: rotation %d\n", rotation);
  }

  uint32_t t0 = micros();
  A.frame(in);
  uint32_t t1 = micros();
  waitForSafeStart();
  uint32_t t2 = micros();
  pushFrame();
  uint32_t t3 = micros();
  usDraw += t1 - t0;
  usPush += t3 - t2;
  frames++;

  if (light < 255) {  // fade the backlight in once there is a picture
    light = min(255.0f, light + dt * 500);
    lcd.setBrightness((uint8_t)light);
  }
  if (millis() - statAt >= 3000) {
    uint32_t te = teCount;
    uint8_t rp = rawPins;
    logf("[stat] %.1f fps, draw %.1f ms, push %.1f ms, vsync %.1f Hz (blank %lu of %lu us), scene %s%s, pins A%d B%d key%d, count %ld\n",
                  frames / 3.0f, usDraw / 1000.0f / frames, usPush / 1000.0f / frames, (te - lastTe) / 3.0f,
                  (unsigned long)teHighUs, (unsigned long)tePeriodUs, A.name(A.cur), A.attract ? " (demo)" : "", (rp >> 2) & 1, (rp >> 1) & 1, rp & 1, (long)encQ);
    lastTe = te;
    statAt = millis();
    frames = usDraw = usPush = 0;
  }
}
