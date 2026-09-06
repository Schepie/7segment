// ==============================================================================
// 7-Segment Display Counter: 00 to 99
// Counts up from 00 to 99 and repeats
// Supports Panel 0 custom wiring (TR first) and standard wiring (BL first)
// ==============================================================================

#include <Arduino.h>
#include <Adafruit_NeoPixel.h>

#if defined(CONFIG_IDF_TARGET_ESP32C3)
  #define LED_PIN         2   // GPIO 2 on ESP32-C3 SuperMini
  #define ONBOARD_LED_PIN 8   // Active LOW onboard LED
#else
  #define LED_PIN         15  // GPIO 15 on ESP32-S3 Zero
  #define ONBOARD_RGB_PIN 21
#endif

#define NUM_DIGITS        4
#define LEDS_PER_SEGMENT  4
#define LEDS_PER_DIGIT    28  // 7 segments * 4 LEDs
#define COLON_LEDS        2
#define NUMPIXELS         (NUM_DIGITS * LEDS_PER_DIGIT + COLON_LEDS) // 114 LEDs
#define BRIGHTNESS        180

Adafruit_NeoPixel pixels(NUMPIXELS, LED_PIN, NEO_GRB + NEO_KHZ800);

// ==============================================================================
// 7-Segment Font & Wiring Mapping
// ==============================================================================
// Standard Segment Order:
//   [0] BL (Bottom-Left)
//   [1] B  (Bottom)
//   [2] BR (Bottom-Right)
//   [3] M  (Middle)
//   [4] TL (Top-Left)
//   [5] T  (Top)
//   [6] TR (Top-Right)
const uint8_t numbers[10][7] = {
  // BL, B, BR, M, TL, T, TR
  {   1, 1,  1, 0,  1, 1,  1 }, // 0
  {   0, 0,  1, 0,  0, 0,  1 }, // 1
  {   1, 1,  0, 1,  0, 1,  1 }, // 2
  {   0, 1,  1, 1,  0, 1,  1 }, // 3
  {   0, 0,  1, 1,  1, 0,  1 }, // 4
  {   0, 1,  1, 1,  1, 1,  0 }, // 5
  {   1, 1,  1, 1,  1, 1,  0 }, // 6
  {   0, 0,  1, 0,  0, 1,  1 }, // 7
  {   1, 1,  1, 1,  1, 1,  1 }, // 8
  {   0, 1,  1, 1,  1, 1,  1 }  // 9
};

// Panel 0 (First Panel) Custom Wiring: First segment is TR instead of BL
// BL(0)->Slot 6, B(1)->Slot 5, BR(2)->Slot 4, M(3)->Slot 3, TL(4)->Slot 2, T(5)->Slot 1, TR(6)->Slot 0
#define PANEL0_CUSTOM_WIRING 1
const uint8_t panel0SegmentMap[7] = { 6, 5, 4, 3, 2, 1, 0 };

int getDigitBaseLed(int digitIndex) {
  if (digitIndex < 2) {
    return digitIndex * LEDS_PER_DIGIT;
  } else {
    return (digitIndex * LEDS_PER_DIGIT) + COLON_LEDS;
  }
}

void drawDigit(int digitIndex, int num, uint32_t color) {
  if (digitIndex < 0 || digitIndex >= NUM_DIGITS) return;
  if (num < 0 || num > 9) return;

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

void drawColon(bool show, uint32_t color) {
  int colonBase = 2 * LEDS_PER_DIGIT; // Index 56
  for (int i = 0; i < COLON_LEDS; i++) {
    pixels.setPixelColor(colonBase + i, show ? color : 0);
  }
}

void displayCounter(int count) {
  pixels.clear();

  int tens = (count / 10) % 10;
  int ones = count % 10;

  uint32_t colorBlue = pixels.Color(0, 200, 255); // Cyan / Ice Blue
  uint32_t colorRed  = pixels.Color(255, 40, 40);  // Vivid Red
  uint32_t colorCol  = pixels.Color(180, 180, 180);

  // Digits 0 and 1: 00 to 99
  drawDigit(0, tens, colorBlue);
  drawDigit(1, ones, colorBlue);

  // Colon dot
  drawColon(true, colorCol);

  // Digits 2 and 3: same counter (if connected)
  drawDigit(2, tens, colorRed);
  drawDigit(3, ones, colorRed);

  pixels.show();
}

void setup() {
  Serial.begin(115200);
  delay(200);

#if defined(CONFIG_IDF_TARGET_ESP32C3)
  pinMode(ONBOARD_LED_PIN, OUTPUT);
  digitalWrite(ONBOARD_LED_PIN, LOW);
#endif

  pixels.begin();
  pixels.setBrightness(BRIGHTNESS);
  pixels.clear();
  pixels.show();

  Serial.println("=================================================");
  Serial.printf("   7-Segment Counter 00 -> 99 on GPIO %d          \n", LED_PIN);
  Serial.println("=================================================");
}

int currentCount = 0;

void loop() {
  displayCounter(currentCount);
  Serial.printf("[COUNTER] %02d\n", currentCount);

  // Toggle onboard LED on each count
#if defined(CONFIG_IDF_TARGET_ESP32C3)
  digitalWrite(ONBOARD_LED_PIN, (currentCount % 2 == 0) ? LOW : HIGH);
#endif

  currentCount++;
  if (currentCount > 99) {
    currentCount = 0;
  }

  // Count step interval: 600ms per number
  delay(600);
}
