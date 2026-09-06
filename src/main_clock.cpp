// ==============================================================================
// ESP32 7-Segment Digital Clock (4 Digits + Colon)
//
// Physical Chain & Wiring Order (114 LEDs Total):
//   1. Digit 0 (Hours Tens / Left):    28 LEDs (0..27)
//   2. Digit 1 (Hours Ones):           28 LEDs (28..55)
//   3. Colon (2 center dots):          2 LEDs  (56..57)
//   4. Digit 2 (Minutes Tens):         28 LEDs (58..85)
//   5. Digit 3 (Minutes Ones / Right): 28 LEDs (86..113)
//
// Each 7-segment display has 7 segments * 4 LEDs = 28 LEDs in exact order:
//   Segment 0: Bottom-Left (BL)  -> LEDs 0..3
//   Segment 1: Bottom (B)        -> LEDs 4..7
//   Segment 2: Bottom-Right (BR) -> LEDs 8..11
//   Segment 3: Middle (M)        -> LEDs 12..15
//   Segment 4: Top-Left (TL)     -> LEDs 16..19
//   Segment 5: Top (T)           -> LEDs 20..23
//   Segment 6: Top-Right (TR)    -> LEDs 24..27
// ==============================================================================

#include <Arduino.h>
#include <Adafruit_NeoPixel.h>
#include <ThreeWire.h>
#include <RtcDS1302.h>
#include <NimBLEDevice.h>
#include "ble_fota.h"
#if defined(ESP32)
  #include "driver/gpio.h"
#endif

// ==============================================================================
// Hardware Configuration
// ==============================================================================
#if defined(CONFIG_IDF_TARGET_ESP32C3)
  #define LED_PIN           2      // WS2812 Data Pin on ESP32-C3 SuperMini (GPIO 2)
  #define ONBOARD_LED_PIN   8      // ESP32-C3 SuperMini LED (GPIO 8, Active LOW)
  #define DS1302_CLK_PIN    4      // RTC SCLK
  #define DS1302_DAT_PIN    5      // RTC DAT / IO
  #define DS1302_RST_PIN    3      // RTC RST / CE
#else
  #define LED_PIN           15     // WS2812 Data Pin on ESP32-S3 Zero (GPIO 15)
  #define ONBOARD_RGB_PIN   21     // Waveshare ESP32-S3 Zero On-board RGB (GPIO 21)
  #define DS1302_CLK_PIN    4      // RTC SCLK -> GPIO 4
  #define DS1302_DAT_PIN    5      // RTC DAT / IO -> GPIO 5
  #define DS1302_RST_PIN    6      // RTC RST / CE -> GPIO 6
#endif

#define NUM_DIGITS        4      // 4 Digits (HH:MM)
#define LEDS_PER_SEGMENT  4      // 4 LEDs per segment
#define LEDS_PER_DIGIT    28     // 7 segments * 4 LEDs = 28 LEDs per digit
#define COLON_LEDS        2      // 2 LEDs for the colon
#define NUMPIXELS         (NUM_DIGITS * LEDS_PER_DIGIT + COLON_LEDS) // 114 LEDs total

// ==============================================================================
// Clock & Display Customization Options
// ==============================================================================
#define BRIGHTNESS              180   // LED brightness (0 - 255)
#define USE_24HOUR_FORMAT       true  // true: 24h (13:45), false: 12h (1:45)
#define LEADING_ZERO            false // true: "09:45", false: " 9:45" (blank leading hour zero)
#define BLINK_COLON             true  // true: Colon blinks every second, false: Solid ON
#define COLOR_CYCLE_PERIOD_MS   6000  // Transition smoothly between palette colors every 6s

// ==============================================================================
// Curated Color Palette (Smooth Transitions)
// ==============================================================================
struct RGBColor {
  uint8_t r, g, b;
};

const RGBColor colorPalette[] = {
  { 255, 240, 200 }, // Warm White
  { 0,   220, 255 }, // Vivid Cyan / Ice Blue
  { 255, 100, 0   }, // Amber / Orange
  { 0,   255, 130 }, // Mint / Emerald Green
  { 255, 30,  150 }, // Hot Pink / Magenta
  { 255, 215, 0   }, // Warm Gold
  { 170, 40,  255 }, // Electric Violet
  { 255, 60,  60  }  // Coral Red
};
const int NUM_PALETTE_COLORS = sizeof(colorPalette) / sizeof(colorPalette[0]);

// ==============================================================================
// Hardware Instances
// ==============================================================================
Adafruit_NeoPixel pixels(NUMPIXELS, LED_PIN, NEO_GRB + NEO_KHZ800);

#if !defined(CONFIG_IDF_TARGET_ESP32C3)
Adafruit_NeoPixel onboardLed(1, ONBOARD_RGB_PIN, NEO_GRB + NEO_KHZ800);
#endif

ThreeWire rtcWire(DS1302_DAT_PIN, DS1302_CLK_PIN, DS1302_RST_PIN);
RtcDS1302<ThreeWire> Rtc(rtcWire);

// State
bool rtcAvailable = false;
int curHour   = 12;
int curMinute = 0;
int curSecond = 0;
uint32_t lastInternalTick = 0;

// ==============================================================================
// 7-Segment Font Table
// Segment Order per Digit:
//   [0] BL (Bottom-Left)
//   [1] B  (Bottom)
//   [2] BR (Bottom-Right)
//   [3] M  (Middle)
//   [4] TL (Top-Left)
//   [5] T  (Top)
//   [6] TR (Top-Right)
// ==============================================================================
const byte numbers[11][7] = {
  // BL, B, BR, M, TL, T, TR
  {   1, 1,  1, 0,  1, 1,  1 }, // 0: BL, B, BR, TL, T, TR
  {   0, 0,  1, 0,  0, 0,  1 }, // 1: BR, TR
  {   1, 1,  0, 1,  0, 1,  1 }, // 2: BL, B, M, T, TR
  {   0, 1,  1, 1,  0, 1,  1 }, // 3: B, BR, M, T, TR
  {   0, 0,  1, 1,  1, 0,  1 }, // 4: BR, M, TL, TR
  {   0, 1,  1, 1,  1, 1,  0 }, // 5: B, BR, M, TL, T
  {   1, 1,  1, 1,  1, 1,  0 }, // 6: BL, B, BR, M, TL, T
  {   0, 0,  1, 0,  0, 1,  1 }, // 7: BR, T, TR
  {   1, 1,  1, 1,  1, 1,  1 }, // 8: All ON
  {   0, 1,  1, 1,  1, 1,  1 }, // 9: B, BR, M, TL, T, TR
  {   0, 0,  0, 0,  0, 0,  0 }  // 10: Blank
};

// ==============================================================================
// Helper Functions
// ==============================================================================
void setStatusLed(uint8_t r, uint8_t g, uint8_t b) {
#if defined(CONFIG_IDF_TARGET_ESP32C3)
  pinMode(ONBOARD_LED_PIN, OUTPUT);
  digitalWrite(ONBOARD_LED_PIN, (r > 0 || g > 0 || b > 0) ? LOW : HIGH);
#else
  onboardLed.setPixelColor(0, onboardLed.Color(r, g, b));
  onboardLed.show();
#endif
}

// Calculate starting LED index for digit d (0, 1, 2, 3)
// Chain: Digit 0 -> Digit 1 -> Colon -> Digit 2 -> Digit 3
int getDigitBaseLed(int digitIndex) {
  if (digitIndex < 2) {
    return digitIndex * LEDS_PER_DIGIT;                 // Digit 0: 0..27, Digit 1: 28..55
  } else {
    return (digitIndex * LEDS_PER_DIGIT) + COLON_LEDS;  // Digit 2: 58..85, Digit 3: 86..113
  }
}

int getColonBaseLed() {
  return 2 * LEDS_PER_DIGIT; // Index 56 (LEDs 56 and 57)
}

// ==============================================================================
// 7-Segment Hardware Remapping (Panel 1 Custom Wiring)
// ==============================================================================
// Logical segment indices: [0]BL, [1]B, [2]BR, [3]M, [4]TL, [5]T, [6]TR
// Standard Panels (Digits 1, 2, 3): Slot 0=BL, Slot 1=B, Slot 2=BR, Slot 3=M, Slot 4=TL, Slot 5=T, Slot 6=TR
// First Panel (Digit 0) Hardware Variation: First segment is TR (Slot 0=TR, Slot 1=T, Slot 2=TL, Slot 3=M, Slot 4=BR, Slot 5=B, Slot 6=BL)
#define PANEL0_CUSTOM_WIRING true

#if PANEL0_CUSTOM_WIRING
// Maps logical segment index [0..6] to physical 4-LED slot on Digit 0:
// BL(0)->Slot 6, B(1)->Slot 5, BR(2)->Slot 4, M(3)->Slot 3, TL(4)->Slot 2, T(5)->Slot 1, TR(6)->Slot 0
const uint8_t panel0SegmentMap[7] = { 6, 5, 4, 3, 2, 1, 0 };
#endif

// Draw a single number (0-9 or 10=blank) onto a digit
void drawDigit(int digitIndex, int num, uint32_t color) {
  if (digitIndex < 0 || digitIndex >= NUM_DIGITS) return;
  if (num < 0 || num > 10) num = 10;

  int baseLed = getDigitBaseLed(digitIndex);
  for (int seg = 0; seg < 7; seg++) {
#if PANEL0_CUSTOM_WIRING
    int physSeg = (digitIndex == 0) ? panel0SegmentMap[seg] : seg;
#else
    int physSeg = seg;
#endif
    int startPixel = baseLed + (physSeg * LEDS_PER_SEGMENT);
    bool segOn = (numbers[num][seg] == 1);
    for (int i = 0; i < LEDS_PER_SEGMENT; i++) {
      int p = startPixel + i;
      if (p >= 0 && p < NUMPIXELS) {
        pixels.setPixelColor(p, segOn ? color : 0);
      }
    }
  }
}

// Draw colon dots
void drawColon(bool show, uint32_t color) {
  int colonBase = getColonBaseLed();
  for (int i = 0; i < COLON_LEDS; i++) {
    pixels.setPixelColor(colonBase + i, show ? color : 0);
  }
}

// Smooth crossfade across colorPalette quantized to 500ms steps to match colon blink
uint32_t getFadedColor() {
  uint32_t ms = (millis() / 500) * 500; // Quantized to 500ms to eliminate continuous RMT bus spam
  int colorIndex = (ms / COLOR_CYCLE_PERIOD_MS) % NUM_PALETTE_COLORS;
  int nextIndex = (colorIndex + 1) % NUM_PALETTE_COLORS;

  float progress = (float)(ms % COLOR_CYCLE_PERIOD_MS) / (float)COLOR_CYCLE_PERIOD_MS;
  // S-curve easing
  float eased = (1.0f - cosf(progress * 3.14159265f)) * 0.5f;

  uint8_t r = (uint8_t)(colorPalette[colorIndex].r + (colorPalette[nextIndex].r - colorPalette[colorIndex].r) * eased);
  uint8_t g = (uint8_t)(colorPalette[colorIndex].g + (colorPalette[nextIndex].g - colorPalette[colorIndex].g) * eased);
  uint8_t b = (uint8_t)(colorPalette[colorIndex].b + (colorPalette[nextIndex].b - colorPalette[colorIndex].b) * eased);

  return pixels.Color(r, g, b);
}

// Parse compile time "__TIME__" (hh:mm:ss) as initial fallback
void initFallbackTime() {
  const char* t = __TIME__;
  curHour   = (t[0] - '0') * 10 + (t[1] - '0');
  curMinute = (t[3] - '0') * 10 + (t[4] - '0');
  curSecond = (t[6] - '0') * 10 + (t[7] - '0');
}

// ==============================================================================
// Safe WS2812 Show Helper (Eliminates ESP32-C3 Single-Core BLE Glitches)
// ==============================================================================
void showPixelsSafe() {
  bool wasAdvertising = false;
  NimBLEAdvertising* pAdv = NimBLEDevice::getAdvertising();
  if (pAdv != nullptr && pAdv->isAdvertising()) {
    wasAdvertising = true;
    pAdv->stop();
  }

  delayMicroseconds(400);

#if defined(CONFIG_IDF_TARGET_ESP32C3)
  gpio_set_drive_capability((gpio_num_t)LED_PIN, GPIO_DRIVE_CAP_3);
#endif

  pixels.show();

#if defined(CONFIG_IDF_TARGET_ESP32C3)
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  delayMicroseconds(350);
#endif

  if (wasAdvertising) {
    pAdv->start();
  }
}

// ==============================================================================
// Arduino Setup & Loop
// ==============================================================================
void setup() {
  Serial.begin(115200);
  delay(500);

  Serial.println("\n=======================================================");
  Serial.println("   7-Segment 4-Digit + Colon Clock                     ");
  Serial.println("   Wiring: D0 -> D1 -> Colon -> D2 -> D3 (114 LEDs)    ");
  Serial.println("=======================================================");

#if defined(CONFIG_IDF_TARGET_ESP32C3)
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  gpio_set_drive_capability((gpio_num_t)LED_PIN, GPIO_DRIVE_CAP_3);
#endif

  // Initialize NeoPixels
  pixels.begin();
  pixels.setBrightness(BRIGHTNESS);
  pixels.clear();
  showPixelsSafe();

#if !defined(CONFIG_IDF_TARGET_ESP32C3)
  onboardLed.begin();
  onboardLed.setBrightness(50);
  setStatusLed(0, 0, 50); // Blue standby
#endif

  // Initialize DS1302 Real-Time Clock
  Rtc.Begin();

  if (!Rtc.GetIsRunning()) {
    Serial.println("[RTC] Not running; starting clock now...");
    Rtc.SetIsRunning(true);
  }
  if (Rtc.GetIsWriteProtected()) {
    Rtc.SetIsWriteProtected(false);
  }

  // Check if RTC gives a valid time
  RtcDateTime compiledTime = RtcDateTime(__DATE__, __TIME__);
  if (!Rtc.IsDateTimeValid()) {
    Serial.println("[RTC] Warning: RTC DateTime is not valid! Setting RTC to build timestamp...");
    Rtc.SetDateTime(compiledTime);
  }

  RtcDateTime now = Rtc.GetDateTime();
  if (now.IsValid() && now.Year() >= 2024 && now.Year() <= 2099) {
    rtcAvailable = true;
    curHour   = now.Hour();
    curMinute = now.Minute();
    curSecond = now.Second();
    Serial.printf("[RTC] Synced successfully: %02d:%02d:%02d\n", curHour, curMinute, curSecond);
    setStatusLed(0, 50, 0); // Green: RTC ready
  } else {
    rtcAvailable = false;
    initFallbackTime();
    Serial.printf("[RTC] RTC not detected or uninitialized. Using internal timer starting at: %02d:%02d:%02d\n", curHour, curMinute, curSecond);
    setStatusLed(50, 25, 0); // Orange: Software timer mode
  }

  // Initialize BLE FOTA Service
  NimBLEDevice::init("Padel-Clock");
  NimBLEServer* pServer = NimBLEDevice::createServer();
  BleFota::init(pServer, "Padel-Clock-OTA");
  BleFota::setCallbacks(
    [](int percent) {
      pixels.clear();
      drawDigit(0, (percent / 10) % 10, pixels.Color(0, 200, 255));
      drawDigit(1, percent % 10, pixels.Color(0, 200, 255));
      drawDigit(2, (percent / 10) % 10, pixels.Color(0, 200, 255));
      drawDigit(3, percent % 10, pixels.Color(0, 200, 255));
      showPixelsSafe();
    },
    [](bool inProgress, bool success) {
      if (!inProgress && success) {
        pixels.clear();
        for (int i = 0; i < NUMPIXELS; i++) pixels.setPixelColor(i, pixels.Color(0, 255, 0));
        showPixelsSafe();
      }
    }
  );
  pServer->start();

  NimBLEAdvertising* pAdvertising = NimBLEDevice::getAdvertising();
  pAdvertising->setName("Padel-Clock-OTA");
  pAdvertising->addServiceUUID(BLE_FOTA_SERVICE_UUID);
  pAdvertising->setMinInterval(160); // 100ms
  pAdvertising->setMaxInterval(320); // 200ms
  pAdvertising->start();

  lastInternalTick = millis();
}

void loop() {
  if (BleFota::isUpdating()) {
    delay(100);
    return;
  }

  static uint32_t lastRtcPoll = 0;
  static int lastPrintedSecond = -1;

  // Poll RTC or update internal tick every second
  if (rtcAvailable) {
    if (millis() - lastRtcPoll >= 250) {
      lastRtcPoll = millis();
      RtcDateTime now = Rtc.GetDateTime();
      if (now.IsValid()) {
        curHour   = now.Hour();
        curMinute = now.Minute();
        curSecond = now.Second();
      }
    }
  } else {
    // Internal software second counter
    if (millis() - lastInternalTick >= 1000) {
      lastInternalTick += 1000;
      curSecond++;
      if (curSecond >= 60) {
        curSecond = 0;
        curMinute++;
        if (curMinute >= 60) {
          curMinute = 0;
          curHour = (curHour + 1) % 24;
        }
      }
    }
  }

  // Log to serial once per second
  if (curSecond != lastPrintedSecond) {
    lastPrintedSecond = curSecond;
    Serial.printf("[CLOCK] %02d:%02d:%02d (%s)\n",
                  curHour, curMinute, curSecond,
                  rtcAvailable ? "RTC" : "Internal Soft-Clock");
  }

  // Convert hour based on 12h/24h preference
  int displayHour = curHour;
  if (!USE_24HOUR_FORMAT) {
    displayHour = curHour % 12;
    if (displayHour == 0) displayHour = 12;
  }

  // Digits: d0 (Hour tens), d1 (Hour ones), d2 (Minute tens), d3 (Minute ones)
  int d0 = displayHour / 10;
  int d1 = displayHour % 10;
  int d2 = curMinute / 10;
  int d3 = curMinute % 10;

  // Blank leading zero if desired
  if (!LEADING_ZERO && d0 == 0) {
    d0 = 10; // 10 = Blank in numbers table
  }

  // Dynamic color (quantized to 500ms intervals)
  uint32_t activeColor = getFadedColor();

  // Colon blink logic: ON for 500ms, OFF for 500ms
  bool showColon = BLINK_COLON ? ((millis() % 1000) < 500) : true;

  // Redraw ONLY when state changes (colon toggle, second tick, or color transition)
  // This reduces RMT transmissions from 50Hz to 2Hz, completely eliminating RMT FIFO underruns and green flashes
  static int last_d0 = -1, last_d1 = -1, last_d2 = -1, last_d3 = -1;
  static bool last_showColon = false;
  static uint32_t last_color = 0;

  bool needsRedraw = (d0 != last_d0 || d1 != last_d1 || d2 != last_d2 || d3 != last_d3 ||
                      showColon != last_showColon || activeColor != last_color);

  if (needsRedraw) {
    last_d0 = d0;
    last_d1 = d1;
    last_d2 = d2;
    last_d3 = d3;
    last_showColon = showColon;
    last_color = activeColor;

    pixels.clear();
    drawDigit(0, d0, activeColor);
    drawDigit(1, d1, activeColor);
    drawColon(showColon, activeColor);
    drawDigit(2, d2, activeColor);
    drawDigit(3, d3, activeColor);
    showPixelsSafe();
  }

  delay(30);
}
