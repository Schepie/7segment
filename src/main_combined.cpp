// ==============================================================================
// ESP32 Multi-Function Scoreboard, Clock & Remote Controller (Combined Firmware)
//
// Modes:
//   Mode 0: Digital Clock (RTC DS1302 + Internal Fallback, Smooth Color Fade)
//   Mode 1: BLE Padel Scoreboard (BLE Server for Phone / Web App)
//   Mode 2: Xiaomi / YI Shutter Remote Counter (BLE Client to XYLY01 / XiaoYi_RC)
//
// Mode Switching:
//   Press the MODE_BUTTON (default: GPIO 0, onboard BOOT button or external button)
//   to cycle between modes: Clock -> Scoreboard -> Shutter Counter -> Clock...
//   The display briefly splashes the mode name ("CLOC", "SCOR", "ShUt") on switch.
//
// Physical Chain & Wiring Order (114 LEDs Total):
//   Digit 0 (28 LEDs) -> Digit 1 (28 LEDs) -> Colon (2 LEDs) -> Digit 2 (28 LEDs) -> Digit 3 (28 LEDs)
//   Segments per digit (4 LEDs/seg): BL (0..3), B (4..7), BR (8..11), M (12..15), TL (16..19), T (20..23), TR (24..27)
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
// Hardware & Pin Configuration
// ==============================================================================
#if defined(CONFIG_IDF_TARGET_ESP32C3)
  #define LED_PIN           2      // WS2812 Data Pin (ESP32-C3: GPIO 2)
  #define ONBOARD_LED_PIN   8      // ESP32-C3 LED (GPIO 8, Active LOW)
  #define MODE_BUTTON_PIN   9      // Mode button (ESP32-C3 BOOT pin is GPIO 9)
  #define DS1302_CLK_PIN    4      // RTC SCLK
  #define DS1302_DAT_PIN    5      // RTC DAT / IO
  #define DS1302_RST_PIN    3      // RTC RST / CE
#else
  #define LED_PIN           15     // WS2812 Data Pin (ESP32-S3 Zero: GPIO 15)
  #define ONBOARD_RGB_PIN   21     // Waveshare ESP32-S3 Zero RGB LED (GPIO 21)
  #define MODE_BUTTON_PIN   0      // Mode button (ESP32-S3 BOOT pin is GPIO 0, active LOW)
  #define DS1302_CLK_PIN    4      // RTC SCLK
  #define DS1302_DAT_PIN    5      // RTC DAT / IO
  #define DS1302_RST_PIN    6      // RTC RST / CE
#endif

#define NUM_DIGITS        4      // 4 Digits total
#define LEDS_PER_SEGMENT  4      // 4 LEDs per segment
#define LEDS_PER_DIGIT    28     // 7 segments * 4 LEDs = 28 LEDs per digit
#define COLON_LEDS        2      // 2 LEDs for colon between Digit 1 and Digit 2
#define NUMPIXELS         (NUM_DIGITS * LEDS_PER_DIGIT + COLON_LEDS) // 114 LEDs total
#define BRIGHTNESS        180    // LED brightness (0 - 255)

// ==============================================================================
// BLE Server Configuration (Mode 1: Scoreboard)
// ==============================================================================
#define SCORE_SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define SCORE_CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// ==============================================================================
// State & Mode Definitions
// ==============================================================================
enum AppMode {
  MODE_CLOCK = 0,
  MODE_SCOREBOARD = 1,
  MODE_SHUTTER = 2,
  NUM_MODES = 3
};

AppMode currentMode = MODE_CLOCK;
bool modeJustChanged = true;

// Hardware Instances
Adafruit_NeoPixel pixels(NUMPIXELS, LED_PIN, NEO_GRB + NEO_KHZ800);

#if !defined(CONFIG_IDF_TARGET_ESP32C3)
Adafruit_NeoPixel onboardLed(1, ONBOARD_RGB_PIN, NEO_GRB + NEO_KHZ800);
#endif

// RTC Instance
ThreeWire rtcWire(DS1302_DAT_PIN, DS1302_CLK_PIN, DS1302_RST_PIN);
RtcDS1302<ThreeWire> Rtc(rtcWire);
bool rtcAvailable = false;
int clockHour = 12, clockMinute = 0, clockSecond = 0;
uint32_t lastInternalClockTick = 0;

// Curated 8-Color Palette
struct RGBColor {
  uint8_t r, g, b;
  const char* name;
};

const RGBColor colorPalette[] = {
  { 0,   220, 255, "Cyan"       },
  { 255, 0,   0,   "Red"        },
  { 0,   255, 60,  "Green"      },
  { 255, 75,  0,   "Orange"     },
  { 255, 200, 0,   "Yellow"     },
  { 180, 20,  255, "Purple"     },
  { 255, 255, 255, "White"      },
  { 255, 20,  150, "Pink"       }
};
const int NUM_PALETTE_COLORS = sizeof(colorPalette) / sizeof(colorPalette[0]);
int shutterColorIndex = 0;

// Mode 1 (Scoreboard) State
std::string scoreboardScore = "0000";
bool newScoreReceived = false;
bool scoreboardSwapped = false;
bool scoreboardConnected = false;
NimBLEServer* pBleServer = nullptr;

// Mode 2 (Shutter Remote) State & Padel Scoring Engine
enum PadelPoint {
  POINT_0 = 0,   // " 0"
  POINT_15 = 1,  // "15"
  POINT_30 = 2,  // "30"
  POINT_40 = 3,  // "40"
  POINT_AD = 4   // "Ad"
};

struct ScoreState {
  PadelPoint p1;
  PadelPoint p2;
  int games1;
  int games2;
};

#define SCORE_HISTORY_DEPTH 30
ScoreState scoreHistory[SCORE_HISTORY_DEPTH];
int historyCount = 0;

PadelPoint team1Point = POINT_0;
PadelPoint team2Point = POINT_0;
int team1Games = 0;
int team2Games = 0;
bool triggerGameWonAnimation = false;
int winningTeam = 0;
bool triggerShutterUndo = false;

enum RemoteButton { BTN_NONE, BTN_BIG, BTN_SMALL };
volatile RemoteButton lastRemoteBtn = BTN_NONE;
volatile uint32_t lastRemoteClickTime = 0;
volatile bool pendingRemoteSingleClick = false;
NimBLEAdvertisedDevice* shutterTargetDevice = nullptr;
NimBLEClient* pShutterClient = nullptr;
bool shutterDoConnect = false;
bool shutterConnected = false;
bool shutterDoScan = false;

void saveScoreState() {
  if (historyCount < SCORE_HISTORY_DEPTH) {
    scoreHistory[historyCount].p1 = team1Point;
    scoreHistory[historyCount].p2 = team2Point;
    scoreHistory[historyCount].games1 = team1Games;
    scoreHistory[historyCount].games2 = team2Games;
    historyCount++;
  } else {
    for (int i = 0; i < SCORE_HISTORY_DEPTH - 1; i++) {
      scoreHistory[i] = scoreHistory[i + 1];
    }
    scoreHistory[SCORE_HISTORY_DEPTH - 1].p1 = team1Point;
    scoreHistory[SCORE_HISTORY_DEPTH - 1].p2 = team2Point;
    scoreHistory[SCORE_HISTORY_DEPTH - 1].games1 = team1Games;
    scoreHistory[SCORE_HISTORY_DEPTH - 1].games2 = team2Games;
  }
}

bool undoScoreState() {
  if (historyCount <= 0) return false;
  historyCount--;
  team1Point = scoreHistory[historyCount].p1;
  team2Point = scoreHistory[historyCount].p2;
  team1Games = scoreHistory[historyCount].games1;
  team2Games = scoreHistory[historyCount].games2;
  return true;
}

void addPadelPoint(int team) {
  saveScoreState();

  if (team == 1) {
    if (team1Point == POINT_40) {
      if (team2Point == POINT_40) {
        team1Point = POINT_AD; // 40-40 -> Ad-40
      } else if (team2Point == POINT_AD) {
        team2Point = POINT_40; // 40-Ad -> 40-40 Deuce
      } else {
        team1Games++;
        team1Point = POINT_0;
        team2Point = POINT_0;
        winningTeam = 1;
        triggerGameWonAnimation = true;
      }
    } else if (team1Point == POINT_AD) {
      team1Games++;
      team1Point = POINT_0;
      team2Point = POINT_0;
      winningTeam = 1;
      triggerGameWonAnimation = true;
    } else {
      team1Point = (PadelPoint)((int)team1Point + 1);
    }
  } else {
    if (team2Point == POINT_40) {
      if (team1Point == POINT_40) {
        team2Point = POINT_AD; // 40-40 -> 40-Ad
      } else if (team1Point == POINT_AD) {
        team1Point = POINT_40; // Ad-40 -> 40-40 Deuce
      } else {
        team2Games++;
        team1Point = POINT_0;
        team2Point = POINT_0;
        winningTeam = 2;
        triggerGameWonAnimation = true;
      }
    } else if (team2Point == POINT_AD) {
      team2Games++;
      team1Point = POINT_0;
      team2Point = POINT_0;
      winningTeam = 2;
      triggerGameWonAnimation = true;
    } else {
      team2Point = (PadelPoint)((int)team2Point + 1);
    }
  }
}

// ==============================================================================
// 7-Segment Font & Mapping
// ==============================================================================
// Segment order: [0]BL, [1]B, [2]BR, [3]M, [4]TL, [5]T, [6]TR
void getCharSegments(char c, bool segs[7]) {
  for (int i = 0; i < 7; i++) segs[i] = false;

  switch (c) {
    case '0': segs[0]=segs[1]=segs[2]=segs[4]=segs[5]=segs[6]=true; break;
    case '1': segs[2]=segs[6]=true; break;
    case '2': segs[0]=segs[1]=segs[3]=segs[5]=segs[6]=true; break;
    case '3': segs[1]=segs[2]=segs[3]=segs[5]=segs[6]=true; break;
    case '4': segs[2]=segs[3]=segs[4]=segs[6]=true; break;
    case '5': segs[1]=segs[2]=segs[3]=segs[4]=segs[5]=true; break;
    case '6': segs[0]=segs[1]=segs[2]=segs[3]=segs[4]=segs[5]=true; break;
    case '7': segs[2]=segs[5]=segs[6]=true; break;
    case '8': segs[0]=segs[1]=segs[2]=segs[3]=segs[4]=segs[5]=segs[6]=true; break;
    case '9': segs[1]=segs[2]=segs[3]=segs[4]=segs[5]=segs[6]=true; break;
    case 'A': case 'a': segs[0]=segs[2]=segs[3]=segs[4]=segs[5]=segs[6]=true; break;
    case 'b': segs[0]=segs[1]=segs[2]=segs[3]=segs[4]=true; break;
    case 'C': case 'c': segs[0]=segs[1]=segs[4]=segs[5]=true; break;
    case 'd': segs[0]=segs[1]=segs[2]=segs[3]=segs[6]=true; break;
    case 'E': case 'e': segs[0]=segs[1]=segs[3]=segs[4]=segs[5]=true; break;
    case 'F': case 'f': segs[0]=segs[3]=segs[4]=segs[5]=true; break;
    case 'H': case 'h': segs[0]=segs[2]=segs[3]=segs[4]=segs[6]=true; break;
    case 'L': case 'l': segs[0]=segs[1]=segs[4]=true; break;
    case 'o': segs[0]=segs[1]=segs[2]=segs[3]=true; break;
    case 'P': case 'p': segs[0]=segs[3]=segs[4]=segs[5]=segs[6]=true; break;
    case 'r': segs[0]=segs[3]=true; break;
    case 'S': case 's': segs[1]=segs[2]=segs[3]=segs[4]=segs[5]=true; break;
    case 't': segs[0]=segs[1]=segs[3]=segs[4]=true; break;
    case 'U': segs[0]=segs[1]=segs[2]=segs[4]=segs[6]=true; break;
    case 'u': segs[0]=segs[1]=segs[2]=true; break;
    case '-': segs[3]=true; break;
    default: break; // Blank
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

// ==============================================================================
// LED Hardware Drivers
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

int getDigitBaseLed(int digitIndex) {
  if (digitIndex < 2) {
    return digitIndex * LEDS_PER_DIGIT;
  } else {
    return (digitIndex * LEDS_PER_DIGIT) + COLON_LEDS;
  }
}

int getColonBaseLed() {
  return 2 * LEDS_PER_DIGIT; // LEDs 56 and 57
}

void drawChar(int digitIndex, char c, uint32_t color) {
  if (digitIndex < 0 || digitIndex >= NUM_DIGITS) return;

  bool segs[7];
  getCharSegments(c, segs);

  int baseLed = getDigitBaseLed(digitIndex);
  for (int seg = 0; seg < 7; seg++) {
#if PANEL0_CUSTOM_WIRING
    int physSeg = (digitIndex == 0) ? panel0SegmentMap[seg] : seg;
#else
    int physSeg = seg;
#endif
    int startPixel = baseLed + (physSeg * LEDS_PER_SEGMENT);
    for (int i = 0; i < LEDS_PER_SEGMENT; i++) {
      int p = startPixel + i;
      if (p >= 0 && p < NUMPIXELS) {
        pixels.setPixelColor(p, segs[seg] ? color : 0);
      }
    }
  }
}

void drawColon(bool show, uint32_t color) {
  int colonBase = getColonBaseLed();
  for (int i = 0; i < COLON_LEDS; i++) {
    pixels.setPixelColor(colonBase + i, show ? color : 0);
  }
}

// ==============================================================================
// Safe WS2812 Show Helper (Eliminates ESP32-C3 Single-Core BLE Glitches)
// ==============================================================================
void showPixelsSafe() {
  bool wasScanning = false;
  NimBLEScan* pScan = NimBLEDevice::getScan();
  if (pScan != nullptr && pScan->isScanning()) {
    wasScanning = true;
    pScan->stop();
  }

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
  if (wasScanning && currentMode == MODE_SHUTTER && !shutterConnected) {
    pScan->start(0, nullptr, false);
  }
}

void showSplashScreen(const char* text, uint32_t color) {
  pixels.clear();
  drawColon(false, 0);
  for (int d = 0; d < 4; d++) {
    char c = (d < (int)strlen(text)) ? text[d] : ' ';
    drawChar(d, c, color);
  }
  showPixelsSafe();
}

// ==============================================================================
// BLE Callbacks: Mode 1 (Scoreboard Server)
// ==============================================================================
class ScoreboardCharCallbacks : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic *pCharacteristic) override {
    std::string value = pCharacteristic->getValue();
    if (value.length() > 0) {
      scoreboardScore = value;
      newScoreReceived = true;
      Serial.printf("[SCOREBOARD] Received payload: %s\n", scoreboardScore.c_str());
    }
  }
};

class ScoreboardServerCallbacks : public NimBLEServerCallbacks {
  void onConnect(NimBLEServer *pServer) override {
    Serial.println("[SCOREBOARD] Phone / Web App connected");
    scoreboardConnected = true;
    setStatusLed(0, 50, 0); // Green
  }

  void onDisconnect(NimBLEServer *pServer) override {
    Serial.println("[SCOREBOARD] Client disconnected");
    scoreboardConnected = false;
    if (currentMode == MODE_SCOREBOARD) {
      setStatusLed(0, 0, 50); // Blue
      NimBLEDevice::getAdvertising()->start();
    }
  }
};

// ==============================================================================
// BLE Callbacks: Mode 2 (Shutter Remote Client)
// ==============================================================================
void onHIDNotification(NimBLERemoteCharacteristic* pChar, uint8_t* pData, size_t length, bool isNotify) {
  if (length == 0 || pData == nullptr) return;
  uint8_t btnCode = pData[0];

  uint32_t now = millis();
  if (btnCode & 0x40 || btnCode & 0x80) {
    RemoteButton btn = (btnCode & 0x40) ? BTN_BIG : BTN_SMALL;
    if (pendingRemoteSingleClick && (now - lastRemoteClickTime < 380)) {
      // Double click -> UNDO!
      pendingRemoteSingleClick = false;
      triggerShutterUndo = true;
    } else {
      lastRemoteBtn = btn;
      lastRemoteClickTime = now;
      pendingRemoteSingleClick = true;
    }
  }
}

class ShutterAdvertisedDeviceCallbacks : public NimBLEAdvertisedDeviceCallbacks {
  void onResult(NimBLEAdvertisedDevice* advertisedDevice) override {
    if (currentMode != MODE_SHUTTER || shutterConnected || shutterTargetDevice != nullptr) return;

    bool isMatch = false;
    if (advertisedDevice->haveName()) {
      std::string name = advertisedDevice->getName();
      if (name == "XiaoYi_RC" || name == "XYLY01" || name.find("XiaoYi") != std::string::npos) {
        isMatch = true;
      }
    }
    if (!isMatch && advertisedDevice->haveServiceUUID() &&
        advertisedDevice->isAdvertisingService(NimBLEUUID((uint16_t)0x1812))) {
      isMatch = true;
    }

    if (isMatch) {
      Serial.printf("[SHUTTER] Remote found (%s)! Stopping scan to connect...\n",
                    advertisedDevice->getAddress().toString().c_str());
      NimBLEDevice::getScan()->stop();
      shutterTargetDevice = advertisedDevice;
      shutterDoConnect = true;
    }
  }
};

class ShutterClientCallbacks : public NimBLEClientCallbacks {
  void onConnect(NimBLEClient* pClient) override {
    Serial.println("[SHUTTER] Connected to Xiaomi Remote!");
    shutterConnected = true;
    setStatusLed(0, 50, 0); // Green
  }

  void onDisconnect(NimBLEClient* pClient) override {
    Serial.println("[SHUTTER] Remote disconnected");
    shutterConnected = false;
    shutterTargetDevice = nullptr;
    if (currentMode == MODE_SHUTTER) {
      setStatusLed(50, 0, 0); // Red
      shutterDoScan = true;
    }
  }
};

bool connectShutterRemote() {
  if (!shutterTargetDevice) return false;
  setStatusLed(50, 25, 0); // Orange

  if (!pShutterClient) {
    pShutterClient = NimBLEDevice::createClient();
    pShutterClient->setClientCallbacks(new ShutterClientCallbacks(), false);
    pShutterClient->setConnectionParams(24, 40, 0, 400);
  }

  if (!pShutterClient->connect(shutterTargetDevice)) {
    Serial.println("[SHUTTER] Connection failed");
    return false;
  }

  NimBLERemoteService* pHidService = pShutterClient->getService(NimBLEUUID((uint16_t)0x1812));
  if (!pHidService) {
    pShutterClient->disconnect();
    return false;
  }

  std::vector<NimBLERemoteCharacteristic*>* chars = pHidService->getCharacteristics(true);
  if (chars) {
    for (auto* pChar : *chars) {
      if (pChar->canNotify()) {
        pChar->subscribe(true, onHIDNotification, true);
        Serial.println("[SHUTTER] Subscribed to HID notifications");
      }
    }
  }
  return true;
}

// ==============================================================================
// Mode Lifecycle Management
// ==============================================================================
void switchMode(AppMode newMode) {
  currentMode = newMode;
  modeJustChanged = true;
  pixels.clear();
  pixels.show();

  // Deactivate background activities of other modes
  if (currentMode != MODE_SCOREBOARD) {
    NimBLEDevice::getAdvertising()->stop();
  }
  if (currentMode != MODE_SHUTTER) {
    NimBLEDevice::getScan()->stop();
    if (pShutterClient && pShutterClient->isConnected()) {
      pShutterClient->disconnect();
    }
  }

  // Display Splash Screen & Configure Resources
  switch (currentMode) {
    case MODE_CLOCK:
      Serial.println("\n>>> ENTERING MODE: DIGITAL CLOCK <<<");
      setStatusLed(0, 50, 25); // Cyan
      showSplashScreen("CLOC", pixels.Color(0, 220, 255));
      delay(700);
      break;

    case MODE_SCOREBOARD:
      Serial.println("\n>>> ENTERING MODE: PADEL SCOREBOARD (BLE SERVER) <<<");
      setStatusLed(0, 0, 50); // Blue
      showSplashScreen("SCOR", pixels.Color(0, 150, 255));
      delay(700);
      NimBLEDevice::getAdvertising()->start();
      Serial.println("[SCOREBOARD] BLE Advertising started ('Padel Display')");
      break;

    case MODE_SHUTTER:
      Serial.println("\n>>> ENTERING MODE: XIAOMI SHUTTER COUNTER <<<");
      setStatusLed(50, 0, 50); // Magenta
      showSplashScreen("ShUt", pixels.Color(255, 20, 150));
      delay(700);
      shutterDoScan = true;
      break;

    default:
      break;
  }
}

// ==============================================================================
// Mode Render Loops
// ==============================================================================

// Mode 0: Clock Loop
void loopClock() {
  static uint32_t lastRtcPoll = 0;

  // Poll RTC or increment internal tick
  if (rtcAvailable) {
    if (millis() - lastRtcPoll >= 250) {
      lastRtcPoll = millis();
      RtcDateTime now = Rtc.GetDateTime();
      if (now.IsValid()) {
        clockHour   = now.Hour();
        clockMinute = now.Minute();
        clockSecond = now.Second();
      }
    }
  } else {
    if (millis() - lastInternalClockTick >= 1000) {
      lastInternalClockTick += 1000;
      clockSecond++;
      if (clockSecond >= 60) {
        clockSecond = 0;
        clockMinute++;
        if (clockMinute >= 60) {
          clockMinute = 0;
          clockHour = (clockHour + 1) % 24;
        }
      }
    }
  }

  // Calculate smooth color crossfade (every 6 seconds)
  uint32_t ms = (millis() / 500) * 500; // Quantized to 500ms
  int colIdx = (ms / 6000) % NUM_PALETTE_COLORS;
  int nextIdx = (colIdx + 1) % NUM_PALETTE_COLORS;
  float progress = (float)(ms % 6000) / 6000.0f;
  float eased = (1.0f - cosf(progress * 3.14159265f)) * 0.5f;

  uint8_t r = (uint8_t)(colorPalette[colIdx].r + (colorPalette[nextIdx].r - colorPalette[colIdx].r) * eased);
  uint8_t g = (uint8_t)(colorPalette[colIdx].g + (colorPalette[nextIdx].g - colorPalette[colIdx].g) * eased);
  uint8_t b = (uint8_t)(colorPalette[colIdx].b + (colorPalette[nextIdx].b - colorPalette[colIdx].b) * eased);
  uint32_t activeColor = pixels.Color(r, g, b);

  // Colon blink logic (500ms ON / 500ms OFF)
  bool showColon = (millis() % 1000) < 500;

  // Format digits
  int d0 = clockHour / 10;
  int d1 = clockHour % 10;
  int d2 = clockMinute / 10;
  int d3 = clockMinute % 10;
  char c0 = (d0 == 0) ? ' ' : ('0' + d0); // Blank leading zero

  static char last_c0 = 0, last_c1 = 0, last_c2 = 0, last_c3 = 0;
  static bool last_showColon = false;
  static uint32_t last_color = 0;

  char c1 = '0' + d1;
  char c2 = '0' + d2;
  char c3 = '0' + d3;

  bool needsRedraw = (c0 != last_c0 || c1 != last_c1 || c2 != last_c2 || c3 != last_c3 ||
                      showColon != last_showColon || activeColor != last_color);

  if (needsRedraw) {
    last_c0 = c0;
    last_c1 = c1;
    last_c2 = c2;
    last_c3 = c3;
    last_showColon = showColon;
    last_color = activeColor;

    pixels.clear();
    drawChar(0, c0, activeColor);
    drawChar(1, c1, activeColor);
    drawColon(showColon, activeColor);
    drawChar(2, c2, activeColor);
    drawChar(3, c3, activeColor);
    showPixelsSafe();
  }
}

// Mode 1: Scoreboard Loop
void renderScoreboard() {
  pixels.clear();

  uint32_t colorBlue  = pixels.Color(0, 180, 255);
  uint32_t colorRed   = pixels.Color(255, 0, 0);
  uint32_t colorColon = pixels.Color(200, 200, 200);

  uint32_t leftColor  = scoreboardSwapped ? colorRed : colorBlue;
  uint32_t rightColor = scoreboardSwapped ? colorBlue : colorRed;

  std::string s = scoreboardScore;
  while (s.length() < 4) s += " ";

  drawChar(0, s[0], leftColor);
  drawChar(1, s[1], leftColor);
  drawColon(true, colorColon);
  drawChar(2, s[2], rightColor);
  drawChar(3, s[3], rightColor);

  showPixelsSafe();
}

void loopScoreboard() {
  if (modeJustChanged) {
    modeJustChanged = false;
    renderScoreboard();
  }

  if (newScoreReceived) {
    newScoreReceived = false;

    // Parse format: "1530,1" or "1530"
    std::string scoreStr = "0000";
    size_t comma = scoreboardScore.find(',');
    if (comma != std::string::npos) {
      scoreStr = scoreboardScore.substr(0, comma);
      scoreboardSwapped = (scoreboardScore.substr(comma + 1) == "1");
    } else {
      scoreStr = scoreboardScore;
    }
    scoreboardScore = scoreStr;
    renderScoreboard();
  }
}

// Mode 2: Shutter Remote Padel Scoreboard Loop
void renderShutterScore() {
  pixels.clear();

  uint32_t colorBlue  = pixels.Color(0, 180, 255); // Team 1 Blue
  uint32_t colorRed   = pixels.Color(255, 0, 0);   // Team 2 Red
  uint32_t colorColon = pixels.Color(200, 200, 200);

  const char* pointLabels[] = { " 0", "15", "30", "40", "Ad" };
  const char* s1 = pointLabels[team1Point];
  const char* s2 = pointLabels[team2Point];

  drawChar(0, s1[0], colorBlue);
  drawChar(1, s1[1], colorBlue);
  drawColon(true, colorColon);
  drawChar(2, s2[0], colorRed);
  drawChar(3, s2[1], colorRed);

  showPixelsSafe();
}

void loopShutter() {
  if (modeJustChanged) {
    modeJustChanged = false;
    renderShutterScore();
  }

  // Handle BLE Discovery & Connection
  if (shutterDoConnect) {
    shutterDoConnect = false;
    if (!connectShutterRemote()) {
      delay(1500);
      shutterDoScan = true;
    }
  }

  if (shutterDoScan && !shutterConnected) {
    shutterDoScan = false;
    setStatusLed(0, 0, 50); // Blue
    NimBLEDevice::getScan()->start(0, false);
  }

  // Handle Single-Click timeout (380ms)
  if (pendingRemoteSingleClick && (millis() - lastRemoteClickTime >= 380)) {
    pendingRemoteSingleClick = false;
    const char* pointLabels[] = { " 0", "15", "30", "40", "Ad" };
    if (lastRemoteBtn == BTN_BIG) {
      // Big Button: Increase score Team 1
      addPadelPoint(1);
      Serial.printf("[SHUTTER] Big Button -> Point Team 1! Score: %s - %s (Games: %d-%d)\n",
                    pointLabels[team1Point], pointLabels[team2Point], team1Games, team2Games);
      renderShutterScore();
    } else if (lastRemoteBtn == BTN_SMALL) {
      // Small Button: Increase score Team 2
      addPadelPoint(2);
      Serial.printf("[SHUTTER] Small Button -> Point Team 2! Score: %s - %s (Games: %d-%d)\n",
                    pointLabels[team1Point], pointLabels[team2Point], team1Games, team2Games);
      renderShutterScore();
    }
  }

  // Handle Double-Click Undo
  if (triggerShutterUndo) {
    triggerShutterUndo = false;
    if (undoScoreState()) {
      const char* pointLabels[] = { " 0", "15", "30", "40", "Ad" };
      Serial.printf("[SHUTTER] Double Click -> UNDO! Restored: %s - %s (Games: %d-%d)\n",
                    pointLabels[team1Point], pointLabels[team2Point], team1Games, team2Games);
      // Flash colon to give visual confirmation
      drawColon(false, 0);
      showPixelsSafe();
      delay(80);
      renderShutterScore();
    } else {
      Serial.println("[SHUTTER] Undo triggered, but no history available");
    }
  }

  // Handle Game Won Animation
  if (triggerGameWonAnimation) {
    triggerGameWonAnimation = false;
    uint32_t winColor = (winningTeam == 1) ? pixels.Color(0, 180, 255) : pixels.Color(255, 0, 0);
    Serial.printf("[SHUTTER] ★ GAME WON by Team %d! Total Games: T1=%d, T2=%d\n",
                  winningTeam, team1Games, team2Games);
    for (int f = 0; f < 2; f++) {
      showSplashScreen("GAmE", winColor);
      delay(250);
      pixels.clear();
      showPixelsSafe();
      delay(150);
    }
    renderShutterScore();
  }
}

// ==============================================================================
// Setup & Main Loop
// ==============================================================================
void setup() {
  Serial.begin(115200);
  delay(500);

  Serial.println("\n=======================================================");
  Serial.println("   ESP32 Multi-Program Firmware (Combined)             ");
  Serial.println("   Modes: Clock (0) | Scoreboard (1) | Shutter (2)     ");
  Serial.printf("   Cycle Button: GPIO %d (Active LOW)\n", MODE_BUTTON_PIN);
  Serial.println("=======================================================");

  // Mode button with internal pullup
  pinMode(MODE_BUTTON_PIN, INPUT_PULLUP);

#if defined(CONFIG_IDF_TARGET_ESP32C3)
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  gpio_set_drive_capability((gpio_num_t)LED_PIN, GPIO_DRIVE_CAP_3);
#endif

  // Initialize LEDs
  pixels.begin();
  pixels.setBrightness(BRIGHTNESS);
  pixels.clear();
  showPixelsSafe();

#if !defined(CONFIG_IDF_TARGET_ESP32C3)
  onboardLed.begin();
  onboardLed.setBrightness(50);
#endif

  // Initialize RTC
  Rtc.Begin();
  if (!Rtc.GetIsRunning()) Rtc.SetIsRunning(true);
  if (Rtc.GetIsWriteProtected()) Rtc.SetIsWriteProtected(false);

  RtcDateTime now = Rtc.GetDateTime();
  if (now.IsValid() && now.Year() >= 2024 && now.Year() <= 2099) {
    rtcAvailable = true;
    clockHour = now.Hour();
    clockMinute = now.Minute();
    clockSecond = now.Second();
    Serial.printf("[RTC] Synced: %02d:%02d:%02d\n", clockHour, clockMinute, clockSecond);
  } else {
    rtcAvailable = false;
    const char* t = __TIME__;
    clockHour   = (t[0] - '0') * 10 + (t[1] - '0');
    clockMinute = (t[3] - '0') * 10 + (t[4] - '0');
    clockSecond = (t[6] - '0') * 10 + (t[7] - '0');
    lastInternalClockTick = millis();
    Serial.printf("[RTC] Software fallback: %02d:%02d:%02d\n", clockHour, clockMinute, clockSecond);
  }

  // Initialize NimBLE Stack (Dual-role Central + Peripheral)
  NimBLEDevice::init("Padel Display");
  NimBLEDevice::setSecurityAuth(true, true, true);
  NimBLEDevice::setSecurityIOCap(BLE_HS_IO_NO_INPUT_OUTPUT);
  NimBLEDevice::setPower(ESP_PWR_LVL_P9);

  // Configure Scoreboard BLE Server
  pBleServer = NimBLEDevice::createServer();
  pBleServer->setCallbacks(new ScoreboardServerCallbacks());
  NimBLEService* pScoreService = pBleServer->createService(SCORE_SERVICE_UUID);
  NimBLECharacteristic* pScoreChar = pScoreService->createCharacteristic(
      SCORE_CHARACTERISTIC_UUID,
      NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_NR | NIMBLE_PROPERTY::READ);
  pScoreChar->setCallbacks(new ScoreboardCharCallbacks());
  pScoreChar->setValue("0000");
  pScoreService->start();

  // Initialize BLE FOTA Service
  BleFota::init(pBleServer);
  BleFota::setCallbacks(
    [](int percent) {
      char buf[6];
      snprintf(buf, sizeof(buf), "%02d%02d", percent, percent);
      showSplashScreen(buf, pixels.Color(0, 200, 255));
    },
    [](bool inProgress, bool success) {
      if (!inProgress && success) {
        showSplashScreen("PASS", pixels.Color(0, 255, 0));
        delay(1200);
      }
    }
  );

  pBleServer->start();

  NimBLEAdvertising* pAdv = NimBLEDevice::getAdvertising();
  pAdv->setName("Padel Display");
  pAdv->addServiceUUID(SCORE_SERVICE_UUID);
  pAdv->addServiceUUID(BLE_FOTA_SERVICE_UUID);
  pAdv->start();

  Serial.println("[BLE] Stack initialized and advertising 'Padel Display'");

  // Boot into default mode (Digital Clock)
  switchMode(MODE_CLOCK);
}

void loop() {
  // Check Mode Switch Button (Active LOW with debounce)
  static uint32_t lastBtnCheck = 0;
  static bool lastBtnState = HIGH;

  if (millis() - lastBtnCheck >= 20) {
    lastBtnCheck = millis();
    bool currentBtnState = digitalRead(MODE_BUTTON_PIN);

    // Falling edge detected (button pressed down)
    if (lastBtnState == HIGH && currentBtnState == LOW) {
      Serial.println("\n[BUTTON] Mode switch pressed!");
      AppMode nextMode = (AppMode)((currentMode + 1) % NUM_MODES);
      switchMode(nextMode);
    }
    lastBtnState = currentBtnState;
  }

  // Execute active mode loop
  switch (currentMode) {
    case MODE_CLOCK:
      loopClock();
      break;
    case MODE_SCOREBOARD:
      loopScoreboard();
      break;
    case MODE_SHUTTER:
      loopShutter();
      break;
  }

  delay(20);
}
