#include <Arduino.h>
#include <Adafruit_NeoPixel.h>
#include <ThreeWire.h>
#include <RtcDS1302.h>

// =========================================================================
// Hardware & Pin Configuration
// =========================================================================
#define LED_PIN           2    // WS2812 Data Pin (ESP32-C3: GPIO 2)
#define NUM_DIGITS        4    // 4 Digits (HH:MM)
#define LEDS_PER_SEGMENT  4    // 4 LEDs per segment
#define LEDS_PER_DIGIT    28   // 7 segments * 4 LEDs = 28 LEDs per digit
#define COLON_LEDS        2    // Number of LEDs in the colon (typically 2, 1 per dot)

// Total LEDs on strip = 4 digits * 28 + colon = 114 LEDs
#define NUMPIXELS         (NUM_DIGITS * LEDS_PER_DIGIT + COLON_LEDS)

// DS1302 RTC Pin Connections
#define DS1302_CLK_PIN    4    // Clock (SCLK) -> GPIO 4
#define DS1302_DAT_PIN    5    // Data (DAT / IO) -> GPIO 5
#define DS1302_RST_PIN    3    // Reset / Chip Enable (RST / CE) -> GPIO 3

// =========================================================================
// Clock & Display Customization Options
// =========================================================================
#define BRIGHTNESS              220   // Display brightness (0 to 255)
#define LEADING_ZERO            false // true: "09:45", false: " 9:45" (blank leading zero)
#define BLINK_COLON             true  // true: Colon blinks every second, false: Solid ON
#define COLOR_CYCLE_PERIOD_MS   5000  // Transition to a new color every 5 seconds (5000 ms)

// Colon Wiring Position in the LED Strip chain:
// 0: Between Digits 2 and 3 (Digit 1 -> Digit 2 -> COLON -> Digit 3 -> Digit 4)
#define COLON_CHAIN_POS   0

// =========================================================================
// Color Palette (Curated vibrant colors for 5-second crossfades)
// =========================================================================
struct RGBColor {
  uint8_t r, g, b;
};

const RGBColor colorPalette[] = {
  { 255, 240, 200 }, // Warm White
  { 0,   235, 255 }, // Vivid Cyan / Ice Blue
  { 255, 80,  0   }, // Sunset Amber / Orange
  { 0,   255, 120 }, // Emerald Green
  { 255, 25,  160 }, // Magenta Pink
  { 255, 210, 0   }, // Golden Yellow
  { 170, 30,  255 }, // Electric Purple / Violet
  { 255, 50,  70  }  // Coral Red
};
const int NUM_PALETTE_COLORS = sizeof(colorPalette) / sizeof(colorPalette[0]);

// =========================================================================
// Hardware Instances
// =========================================================================
Adafruit_NeoPixel pixels(NUMPIXELS, LED_PIN, NEO_GRB + NEO_KHZ800);
ThreeWire rtcWire(DS1302_DAT_PIN, DS1302_CLK_PIN, DS1302_RST_PIN);
RtcDS1302<ThreeWire> Rtc(rtcWire);

// =========================================================================
// 7-Segment Font & Mapping Table
// Segment wiring order according to your diagram:
// Index 0: Segment A (Bottom-Left)  -> LEDs 0..3
// Index 1: Segment B (Bottom)       -> LEDs 4..7
// Index 2: Segment C (Bottom-Right) -> LEDs 8..11
// Index 3: Segment D (Middle)       -> LEDs 12..15
// Index 4: Segment E (Top-Left)     -> LEDs 16..19
// Index 5: Segment F (Top)          -> LEDs 20..23
// Index 6: Segment G (Top-Right)    -> LEDs 24..27
// =========================================================================
const byte numbers[11][7] = {
  // A  B  C  D  E  F  G
  {  1, 1, 1, 0, 1, 1, 1 }, // 0: A, B, C, E, F, G (all except D)
  {  0, 0, 1, 0, 0, 0, 1 }, // 1: C, G
  {  1, 1, 0, 1, 0, 1, 1 }, // 2: F, G, D, A, B
  {  0, 1, 1, 1, 0, 1, 1 }, // 3: F, G, D, C, B
  {  0, 0, 1, 1, 1, 0, 1 }, // 4: E, G, D, C
  {  0, 1, 1, 1, 1, 1, 0 }, // 5: F, E, D, C, B
  {  1, 1, 1, 1, 1, 1, 0 }, // 6: F, E, D, A, C, B
  {  0, 0, 1, 0, 0, 1, 1 }, // 7: F, G, C
  {  1, 1, 1, 1, 1, 1, 1 }, // 8: All ON
  {  0, 1, 1, 1, 1, 1, 1 }, // 9: F, E, G, D, C, B
  {  0, 0, 0, 0, 0, 0, 0 }  // 10: Blank
};

// Logical segment starting indices relative to the digit's base LED
const int segmentOffsets[7] = {
  0 * LEDS_PER_SEGMENT,  // 0: A (Bottom-Left)
  1 * LEDS_PER_SEGMENT,  // 1: B (Bottom)
  2 * LEDS_PER_SEGMENT,  // 2: C (Bottom-Right)
  3 * LEDS_PER_SEGMENT,  // 3: D (Middle)
  4 * LEDS_PER_SEGMENT,  // 4: E (Top-Left)
  5 * LEDS_PER_SEGMENT,  // 5: F (Top)
  6 * LEDS_PER_SEGMENT   // 6: G (Top-Right)
};

// Helper: Calculate starting LED index for each digit (0 to 3) based on colon position
int getDigitLedOffset(int digitIndex) {
#if COLON_CHAIN_POS == 0
  if (digitIndex < 2) {
    return digitIndex * LEDS_PER_DIGIT;
  } else {
    return (digitIndex * LEDS_PER_DIGIT) + COLON_LEDS;
  }
#elif COLON_CHAIN_POS == 1
  return digitIndex * LEDS_PER_DIGIT;
#elif COLON_CHAIN_POS == 2
  return COLON_LEDS + (digitIndex * LEDS_PER_DIGIT);
#endif
}

// Helper: Calculate starting LED index for the colon
int getColonLedOffset() {
#if COLON_CHAIN_POS == 0
  return 2 * LEDS_PER_DIGIT; // Right after digit 2 (Hours ones)
#elif COLON_CHAIN_POS == 1
  return 4 * LEDS_PER_DIGIT; // After all 4 digits
#elif COLON_CHAIN_POS == 2
  return 0;                  // First in chain
#endif
}

// Compute smooth color fade across palette based on current millisecond
uint32_t getFadedColor() {
  uint32_t ms = millis();
  int colorIndex = (ms / COLOR_CYCLE_PERIOD_MS) % NUM_PALETTE_COLORS;
  int nextIndex = (colorIndex + 1) % NUM_PALETTE_COLORS;

  // Linear progression 0.0 -> 1.0 within the 5-second interval
  float progress = (float)(ms % COLOR_CYCLE_PERIOD_MS) / (float)COLOR_CYCLE_PERIOD_MS;

  // Smooth cosine S-curve easing
  float eased = (1.0f - cosf(progress * 3.14159265f)) * 0.5f;

  uint8_t r = (uint8_t)(colorPalette[colorIndex].r + (colorPalette[nextIndex].r - colorPalette[colorIndex].r) * eased);
  uint8_t g = (uint8_t)(colorPalette[colorIndex].g + (colorPalette[nextIndex].g - colorPalette[colorIndex].g) * eased);
  uint8_t b = (uint8_t)(colorPalette[colorIndex].b + (colorPalette[nextIndex].b - colorPalette[colorIndex].b) * eased);

  return pixels.Color(r, g, b);
}

// Draw a single number (0-9 or 10=blank) onto a digit
void drawDigit(int digitIndex, int num, uint32_t color) {
  int baseLed = getDigitLedOffset(digitIndex);
  if (num < 0 || num > 10) num = 10;

  for (int seg = 0; seg < 7; seg++) {
    if (numbers[num][seg] == 1) {
      int startPixel = baseLed + segmentOffsets[seg];
      for (int i = 0; i < LEDS_PER_SEGMENT; i++) {
        pixels.setPixelColor(startPixel + i, color);
      }
    }
  }
}

// Draw the colon dots
void drawColon(bool show, uint32_t color) {
  int colonStart = getColonLedOffset();
  for (int i = 0; i < COLON_LEDS; i++) {
    pixels.setPixelColor(colonStart + i, show ? color : 0);
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000); // Allow USB Serial to attach

  Serial.println("\n=======================================================");
  Serial.println("   7-Segment 4-Digit Clock with 5s Color Crossfade     ");
  Serial.println("=======================================================");

  // Initialize NeoPixel LED Strip
  pixels.begin();
  pixels.setBrightness(BRIGHTNESS);
  pixels.clear();
  pixels.show();

  // Initialize DS1302 Real-Time Clock
  Rtc.Begin();

  if (!Rtc.GetIsRunning()) {
    Serial.println("RTC was not actively running, starting clock now...");
    Rtc.SetIsRunning(true);
  }

  if (Rtc.GetIsWriteProtected()) {
    Rtc.SetIsWriteProtected(false);
  }

  Serial.println("Setup complete! Starting clock display loop...\n");
}

void loop() {
  static uint32_t lastRtcRead = 0;
  static RtcDateTime currentTime;
  static int lastLoggedSecond = -1;

  // Poll RTC every 200 ms
  if (millis() - lastRtcRead > 200 || lastRtcRead == 0) {
    lastRtcRead = millis();
    RtcDateTime rtcNow = Rtc.GetDateTime();
    if (rtcNow.IsValid()) {
      currentTime = rtcNow;
    }
  }

  int hours = currentTime.Hour();
  int minutes = currentTime.Minute();
  int seconds = currentTime.Second();

  // Log to serial monitor once per second
  if (seconds != lastLoggedSecond && currentTime.IsValid()) {
    lastLoggedSecond = seconds;
    Serial.printf("[%04d-%02d-%02d] %02d:%02d:%02d\n",
                  currentTime.Year(), currentTime.Month(), currentTime.Day(),
                  hours, minutes, seconds);
  }

  // Extract individual digits
  int d0 = hours / 10;
  int d1 = hours % 10;
  int d2 = minutes / 10;
  int d3 = minutes % 10;

  if (!LEADING_ZERO && d0 == 0) {
    d0 = 10; // Blank leading zero
  }

  // Calculate current interpolated crossfade color (smooth 50 FPS)
  uint32_t activeColor = getFadedColor();

  // Colon blink logic (odd seconds ON, even seconds OFF)
  bool showColon = BLINK_COLON ? (seconds % 2 == 0) : true;

  // Render frame
  pixels.clear();
  drawDigit(0, d0, activeColor);
  drawDigit(1, d1, activeColor);
  drawDigit(2, d2, activeColor);
  drawDigit(3, d3, activeColor);
  drawColon(showColon, activeColor);

  pixels.show();

  // 20ms delay yields silky-smooth 50 FPS crossfade transitions
  delay(20);
}

