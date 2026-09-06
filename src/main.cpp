// ==============================================================================
// ESP32 Padel Scoreboard - 4-Digit + Colon BLE Score Display
// 
// Physical Chain & Wiring Order (114 LEDs Total):
//   1. Digit 1 (Tens Team 1 / Left):   28 LEDs (0..27)
//   2. Digit 2 (Ones Team 1 / Left):   28 LEDs (28..55)
//   3. Colon (Semi-colon dots):        2 LEDs  (56..57)
//   4. Digit 3 (Tens Team 2 / Right):  28 LEDs (58..85)
//   5. Digit 4 (Ones Team 2 / Right):  28 LEDs (86..113)
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

#include <Adafruit_NeoPixel.h>
#include <Arduino.h>
#include <NimBLEDevice.h>
#include "ble_fota.h"

// ==============================================================================
// Hardware Configuration
// ==============================================================================
#if defined(CONFIG_IDF_TARGET_ESP32C3)
  #define LED_PIN           2      // WS2812 Data Pin on ESP32-C3 SuperMini (GPIO 2)
  #define ONBOARD_LED_PIN   8      // ESP32-C3 SuperMini LED (GPIO 8, Active LOW)
#else
  #define LED_PIN           15     // WS2812 Data Pin on ESP32-S3 Zero (GPIO 15)
  #define ONBOARD_RGB_PIN   21     // Waveshare ESP32-S3 Zero On-board RGB (GPIO 21)
#endif

#define NUM_DIGITS        4      // 4 Digits total (2 for Team 1, 2 for Team 2)
#define LEDS_PER_SEGMENT  4      // 4 LEDs per segment
#define LEDS_PER_DIGIT    28     // 7 segments * 4 LEDs = 28 LEDs per digit
#define COLON_LEDS        2      // 2 LEDs for colon between Digit 2 and Digit 3
#define NUMPIXELS         (NUM_DIGITS * LEDS_PER_DIGIT + COLON_LEDS) // 114 LEDs total
#define BRIGHTNESS        180    // LED brightness (0 - 255)

// ==============================================================================
// BLE Server Configuration
// ==============================================================================
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// ==============================================================================
// Hardware Instances & State
// ==============================================================================
Adafruit_NeoPixel pixels(NUMPIXELS, LED_PIN, NEO_GRB + NEO_KHZ800);

#if !defined(CONFIG_IDF_TARGET_ESP32C3)
Adafruit_NeoPixel onboardLed(1, ONBOARD_RGB_PIN, NEO_GRB + NEO_KHZ800);
#endif

std::string currentScore = "0000";
bool newScoreReceived = false;
bool isSwitched = false;
bool triggerConnectAnimation = false;

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
const byte numbers[13][7] = {
  // BL, B, BR, M, TL, T, TR
  {   1, 1,  1, 0,  1, 1,  1 }, // 0: BL, B, BR, TL, T, TR (all except Middle)
  {   0, 0,  1, 0,  0, 0,  1 }, // 1: BR, TR
  {   1, 1,  0, 1,  0, 1,  1 }, // 2: BL, B, M, T, TR
  {   0, 1,  1, 1,  0, 1,  1 }, // 3: B, BR, M, T, TR
  {   0, 0,  1, 1,  1, 0,  1 }, // 4: BR, M, TL, TR
  {   0, 1,  1, 1,  1, 1,  0 }, // 5: B, BR, M, TL, T
  {   1, 1,  1, 1,  1, 1,  0 }, // 6: BL, B, BR, M, TL, T
  {   0, 0,  1, 0,  0, 1,  1 }, // 7: BR, T, TR
  {   1, 1,  1, 1,  1, 1,  1 }, // 8: All ON
  {   0, 1,  1, 1,  1, 1,  1 }, // 9: B, BR, M, TL, T, TR
  {   0, 0,  0, 0,  0, 0,  0 }, // 10: Blank
  {   1, 0,  1, 1,  1, 1,  1 }, // 11: 'A' (Advantage)
  {   1, 1,  1, 1,  0, 0,  1 }  // 12: 'd' (Advantage)
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
int getDigitBaseLed(int digitIndex) {
  if (digitIndex < 2) {
    return digitIndex * LEDS_PER_DIGIT;              // Digit 0: 0..27, Digit 1: 28..55
  } else {
    return (digitIndex * LEDS_PER_DIGIT) + COLON_LEDS; // Digit 2: 58..85, Digit 3: 86..113
  }
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

void drawDigit(int digitIndex, int numIndex, uint32_t color) {
  if (digitIndex < 0 || digitIndex >= NUM_DIGITS) return;
  if (numIndex < 0 || numIndex > 12) numIndex = 10; // 10 = Blank

  int baseLed = getDigitBaseLed(digitIndex);
  for (int seg = 0; seg < 7; seg++) {
#if PANEL0_CUSTOM_WIRING
    int physSeg = (digitIndex == 0) ? panel0SegmentMap[seg] : seg;
#else
    int physSeg = seg;
#endif
    int startPixel = baseLed + (physSeg * LEDS_PER_SEGMENT);
    bool segOn = (numbers[numIndex][seg] == 1);
    for (int i = 0; i < LEDS_PER_SEGMENT; i++) {
      int p = startPixel + i;
      if (p >= 0 && p < NUMPIXELS) {
        pixels.setPixelColor(p, segOn ? color : 0);
      }
    }
  }
}

void displayScore(std::string score, bool swapped) {
  pixels.clear();

  // Team Colors: Team 1 Blue, Team 2 Red (flips across net when sides swapped)
  uint32_t colorBlue  = pixels.Color(0, 180, 255);
  uint32_t colorRed   = pixels.Color(255, 0, 0);
  uint32_t colorColon = pixels.Color(200, 200, 200);

  uint32_t leftColor  = swapped ? colorRed : colorBlue;
  uint32_t rightColor = swapped ? colorBlue : colorRed;

  // Ensure score is at least 4 chars (e.g. "1530", " 0 0", "Ad40")
  while (score.length() < 4) score += " ";

  for (int d = 0; d < 4; d++) {
    char c = score[d];
    int numIndex = 10; // default blank

    if (c >= '0' && c <= '9') {
      numIndex = c - '0';
    } else if (c == 'A' || c == 'a') {
      numIndex = 11; // 'A'
    } else if (c == 'D' || c == 'd') {
      numIndex = 12; // 'd'
    }

    // Advantage "Ad" autocompletion
    if (d == 1 && (score[0] == 'A' || score[0] == 'a') && (c == ' ' || numIndex == 10)) {
      numIndex = 12;
    }
    if (d == 3 && (score[2] == 'A' || score[2] == 'a') && (c == ' ' || numIndex == 10)) {
      numIndex = 12;
    }

    uint32_t digitColor = (d < 2) ? leftColor : rightColor;
    drawDigit(d, numIndex, digitColor);
  }

  // Draw 2 Colon LEDs (between Digit 2 and Digit 3, indices 56 & 57)
  int colonStart = 2 * LEDS_PER_DIGIT;
  for (int i = 0; i < COLON_LEDS; i++) {
    int p = colonStart + i;
    if (p < NUMPIXELS) {
      pixels.setPixelColor(p, colorColon);
    }
  }

  pixels.show();
  Serial.printf(">> [DISPLAY] Score: %s | Swapped: %d\n", score.c_str(), swapped);
}

void animateSwap() {
  for (int i = 0; i < NUMPIXELS; i++) {
    pixels.setPixelColor(i, 0);
    pixels.show();
    delay(2);
  }
  delay(100);
}

// ==============================================================================
// BLE Server Callbacks
// ==============================================================================
class MyServerCallbacks : public NimBLEServerCallbacks {
  void onConnect(NimBLEServer* pServer) override {
    Serial.println(">> [BLE] Watch connected!");
    setStatusLed(0, 255, 0); // Green
    triggerConnectAnimation = true;
  }

  void onDisconnect(NimBLEServer* pServer) override {
    Serial.println(">> [BLE] Watch disconnected. Restarting advertising...");
    setStatusLed(0, 0, 255); // Blue
    NimBLEDevice::startAdvertising();
  }
};

class MyCallbacks : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic* pCharacteristic) override {
    std::string value = pCharacteristic->getValue();
    if (value.length() > 0) {
      Serial.printf(">> [BLE] Received score payload: '%s'\n", value.c_str());
      currentScore = value;
      newScoreReceived = true;
    }
  }
};

// ==============================================================================
// Dedicated FreeRTOS Scoreboard Task (16KB Stack)
// ==============================================================================
void scoreboardTask(void* parameter) {
  Serial.println("[TASK] Scoreboard task started. Initializing NimBLE...");

  NimBLEDevice::init("Padel Display");

  NimBLEServer* pServer = NimBLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  NimBLEService* pService = pServer->createService(SERVICE_UUID);
  NimBLECharacteristic* pCharacteristic = pService->createCharacteristic(
      CHARACTERISTIC_UUID,
      NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_NR | NIMBLE_PROPERTY::READ
  );
  pCharacteristic->setCallbacks(new MyCallbacks());
  pCharacteristic->setValue("0000");

  pService->start();

  // Initialize BLE FOTA Service
  BleFota::init(pServer);
  BleFota::setCallbacks(
    [](int percent) {
      pixels.clear();
      drawDigit(0, (percent / 10) % 10, pixels.Color(0, 200, 255));
      drawDigit(1, percent % 10, pixels.Color(0, 200, 255));
      drawDigit(2, (percent / 10) % 10, pixels.Color(0, 200, 255));
      drawDigit(3, percent % 10, pixels.Color(0, 200, 255));
      pixels.show();
    },
    [](bool inProgress, bool success) {
      if (!inProgress && success) {
        pixels.clear();
        for (int i = 0; i < NUMPIXELS; i++) pixels.setPixelColor(i, pixels.Color(0, 255, 0));
        pixels.show();
      }
    }
  );

  pServer->start();

  NimBLEAdvertising* pAdvertising = NimBLEDevice::getAdvertising();
  pAdvertising->setName("Padel Display");
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->start();

  Serial.println(">> [BLE] Server started as 'Padel Display'. Waiting for connections...");
  setStatusLed(0, 0, 255); // Blue = Advertising

  // Initial Score Display (00 00)
  displayScore("0000", false);

  while (true) {
    if (BleFota::isUpdating()) {
      vTaskDelay(pdMS_TO_TICKS(100));
      continue;
    }
    if (triggerConnectAnimation) {
      triggerConnectAnimation = false;
      // Flash all blue 3 times
      for (int j = 0; j < 3; j++) {
        for (int i = 0; i < NUMPIXELS; i++) {
          pixels.setPixelColor(i, pixels.Color(0, 180, 255));
        }
        pixels.show();
        vTaskDelay(pdMS_TO_TICKS(120));
        pixels.clear();
        pixels.show();
        vTaskDelay(pdMS_TO_TICKS(120));
      }
      displayScore(currentScore, isSwitched);
    }

    if (newScoreReceived) {
      newScoreReceived = false;

      std::string scoreStr = "0000";
      bool newIsSwitched = isSwitched;

      // Parse "SCORE,SWITCH_FLAG" (e.g. "1530,1" or " 0 0,0")
      size_t commaPos = currentScore.find(',');
      if (commaPos != std::string::npos) {
        scoreStr = currentScore.substr(0, commaPos);
        std::string flag = currentScore.substr(commaPos + 1);
        newIsSwitched = (flag == "1");
      } else {
        scoreStr = currentScore;
      }

      if (newIsSwitched != isSwitched) {
        animateSwap();
        isSwitched = newIsSwitched;
      }

      displayScore(scoreStr, isSwitched);
    }

    vTaskDelay(pdMS_TO_TICKS(20));
  }
}

// ==============================================================================
// Arduino Setup & Main Loop
// ==============================================================================
void setup() {
  Serial.begin(115200);
  delay(500);

  Serial.println("\n=========================================================");
  Serial.println("   4-Digit Padel Scoreboard Display (Watch BLE App)      ");
  Serial.println("=========================================================");

#if !defined(CONFIG_IDF_TARGET_ESP32C3)
  onboardLed.begin();
  onboardLed.setBrightness(40);
#endif

  pixels.begin();
  pixels.setBrightness(BRIGHTNESS);
  pixels.clear();
  pixels.show();

  // Run Scoreboard & BLE in dedicated 16KB task to prevent stack overflow
  xTaskCreate(
      scoreboardTask,
      "scoreboardTask",
      16384,
      NULL,
      1,
      NULL
  );
}

void loop() {
  vTaskDelay(pdMS_TO_TICKS(1000));
}
