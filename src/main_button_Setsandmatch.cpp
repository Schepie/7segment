// ==============================================================================
// ESP32 Padel Scoreboard - Xiaomi / YI Bluetooth Remote (XYLY01)
// Version: Sets & Match Edition (with Games & Sets Indicator Module)
//
// Remote Specifications:
//   Model: Xiaomi / YI Action Camera Remote (XYLY01, advertised as "XiaoYi_RC")
//   Protocol: BLE HID Report Characteristic (0x2A4D under Service 0x1812)
//   Big Button (Top / Shutter, 0x40): Point for Team 1 (Left / Blue)
//   Small Button (Bottom / Mode, 0x80): Point for Team 2 (Right / Red)
//   Double Click (Within 380ms): UNDO the previous point / game / set!
//
// Physical LED Chain & Wiring Order (136 LEDs Total):
//   1. Digit 0 (Team 1 Tens):            28 LEDs (0..27)
//   2. Digit 1 (Team 1 Ones):            28 LEDs (28..55)
//   3. Games & Sets Indicator Module:    24 LEDs (56..79)
//      - Left Column (Team 1, Bottom to Top):
//        * LEDs 56..64 (Indices 0..8):   Team 1 Games (G1..G9, bottom to top)
//        * LED 65      (Index 9):        Blank Spacer Gap (Always OFF)
//        * LEDs 66..67 (Indices 10..11): Team 1 Sets (S1, S2, bottom to top)
//      - Right Column (Team 2, Top to Bottom):
//        * LEDs 68..69 (Indices 12..13): Team 2 Sets (S2=top, S1=lower)
//        * LED 70      (Index 14):       Blank Spacer Gap (Always OFF)
//        * LEDs 71..79 (Indices 15..23): Team 2 Games (G9=top down to G1=bottom)
//   4. Digit 2 (Team 2 Tens):            28 LEDs (80..107)
//   5. Digit 3 (Team 2 Ones):            28 LEDs (108..135)
//
// Each 7-Segment Digit has 7 segments * 4 LEDs = 28 LEDs:
//   Segment 0: BL (Bottom-Left)  -> 0..3
//   Segment 1: B  (Bottom)       -> 4..7
//   Segment 2: BR (Bottom-Right) -> 8..11
//   Segment 3: M  (Middle)       -> 12..15
//   Segment 4: TL (Top-Left)     -> 16..19
//   Segment 5: T  (Top)          -> 20..23
//   Segment 6: TR (Top-Right)    -> 24..27
// ==============================================================================

#include <Arduino.h>
#include <Adafruit_NeoPixel.h>
#include <ThreeWire.h>
#include <RtcDS1302.h>
#include <NimBLEDevice.h>
#include <Preferences.h>
#include "ble_fota.h"
#if defined(ESP32)
  #include "driver/gpio.h"
#endif
#include <vector>
#include <string>

// ==============================================================================
// Hardware Configuration
// ==============================================================================
#if defined(CONFIG_IDF_TARGET_ESP32C3)
  #define LED_PIN           2      // WS2812 Data Pin on ESP32-C3 SuperMini (GPIO 2)
  #define ONBOARD_LED_PIN   8      // ESP32-C3 SuperMini LED (GPIO 8, Active LOW)
  #define DS1302_CLK_PIN    4      // RTC SCLK -> GPIO 4
  #define DS1302_DAT_PIN    5      // RTC DAT / IO -> GPIO 5
  #define DS1302_RST_PIN    3      // RTC RST / CE -> GPIO 3
#else
  #define LED_PIN           15     // WS2812 Data Pin on ESP32-S3 Zero (GPIO 15)
  #define ONBOARD_RGB_PIN   21     // Waveshare ESP32-S3 Zero On-board RGB (GPIO 21)
  #define DS1302_CLK_PIN    4      // RTC SCLK -> GPIO 4
  #define DS1302_DAT_PIN    5      // RTC DAT / IO -> GPIO 5
  #define DS1302_RST_PIN    6      // RTC RST / CE -> GPIO 6
#endif

#define NUM_DIGITS        4      // 4 Digits total (2 for Team 1, 2 for Team 2)
#define LEDS_PER_SEGMENT  4      // 4 LEDs per segment
#define LEDS_PER_DIGIT    28     // 7 segments * 4 LEDs = 28 LEDs per digit
#define GAMES_SETS_LEDS   24     // 2 columns * 12 LEDs for Games & Sets Module
#define NUMPIXELS         (NUM_DIGITS * LEDS_PER_DIGIT + GAMES_SETS_LEDS) // 136 LEDs total
#define BRIGHTNESS        180    // LED brightness (0 - 255)

// ==============================================================================
// Padel & Match Scoring Engine State
// ==============================================================================
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
  int sets1;
  int sets2;
  bool matchWon;
  int s1g1, s1g2;
  int s2g1, s2g2;
  int s3g1, s3g2;
  int setsPlayed;
  bool inTb;
  int tb1, tb2;
};

#define SCORE_HISTORY_DEPTH 30
ScoreState scoreHistory[SCORE_HISTORY_DEPTH];
int historyCount = 0;

PadelPoint team1Point = POINT_0;
PadelPoint team2Point = POINT_0;
int team1Games = 0;
int team2Games = 0;
int team1Sets = 0;
int team2Sets = 0;
bool matchWon = false;

// Match Rules Configuration (Persisted in NVS Flash)
bool cfgGoldenPoint = false; // false = Advantage (Ad-40), true = Punto de Oro (Deciding point)
int  cfgGamesPerSet = 6;     // 6 = Standard 6 games, 9 = Pro set
int  cfgSetsToWin   = 2;     // 1 = 1 set match, 2 = Best of 3 sets
bool cfgTiebreak    = true;  // true = Tiebreak at 6-6 (or 8-8)

// Tiebreak State
bool inTiebreak = false;
int tiebreakPoints1 = 0;
int tiebreakPoints2 = 0;

// Historical set games tracking for match summary
int set1Games1 = 0, set1Games2 = 0;
int set2Games1 = 0, set2Games2 = 0;
int set3Games1 = 0, set3Games2 = 0;
int totalSetsPlayed = 0;

enum MatchWonPhase {
  MATCH_PHASE_NONE,
  MATCH_PHASE_SPEL,
  MATCH_PHASE_SET_SCORES
};
MatchWonPhase matchWonPhase = MATCH_PHASE_NONE;
uint32_t matchWonStartTime = 0;

// Progression:
//   0 games (0-0): Normal (false)
//   1 game  (1-0): Swapped (true)   <- Swapped on 1st game (uneven)
//   2 games (1-1): Swapped (true)   <- No change! (even)
//   3 games (2-1): Normal (false)   <- Swapped on 3rd game (uneven)
//   4 games (4-0): Normal (false)   <- No change! (even)
//   5 games (3-2): Swapped (true)   <- Swapped on 5th game (uneven)
//   9 games (5-4): Swapped (true)   <- Swapped on 9th game (uneven)
bool currentCourtSwapped = false;
inline bool isCourtSwapped() {
  if (inTiebreak) {
    int tbSum = tiebreakPoints1 + tiebreakPoints2;
    int totalGames = team1Games + team2Games;
    bool baseSwapped = ((totalGames + 1) / 2) % 2 == 1;
    bool tbSwap = ((tbSum + 5) / 6) % 2 == 1;
    return baseSwapped ^ tbSwap;
  }
  int totalGames = team1Games + team2Games;
  return ((totalGames + 1) / 2) % 2 == 1;
}

bool triggerGameWonAnimation  = false;
bool triggerSetWonAnimation   = false;
bool triggerMatchWonAnimation = false;
int winningTeam = 0;
bool triggerUndoAction = false;
bool scoreNeedsUpdate = true;
// Mode State Machine & Inactivity Idle Timer
enum DisplayMode {
  MODE_CLOCK,
  MODE_SCOREBOARD
};
DisplayMode currentMode = MODE_CLOCK; // Panel starts in Clock Mode on boot!
uint32_t lastActivityTime = 0;
uint8_t  cfgBrightness    = 180;             // LED brightness (0 - 255)
uint32_t cfgIdleTimeoutMs = 5 * 60 * 1000;   // Inactivity timeout in ms (0 = Never)
uint8_t  cfgClockR        = 0;               // Clock Digit Color: Red component
uint8_t  cfgClockG        = 180;             // Clock Digit Color: Green component
uint8_t  cfgClockB        = 0;               // Clock Digit Color: Blue component
uint32_t cfgClockColor    = 0;               // Cached packed NeoPixel color

// RTC & Clock State
ThreeWire rtcWire(DS1302_DAT_PIN, DS1302_CLK_PIN, DS1302_RST_PIN);
RtcDS1302<ThreeWire> Rtc(rtcWire);
bool rtcAvailable = false;
int curHour   = 12;
int curMinute = 0;
int curSecond = 0;
uint32_t lastInternalTick = 0;

// Watch BLE GATT Server Definitions
#define WATCH_SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define WATCH_CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
NimBLECharacteristic* pWatchCharacteristic = nullptr;
void notifyWatchScore();

// Remote interaction tracking
enum RemoteButton { BUTTON_NONE, BUTTON_BIG, BUTTON_SMALL };
volatile RemoteButton lastPressedButton = BUTTON_NONE;
volatile uint32_t lastPressTime = 0;
volatile bool pendingSingleClick = false;

// BLE Central State & Persistent Pairing
Preferences prefs;
String savedRemoteMac = "";
NimBLEAddress targetAddress;
bool hasTarget = false;
bool doConnect = false;
bool connected = false;
bool doScan = true;

// Hardware Instances
Adafruit_NeoPixel pixels(NUMPIXELS, LED_PIN, NEO_GRB + NEO_KHZ800);

#if !defined(CONFIG_IDF_TARGET_ESP32C3)
Adafruit_NeoPixel onboardLed(1, ONBOARD_RGB_PIN, NEO_GRB + NEO_KHZ800);
#endif

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
const byte numbers[14][7] = {
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
  {   0, 0,  0, 0,  0, 0,  0 }, // 10: Blank
  {   1, 0,  1, 1,  1, 1,  1 }, // 11: 'A' (Advantage)
  {   1, 1,  1, 1,  0, 0,  1 }, // 12: 'd' (Advantage)
  {   0, 1,  1, 1,  1, 1,  0 }  // 13: 'S' (Set)
};

// ==============================================================================
// Helper & Display Functions
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
    return (digitIndex * LEDS_PER_DIGIT) + GAMES_SETS_LEDS;
  }
}

int getGamesSetsBaseLed() {
  return 2 * LEDS_PER_DIGIT; // Index 56 (LEDs 56..79)
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

void drawDigit(int digitIndex, int num, uint32_t color) {
  if (digitIndex < 0 || digitIndex >= NUM_DIGITS) return;
  if (num < 0 || num > 13) num = 10;

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

void drawSegment(int digitIndex, int seg, uint32_t color) {
  if (digitIndex < 0 || digitIndex >= NUM_DIGITS) return;
  if (seg < 0 || seg > 6) return;
  int baseLed = getDigitBaseLed(digitIndex);
#if PANEL0_CUSTOM_WIRING
  int physSeg = (digitIndex == 0) ? panel0SegmentMap[seg] : seg;
#else
  int physSeg = seg;
#endif
  int startPixel = baseLed + (physSeg * LEDS_PER_SEGMENT);
  for (int i = 0; i < LEDS_PER_SEGMENT; i++) {
    int p = startPixel + i;
    if (p >= 0 && p < NUMPIXELS) {
      pixels.setPixelColor(p, color);
    }
  }
}

inline uint32_t scaleColor(uint32_t color, float factor) {
  if (factor <= 0.0f) return 0;
  if (factor >= 1.0f) return color;
  uint8_t r = (uint8_t)(((color >> 16) & 0xFF) * factor);
  uint8_t g = (uint8_t)(((color >> 8) & 0xFF) * factor);
  uint8_t b = (uint8_t)((color & 0xFF) * factor);
  return pixels.Color(r, g, b);
}

void getTeamDigits(int team, int &tens, int &ones) {
  if (inTiebreak) {
    int pts = (team == 1) ? tiebreakPoints1 : tiebreakPoints2;
    tens = (pts >= 10) ? (pts / 10) : 10; // Blank leading zero (e.g. " 7", "11")
    ones = pts % 10;
    return;
  }
  PadelPoint pt = (team == 1) ? team1Point : team2Point;
  switch (pt) {
    case POINT_0:  tens = 10; ones = 0; break;
    case POINT_15: tens = 1;  ones = 5; break;
    case POINT_30: tens = 3;  ones = 0; break;
    case POINT_40: tens = 4;  ones = 0; break;
    case POINT_AD: tens = 11; ones = 12; break; // "Ad"
    default:       tens = 10; ones = 10; break;
  }
}

// ==============================================================================
// Games & Sets Indicator Module Rendering (24 LEDs total)
// ==============================================================================
void drawGamesAndSets(int games1, int sets1, int games2, int sets2, bool swapped = false, float brightnessFactor = 1.0f) {
  if (brightnessFactor <= 0.001f) return;
  int base = getGamesSetsBaseLed(); // LED index 56
  
  int leftGames   = !swapped ? games1 : games2;
  int leftSets    = !swapped ? sets1  : sets2;
  uint32_t leftColor = scaleColor(!swapped ? pixels.Color(0, 180, 255) : pixels.Color(255, 0, 0), brightnessFactor);

  int rightGames  = !swapped ? games2 : games1;
  int rightSets   = !swapped ? sets2  : sets1;
  uint32_t rightColor = scaleColor(!swapped ? pixels.Color(255, 0, 0) : pixels.Color(0, 180, 255), brightnessFactor);

  // 1. Left Column Games (9 LEDs: LEDs 1..9 -> base + 0..8, running bottom to top)
  for (int g = 0; g < 9; g++) {
    pixels.setPixelColor(base + g, (g < leftGames) ? leftColor : 0);
  }

  // 2. Left Column Spacer Gap (LED 10 -> base + 9): Always OFF
  pixels.setPixelColor(base + 9, 0);

  // 3. Left Column Sets (2 LEDs: LEDs 11..12 -> base + 10..11)
  // S1 = LED 11 (base + 10, lower set dot), S2 = LED 12 (base + 11, upper set dot)
  pixels.setPixelColor(base + 10, (leftSets >= 1) ? leftColor : 0);
  pixels.setPixelColor(base + 11, (leftSets >= 2) ? leftColor : 0);

  // 4. Right Column Sets (2 LEDs: LEDs 13..14 -> base + 12..13)
  // LED 13 (base + 12) is S2 (top right dot)
  // LED 14 (base + 13) is S1 (lower right set dot)
  pixels.setPixelColor(base + 13, (rightSets >= 1) ? rightColor : 0);
  pixels.setPixelColor(base + 12, (rightSets >= 2) ? rightColor : 0);

  // 5. Right Column Spacer Gap (LED 15 -> base + 14): Always OFF
  pixels.setPixelColor(base + 14, 0);

  // 6. Right Column Games (9 LEDs: LEDs 16..24 -> base + 15..23)
  for (int g = 0; g < 9; g++) {
    int ledIdx = base + 23 - g; // g=0 (Game 1) -> LED 24, g=1 (Game 2) -> LED 23, etc.
    pixels.setPixelColor(ledIdx, (g < rightGames) ? rightColor : 0);
  }
}

inline void drawGamesAndSets(bool swapped, float brightnessFactor = 1.0f) {
  drawGamesAndSets(team1Games, team1Sets, team2Games, team2Sets, swapped, brightnessFactor);
}

// ==============================================================================
// 2x4 LED Colon in Games & Sets Module
// Upper Colon Dot (4 LEDs): Left slots 7,8 (base+7, base+8) & Right slots 7,8 (base+16, base+15)
// Lower Colon Dot (4 LEDs): Left slots 3,4 (base+3, base+4) & Right slots 3,4 (base+20, base+19)
// All other 16 LEDs in the module remain OFF.
// ==============================================================================
void drawColonInGamesSets(bool showColon, uint32_t color) {
  int base = getGamesSetsBaseLed(); // LED index 56
  for (int i = 0; i < GAMES_SETS_LEDS; i++) {
    pixels.setPixelColor(base + i, 0);
  }
  if (!showColon) return;

  // Upper Colon Dot (4 LEDs cluster: Left slots 7 & 8, Right slots 7 & 8)
  pixels.setPixelColor(base + 7, color);
  pixels.setPixelColor(base + 8, color);
  pixels.setPixelColor(base + 15, color);
  pixels.setPixelColor(base + 16, color);

  // Lower Colon Dot (4 LEDs cluster: Left slots 3 & 4, Right slots 3 & 4)
  pixels.setPixelColor(base + 3, color);
  pixels.setPixelColor(base + 4, color);
  pixels.setPixelColor(base + 19, color);
  pixels.setPixelColor(base + 20, color);
}

// ==============================================================================
// Hardware SPI DMA WS2812 Driver (ESP32-C3)
// 100% immune to BLE / CPU preemption glitches. Hardware DMA pushes bits autonomously.
// ==============================================================================
bool bleInitialized = false;

#if defined(CONFIG_IDF_TARGET_ESP32C3)
#include <driver/spi_master.h>

#define NUM_DUMMY_PIXELS  1
#define TOTAL_SPI_PIXELS  (NUMPIXELS + NUM_DUMMY_PIXELS)

static spi_device_handle_t ws2813_spi = nullptr;
static uint8_t* ws2813_dma_buf = nullptr;
static size_t ws2813_dma_buf_size = 0;
static size_t ws2813_led_bytes = 0;
static size_t ws2813_reset_bytes = 0;
static uint32_t spiLookup[256];
static bool spiLookupReady = false;

static void initWs2813SpiDma() {
  if (!spiLookupReady) {
    for (int b = 0; b < 256; b++) {
      uint32_t pattern = 0;
      for (int bit = 7; bit >= 0; bit--) {
        // MSB first on wire: 4 SPI bits per WS2813 bit at 3.333 MHz (300ns/bit)
        // WS2813 Datasheet specifications:
        //   T0H = 220ns ~ 380ns (typical 300ns) -> '0' = 1000 (300ns HIGH, 900ns LOW)
        //   T1H = 580ns ~ 1600ns (typical 900ns) -> '1' = 1110 (900ns HIGH, 300ns LOW)
        uint32_t nibble = (b & (1 << bit)) ? 0x0E : 0x08;
        pattern = (pattern << 4) | nibble;
      }
      uint8_t b0 = (pattern >> 24) & 0xFF;
      uint8_t b1 = (pattern >> 16) & 0xFF;
      uint8_t b2 = (pattern >> 8)  & 0xFF;
      uint8_t b3 = pattern & 0xFF;
      // Little-endian packing for uint32: byte 0 is b0, byte 1 is b1, byte 2 is b2, byte 3 is b3
      spiLookup[b] = (uint32_t)b0 | ((uint32_t)b1 << 8) | ((uint32_t)b2 << 16) | ((uint32_t)b3 << 24);
    }
    spiLookupReady = true;
  }

  if (ws2813_spi == nullptr) {
    // Configure pull-down so MOSI is never pulled high or left floating when SPI is idle
    gpio_set_pull_mode((gpio_num_t)LED_PIN, GPIO_PULLDOWN_ONLY);
    gpio_set_drive_capability((gpio_num_t)LED_PIN, GPIO_DRIVE_CAP_3);

    // Each color byte expands to 4 SPI bytes (32 bits)
    ws2813_led_bytes = TOTAL_SPI_PIXELS * 3 * 4;
    // WS2813 requires >= 280us - 300us reset. 250 bytes * 8 * 300ns = 600us of continuous LOW!
    ws2813_reset_bytes = 250;
    ws2813_dma_buf_size = ws2813_led_bytes + ws2813_reset_bytes;

    spi_bus_config_t buscfg = {};
    buscfg.mosi_io_num = LED_PIN;
    buscfg.miso_io_num = -1;
    buscfg.sclk_io_num = -1;
    buscfg.quadwp_io_num = -1;
    buscfg.quadhd_io_num = -1;
    buscfg.max_transfer_sz = ws2813_dma_buf_size + 128;

    esp_err_t err = spi_bus_initialize(SPI2_HOST, &buscfg, SPI_DMA_CH_AUTO);
    if (err != ESP_OK && err != ESP_ERR_INVALID_STATE) {
      Serial.printf("[SPI-DMA] Bus init failed: %d\n", err);
      return;
    }

    spi_device_interface_config_t devcfg = {};
    // 3.333 MHz -> 80 MHz / 24: even integer divider with exact 50% duty cycle & zero jitter
    devcfg.clock_speed_hz = 3333333;
    devcfg.mode = 0;
    devcfg.spics_io_num = -1;
    devcfg.queue_size = 1;

    err = spi_bus_add_device(SPI2_HOST, &devcfg, &ws2813_spi);
    if (err != ESP_OK) {
      Serial.printf("[SPI-DMA] Device add failed: %d\n", err);
      return;
    }

    ws2813_dma_buf = (uint8_t*)heap_caps_malloc(ws2813_dma_buf_size, MALLOC_CAP_DMA);
    if (ws2813_dma_buf == nullptr) {
      Serial.println("[SPI-DMA] Buffer alloc failed!");
      return;
    }
    memset(ws2813_dma_buf, 0, ws2813_dma_buf_size);
    Serial.println("[SPI-DMA] Hardware SPI DMA WS2813 driver active on GPIO 2 (3.33MHz/300ns + 600us reset)!");
  }
}

static void showWs2813SpiDma() {
  if (ws2813_spi == nullptr || ws2813_dma_buf == nullptr) {
    initWs2813SpiDma();
    if (ws2813_spi == nullptr || ws2813_dma_buf == nullptr) {
      pixels.show();
      return;
    }
  }

  uint8_t* rawPixels = pixels.getPixels();
  if (rawPixels == nullptr) return;

  uint32_t* out32 = (uint32_t*)ws2813_dma_buf;
  size_t numBytes = NUMPIXELS * 3;
  for (size_t i = 0; i < numBytes; i++) {
    out32[i] = spiLookup[rawPixels[i]];
  }

  // Clock in 1 dummy blank pixel (24 bits = 3 color bytes = 3 uint32) to ensure the very last physical LED
  // has all 24 bits pushed completely through its internal shift register into its latch
  for (int i = 0; i < 3; i++) {
    out32[numBytes + i] = spiLookup[0];
  }

  // Guarantee trailing reset bytes are strictly 0x00 on every single frame
  memset(ws2813_dma_buf + ws2813_led_bytes, 0, ws2813_reset_bytes);

  spi_transaction_t t = {};
  t.length = ws2813_dma_buf_size * 8; // in bits
  t.tx_buffer = ws2813_dma_buf;
  spi_device_polling_transmit(ws2813_spi, &t);
}
#endif

void showPixelsSafe() {
#if defined(CONFIG_IDF_TARGET_ESP32C3)
  showWs2813SpiDma();
  delayMicroseconds(400);
#else
  pixels.show();
  delayMicroseconds(350);
#endif
}

void renderBoardWithState(bool swapped, float brightnessFactor) {
  pixels.clear();
  if (brightnessFactor <= 0.001f) {
    showPixelsSafe();
    return;
  }

  uint32_t colorBlue = scaleColor(pixels.Color(0, 180, 255), brightnessFactor);
  uint32_t colorRed  = scaleColor(pixels.Color(255, 0, 0),   brightnessFactor);

  int t1Tens, t1Ones, t2Tens, t2Ones;
  getTeamDigits(1, t1Tens, t1Ones);
  getTeamDigits(2, t2Tens, t2Ones);

  if (!swapped) {
    // Normal: Team 1 (Blue) on Left (0, 1), Team 2 (Red) on Right (2, 3)
    drawDigit(0, t1Tens, colorBlue);
    drawDigit(1, t1Ones, colorBlue);
    drawDigit(2, t2Tens, colorRed);
    drawDigit(3, t2Ones, colorRed);
  } else {
    // Swapped: Team 2 (Red) on Left (0, 1), Team 1 (Blue) on Right (2, 3)
    drawDigit(0, t2Tens, colorRed);
    drawDigit(1, t2Ones, colorRed);
    drawDigit(2, t1Tens, colorBlue);
    drawDigit(3, t1Ones, colorBlue);
  }

  // Draw Games & Sets module in the middle (LEDs 56..79)
  drawGamesAndSets(swapped, brightnessFactor);

  showPixelsSafe();
}

void animateCourtSideSwap(bool toSwapped) {
  bool fromSwapped = !toSwapped;
  uint32_t cBlue    = pixels.Color(0, 180, 255);
  uint32_t cRed     = pixels.Color(255, 0, 0);
  uint32_t cBlueDim = pixels.Color(0, 45, 65);
  uint32_t cRedDim  = pixels.Color(65, 0, 0);
  uint32_t cWhite   = pixels.Color(200, 200, 200);

  Serial.printf("[PADEL] >> Playing smooth Court Side Transition (%s -> %s)...\n",
                fromSwapped ? "Swapped" : "Normal",
                toSwapped   ? "Swapped" : "Normal");

  // Phase 1: Smooth fade down of current display
  for (int step = 3; step >= 0; step--) {
    renderBoardWithState(fromSwapped, step / 4.0f);
    delay(30);
  }
  pixels.clear();
  showPixelsSafe();
  delay(50);

  int gsBase = getGamesSetsBaseLed();

  // Phase 2: Orbital Crossover Flow across all 4 digits
  const int numFrames = 7;
  for (int frame = 0; frame < numFrames; frame++) {
    pixels.clear();

    if (toSwapped) {
      switch (frame) {
        case 0:
          drawSegment(0, 4, cBlue); // TL
          drawSegment(0, 5, cBlue); // T
          drawSegment(3, 2, cRed);  // BR
          drawSegment(3, 1, cRed);  // B
          break;
        case 1:
          drawSegment(0, 5, cBlueDim);
          drawSegment(0, 6, cBlue); // TR
          drawSegment(1, 4, cBlue); // TL
          drawSegment(1, 5, cBlue); // T
          drawSegment(3, 1, cRedDim);
          drawSegment(3, 0, cRed);  // BL
          drawSegment(2, 2, cRed);  // BR
          drawSegment(2, 1, cRed);  // B
          break;
        case 2:
          drawSegment(1, 5, cBlue); // T
          drawSegment(1, 6, cBlue); // TR
          drawSegment(1, 3, cBlueDim); // M trail
          drawSegment(2, 1, cRed);  // B
          drawSegment(2, 0, cRed);  // BL
          drawSegment(2, 3, cRedDim);  // M trail
          break;
        case 3:
          // Net crossover at center between Digit 1 and Digit 2
          drawSegment(1, 6, cBlue); // TR
          drawSegment(1, 3, cWhite); // Center net pulse
          drawSegment(2, 4, cBlue); // TL
          drawSegment(2, 0, cRed);  // BL
          drawSegment(2, 3, cWhite); // Center net pulse
          drawSegment(1, 2, cRed);  // BR
          pixels.setPixelColor(gsBase + 9, cWhite);
          pixels.setPixelColor(gsBase + 14, cWhite);
          break;
        case 4:
          drawSegment(2, 4, cBlueDim);
          drawSegment(2, 5, cBlue); // T
          drawSegment(2, 6, cBlue); // TR
          drawSegment(2, 3, cBlueDim);
          drawSegment(1, 2, cRedDim);
          drawSegment(1, 1, cRed);  // B
          drawSegment(1, 0, cRed);  // BL
          drawSegment(1, 3, cRedDim);
          break;
        case 5:
          drawSegment(2, 5, cBlueDim);
          drawSegment(3, 4, cBlue); // TL
          drawSegment(3, 5, cBlue); // T
          drawSegment(3, 6, cBlue); // TR
          drawSegment(1, 1, cRedDim);
          drawSegment(0, 2, cRed);  // BR
          drawSegment(0, 1, cRed);  // B
          drawSegment(0, 0, cRed);  // BL
          break;
        case 6:
          // Arrival confirmation: new home digits glow
          drawSegment(2, 5, cBlue);
          drawSegment(2, 3, cBlue);
          drawSegment(3, 5, cBlue);
          drawSegment(3, 3, cBlue);
          drawSegment(0, 1, cRed);
          drawSegment(0, 3, cRed);
          drawSegment(1, 1, cRed);
          drawSegment(1, 3, cRed);
          break;
      }
    } else {
      switch (frame) {
        case 0:
          drawSegment(3, 6, cBlue); // TR
          drawSegment(3, 5, cBlue); // T
          drawSegment(0, 0, cRed);  // BL
          drawSegment(0, 1, cRed);  // B
          break;
        case 1:
          drawSegment(3, 5, cBlueDim);
          drawSegment(3, 4, cBlue); // TL
          drawSegment(2, 6, cBlue); // TR
          drawSegment(2, 5, cBlue); // T
          drawSegment(0, 1, cRedDim);
          drawSegment(0, 2, cRed);  // BR
          drawSegment(1, 0, cRed);  // BL
          drawSegment(1, 1, cRed);  // B
          break;
        case 2:
          drawSegment(2, 5, cBlue); // T
          drawSegment(2, 4, cBlue); // TL
          drawSegment(2, 3, cBlueDim); // M trail
          drawSegment(1, 1, cRed);  // B
          drawSegment(1, 2, cRed);  // BR
          drawSegment(1, 3, cRedDim);  // M trail
          break;
        case 3:
          // Net crossover at center between Digit 2 and Digit 1
          drawSegment(2, 4, cBlue); // TL
          drawSegment(2, 3, cWhite); // Center net pulse
          drawSegment(1, 6, cBlue); // TR
          drawSegment(1, 2, cRed);  // BR
          drawSegment(1, 3, cWhite); // Center net pulse
          drawSegment(2, 0, cRed);  // BL
          pixels.setPixelColor(gsBase + 9, cWhite);
          pixels.setPixelColor(gsBase + 14, cWhite);
          break;
        case 4:
          drawSegment(1, 6, cBlueDim);
          drawSegment(1, 5, cBlue); // T
          drawSegment(1, 4, cBlue); // TL
          drawSegment(1, 3, cBlueDim);
          drawSegment(2, 0, cRedDim);
          drawSegment(2, 1, cRed);  // B
          drawSegment(2, 2, cRed);  // BR
          drawSegment(2, 3, cRedDim);
          break;
        case 5:
          drawSegment(1, 5, cBlueDim);
          drawSegment(0, 6, cBlue); // TR
          drawSegment(0, 5, cBlue); // T
          drawSegment(0, 4, cBlue); // TL
          drawSegment(2, 1, cRedDim);
          drawSegment(3, 0, cRed);  // BL
          drawSegment(3, 1, cRed);  // B
          drawSegment(3, 2, cRed);  // BR
          break;
        case 6:
          // Arrival confirmation
          drawSegment(0, 5, cBlue);
          drawSegment(0, 3, cBlue);
          drawSegment(1, 5, cBlue);
          drawSegment(1, 3, cBlue);
          drawSegment(2, 1, cRed);
          drawSegment(2, 3, cRed);
          drawSegment(3, 1, cRed);
          drawSegment(3, 3, cRed);
          break;
      }
    }

    showPixelsSafe();
    delay(45);
  }

  delay(40);
  pixels.clear();
  showPixelsSafe();
  delay(30);

  // Phase 3: Smooth fade up into new swapped positions
  for (int step = 1; step <= 4; step++) {
    renderBoardWithState(toSwapped, step / 4.0f);
    delay(35);
  }
}

void renderPadelScoreboard();

void renderClock() {
  pixels.clear();

  uint32_t clockColor = (cfgClockColor != 0) ? cfgClockColor : pixels.Color(cfgClockR, cfgClockG, cfgClockB);

  // Hours: Digits 0 & 1
  int hTens = curHour / 10;
  int hOnes = curHour % 10;
  if (hTens == 0) hTens = 10; // Blank leading zero (e.g. " 9:45")

  // Minutes: Digits 2 & 3
  int mTens = curMinute / 10;
  int mOnes = curMinute % 10;

  drawDigit(0, hTens, clockColor);
  drawDigit(1, hOnes, clockColor);

  // Blinking 2x4 LED colon in middle Games & Sets module: 500ms ON / 500ms OFF
  bool colonOn = (millis() % 1000) < 500;
  drawColonInGamesSets(colonOn, clockColor);

  drawDigit(2, mTens, clockColor);
  drawDigit(3, mOnes, clockColor);

  showPixelsSafe();
}

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
    case 'b': case 'B': segs[0]=segs[1]=segs[2]=segs[3]=segs[4]=true; break;
    case 'C': case 'c': segs[0]=segs[1]=segs[4]=segs[5]=true; break;
    case 'd': case 'D': segs[0]=segs[1]=segs[2]=segs[3]=segs[6]=true; break;
    case 'E': case 'e': segs[0]=segs[1]=segs[3]=segs[4]=segs[5]=true; break;
    case 'F': case 'f': segs[0]=segs[3]=segs[4]=segs[5]=true; break;
    case 'H': case 'h': segs[0]=segs[2]=segs[3]=segs[4]=segs[6]=true; break;
    case 'L': case 'l': segs[0]=segs[1]=segs[4]=true; break;
    case 'n': case 'N': segs[0]=segs[2]=segs[3]=true; break;
    case 'O': case 'o': segs[0]=segs[1]=segs[2]=segs[4]=segs[5]=segs[6]=true; break;
    case 'P': case 'p': segs[0]=segs[3]=segs[4]=segs[5]=segs[6]=true; break;
    case 'r': case 'R': segs[0]=segs[3]=true; break;
    case 'S': case 's': segs[1]=segs[2]=segs[3]=segs[4]=segs[5]=true; break;
    case 't': case 'T': segs[0]=segs[1]=segs[3]=segs[4]=true; break;
    case 'U': case 'u': segs[0]=segs[1]=segs[2]=segs[4]=segs[6]=true; break;
    case '-': segs[3]=true; break;
    default: break;
  }
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
    bool segOn = segs[seg];
    for (int i = 0; i < LEDS_PER_SEGMENT; i++) {
      int p = startPixel + i;
      if (p >= 0 && p < NUMPIXELS) {
        pixels.setPixelColor(p, segOn ? color : 0);
      }
    }
  }
}

void splashText(const char* text, uint32_t color) {
  pixels.clear();
  drawGamesAndSets(0, 0, 0, 0);
  int len = strlen(text);
  for (int i = 0; i < NUM_DIGITS; i++) {
    char c = (i < len) ? text[i] : ' ';
    drawChar(i, c, color);
  }
  showPixelsSafe();
}

void renderMatchSetScores() {
  pixels.clear();
  uint32_t cBlue = pixels.Color(0, 180, 255);
  uint32_t cRed  = pixels.Color(255, 0, 0);

  int leftS1, rightS1;
  int leftS2, rightS2;

  // Determine if we show Set 1 & Set 2, or (if 3 sets played) cycle between Set 1+2 and Set 2+3
  bool showSet2and3 = (totalSetsPlayed >= 3) && (((millis() / 4000) % 2) == 1);

  if (!showSet2and3) {
    // Left 2 segments: Set 1
    leftS1  = set1Games1;
    rightS1 = set1Games2;
    // Right 2 segments: Set 2
    leftS2  = set2Games1;
    rightS2 = set2Games2;
  } else {
    // Left 2 segments: Set 2
    leftS1  = set2Games1;
    rightS1 = set2Games2;
    // Right 2 segments: Set 3
    leftS2  = set3Games1;
    rightS2 = set3Games2;
  }

  // Draw Set on left 2 segments (Digit 0: Team 1 games, Digit 1: Team 2 games)
  drawDigit(0, leftS1 % 10, cBlue);
  drawDigit(1, rightS1 % 10, cRed);

  // Middle Games & Sets module: show final sets won dots (S1, S2)
  drawGamesAndSets(0, team1Sets, 0, team2Sets, false, 1.0f);

  // Draw Set on right 2 panels (Digit 2: Team 1 games, Digit 3: Team 2 games)
  drawDigit(2, leftS2 % 10, cBlue);
  drawDigit(3, rightS2 % 10, cRed);

  showPixelsSafe();
}

void renderPadelScoreboard() {
  if (matchWon) {
    if (matchWonPhase == MATCH_PHASE_SPEL) {
      uint32_t winColor = (winningTeam == 1) ? pixels.Color(0, 180, 255) : pixels.Color(255, 0, 0);
      splashText("SPEL", winColor);
      return;
    } else if (matchWonPhase == MATCH_PHASE_SET_SCORES) {
      renderMatchSetScores();
      return;
    }
  }
  renderBoardWithState(isCourtSwapped(), 1.0f);
}

// ==============================================================================
// Padel & Match Engine Logic & History
// ==============================================================================
void saveScoreState() {
  if (historyCount < SCORE_HISTORY_DEPTH) {
    scoreHistory[historyCount].p1 = team1Point;
    scoreHistory[historyCount].p2 = team2Point;
    scoreHistory[historyCount].games1 = team1Games;
    scoreHistory[historyCount].games2 = team2Games;
    scoreHistory[historyCount].sets1 = team1Sets;
    scoreHistory[historyCount].sets2 = team2Sets;
    scoreHistory[historyCount].matchWon = matchWon;
    scoreHistory[historyCount].s1g1 = set1Games1;
    scoreHistory[historyCount].s1g2 = set1Games2;
    scoreHistory[historyCount].s2g1 = set2Games1;
    scoreHistory[historyCount].s2g2 = set2Games2;
    scoreHistory[historyCount].s3g1 = set3Games1;
    scoreHistory[historyCount].s3g2 = set3Games2;
    scoreHistory[historyCount].setsPlayed = totalSetsPlayed;
    scoreHistory[historyCount].inTb = inTiebreak;
    scoreHistory[historyCount].tb1 = tiebreakPoints1;
    scoreHistory[historyCount].tb2 = tiebreakPoints2;
    historyCount++;
  } else {
    for (int i = 0; i < SCORE_HISTORY_DEPTH - 1; i++) {
      scoreHistory[i] = scoreHistory[i + 1];
    }
    scoreHistory[SCORE_HISTORY_DEPTH - 1].p1 = team1Point;
    scoreHistory[SCORE_HISTORY_DEPTH - 1].p2 = team2Point;
    scoreHistory[SCORE_HISTORY_DEPTH - 1].games1 = team1Games;
    scoreHistory[SCORE_HISTORY_DEPTH - 1].games2 = team2Games;
    scoreHistory[SCORE_HISTORY_DEPTH - 1].sets1 = team1Sets;
    scoreHistory[SCORE_HISTORY_DEPTH - 1].sets2 = team2Sets;
    scoreHistory[SCORE_HISTORY_DEPTH - 1].matchWon = matchWon;
    scoreHistory[SCORE_HISTORY_DEPTH - 1].s1g1 = set1Games1;
    scoreHistory[SCORE_HISTORY_DEPTH - 1].s1g2 = set1Games2;
    scoreHistory[SCORE_HISTORY_DEPTH - 1].s2g1 = set2Games1;
    scoreHistory[SCORE_HISTORY_DEPTH - 1].s2g2 = set2Games2;
    scoreHistory[SCORE_HISTORY_DEPTH - 1].s3g1 = set3Games1;
    scoreHistory[SCORE_HISTORY_DEPTH - 1].s3g2 = set3Games2;
    scoreHistory[SCORE_HISTORY_DEPTH - 1].setsPlayed = totalSetsPlayed;
    scoreHistory[SCORE_HISTORY_DEPTH - 1].inTb = inTiebreak;
    scoreHistory[SCORE_HISTORY_DEPTH - 1].tb1 = tiebreakPoints1;
    scoreHistory[SCORE_HISTORY_DEPTH - 1].tb2 = tiebreakPoints2;
  }
}

bool undoScoreState() {
  if (historyCount <= 0) return false;
  historyCount--;
  team1Point = scoreHistory[historyCount].p1;
  team2Point = scoreHistory[historyCount].p2;
  team1Games = scoreHistory[historyCount].games1;
  team2Games = scoreHistory[historyCount].games2;
  team1Sets = scoreHistory[historyCount].sets1;
  team2Sets = scoreHistory[historyCount].sets2;
  matchWon = scoreHistory[historyCount].matchWon;
  set1Games1 = scoreHistory[historyCount].s1g1;
  set1Games2 = scoreHistory[historyCount].s1g2;
  set2Games1 = scoreHistory[historyCount].s2g1;
  set2Games2 = scoreHistory[historyCount].s2g2;
  set3Games1 = scoreHistory[historyCount].s3g1;
  set3Games2 = scoreHistory[historyCount].s3g2;
  totalSetsPlayed = scoreHistory[historyCount].setsPlayed;
  inTiebreak = scoreHistory[historyCount].inTb;
  tiebreakPoints1 = scoreHistory[historyCount].tb1;
  tiebreakPoints2 = scoreHistory[historyCount].tb2;
  if (!matchWon) {
    matchWonPhase = MATCH_PHASE_NONE;
  }
  return true;
}

void addPadelPoint(int team) {
  // If match was already completed, a button click starts a brand-new match:
  if (matchWon) {
    if (millis() - matchWonStartTime < 3000) {
      return; // Ignore accidental button presses within 3s of match completion
    }
    matchWon = false;
    matchWonPhase = MATCH_PHASE_NONE;
    team1Sets = 0;
    team2Sets = 0;
    team1Games = 0;
    team2Games = 0;
    set1Games1 = 0; set1Games2 = 0;
    set2Games1 = 0; set2Games2 = 0;
    set3Games1 = 0; set3Games2 = 0;
    totalSetsPlayed = 0;
    inTiebreak = false;
    tiebreakPoints1 = 0;
    tiebreakPoints2 = 0;
    team1Point = POINT_0;
    team2Point = POINT_0;
    saveScoreState();
  } else {
    saveScoreState();
  }

  // If currently in a Tiebreak:
  if (inTiebreak) {
    if (team == 1) {
      tiebreakPoints1++;
    } else {
      tiebreakPoints2++;
    }
    Serial.printf("[TIEBREAK] Point! %d - %d\n", tiebreakPoints1, tiebreakPoints2);

    bool tbWon = false;
    int tbWinner = 0;
    if (tiebreakPoints1 >= 7 && (tiebreakPoints1 - tiebreakPoints2 >= 2)) {
      tbWon = true;
      tbWinner = 1;
    } else if (tiebreakPoints2 >= 7 && (tiebreakPoints2 - tiebreakPoints1 >= 2)) {
      tbWon = true;
      tbWinner = 2;
    }

    if (tbWon) {
      inTiebreak = false;
      winningTeam = tbWinner;
      if (tbWinner == 1) {
        team1Games++;
        team1Sets++;
      } else {
        team2Games++;
        team2Sets++;
      }

      // Record this completed set's final games (e.g. 7-6 or 9-8):
      if (totalSetsPlayed == 0) {
        set1Games1 = team1Games; set1Games2 = team2Games; totalSetsPlayed = 1;
      } else if (totalSetsPlayed == 1) {
        set2Games1 = team1Games; set2Games2 = team2Games; totalSetsPlayed = 2;
      } else {
        set3Games1 = team1Games; set3Games2 = team2Games; totalSetsPlayed = 3;
      }

      // Check Match Won condition (configurable: 1 set or best of 3):
      if (team1Sets >= cfgSetsToWin || team2Sets >= cfgSetsToWin) {
        matchWon = true;
        matchWonPhase = MATCH_PHASE_SPEL;
        matchWonStartTime = millis();
        triggerMatchWonAnimation = true;
      } else {
        triggerSetWonAnimation = true;
      }

      team1Games = 0;
      team2Games = 0;
      team1Point = POINT_0;
      team2Point = POINT_0;
      tiebreakPoints1 = 0;
      tiebreakPoints2 = 0;
    }

    notifyWatchScore();
    return;
  }

  bool gameWon = false;
  int gameWinner = 0;

  if (team == 1) {
    if (team1Point == POINT_40) {
      if (team2Point == POINT_40) {
        if (cfgGoldenPoint) {
          // Golden Point / Punto de Oro: Deciding point wins immediately!
          gameWon = true;
          gameWinner = 1;
        } else {
          team1Point = POINT_AD; // 40-40 -> Ad-40
        }
      } else if (team2Point == POINT_AD) {
        team2Point = POINT_40; // 40-Ad -> 40-40 Deuce
      } else {
        gameWon = true;
        gameWinner = 1;
      }
    } else if (team1Point == POINT_AD) {
      gameWon = true;
      gameWinner = 1;
    } else {
      team1Point = (PadelPoint)((int)team1Point + 1);
    }
  } else {
    if (team2Point == POINT_40) {
      if (team1Point == POINT_40) {
        if (cfgGoldenPoint) {
          // Golden Point / Punto de Oro: Deciding point wins immediately!
          gameWon = true;
          gameWinner = 2;
        } else {
          team2Point = POINT_AD; // 40-40 -> 40-Ad
        }
      } else if (team1Point == POINT_AD) {
        team1Point = POINT_40; // Ad-40 -> 40-40 Deuce
      } else {
        gameWon = true;
        gameWinner = 2;
      }
    } else if (team2Point == POINT_AD) {
      gameWon = true;
      gameWinner = 2;
    } else {
      team2Point = (PadelPoint)((int)team2Point + 1);
    }
  }

  if (gameWon) {
    team1Point = POINT_0;
    team2Point = POINT_0;
    winningTeam = gameWinner;

    if (gameWinner == 1) {
      team1Games++;
    } else {
      team2Games++;
    }

    // Check Tiebreak trigger condition:
    // When both teams reach cfgGamesPerSet (e.g. 6-6 or 8-8) and tiebreak is enabled:
    if (cfgTiebreak && team1Games == cfgGamesPerSet && team2Games == cfgGamesPerSet) {
      inTiebreak = true;
      tiebreakPoints1 = 0;
      tiebreakPoints2 = 0;
      Serial.printf("[PADEL] 🔥 %d-%d Reached -> ENTERING TIEBREAK!\n", cfgGamesPerSet, cfgGamesPerSet);
      notifyWatchScore();
      return;
    }

    // Check Set Won condition:
    // Win set at cfgGamesPerSet (6 or 9) with >=2 lead, or advantage sets if tiebreak disabled
    bool setWon = false;
    if (gameWinner == 1) {
      if ((team1Games >= cfgGamesPerSet && (team1Games - team2Games >= 2)) || (!cfgTiebreak && team1Games >= cfgGamesPerSet + 1)) {
        setWon = true;
        team1Sets++;
      }
    } else {
      if ((team2Games >= cfgGamesPerSet && (team2Games - team1Games >= 2)) || (!cfgTiebreak && team2Games >= cfgGamesPerSet + 1)) {
        setWon = true;
        team2Sets++;
      }
    }

    if (setWon) {
      // Record this completed set's final games:
      if (totalSetsPlayed == 0) {
        set1Games1 = team1Games;
        set1Games2 = team2Games;
        totalSetsPlayed = 1;
      } else if (totalSetsPlayed == 1) {
        set2Games1 = team1Games;
        set2Games2 = team2Games;
        totalSetsPlayed = 2;
      } else {
        set3Games1 = team1Games;
        set3Games2 = team2Games;
        totalSetsPlayed = 3;
      }

      // Check Match Won condition (configurable: 1 set or best of 3):
      if (team1Sets >= cfgSetsToWin || team2Sets >= cfgSetsToWin) {
        matchWon = true;
        matchWonPhase = MATCH_PHASE_SPEL;
        matchWonStartTime = millis();
        triggerMatchWonAnimation = true;
      } else {
        triggerSetWonAnimation = true;
      }
      // Reset games for the new set
      team1Games = 0;
      team2Games = 0;
    } else {
      triggerGameWonAnimation = true;
    }
  }

  notifyWatchScore();
}

// ==============================================================================
// Watch BLE App Synchronization Helper Functions
// ==============================================================================
PadelPoint parsePadelPoint(char tens, char ones) {
  if (tens == 'A' || tens == 'a' || ones == 'A' || ones == 'a' || ones == 'd' || ones == 'D') return POINT_AD;
  if (tens == '4' && ones == '0') return POINT_40;
  if (tens == '3' && ones == '0') return POINT_30;
  if (tens == '1' && ones == '5') return POINT_15;
  if (ones == '0') return POINT_0;
  return POINT_0;
}

void formatPadelPoint(PadelPoint pt, char &tens, char &ones) {
  switch (pt) {
    case POINT_0:  tens = ' '; ones = '0'; break;
    case POINT_15: tens = '1'; ones = '5'; break;
    case POINT_30: tens = '3'; ones = '0'; break;
    case POINT_40: tens = '4'; ones = '0'; break;
    case POINT_AD: tens = 'A'; ones = 'd'; break;
    default:       tens = ' '; ones = '0'; break;
  }
}

void notifyWatchScore() {
  if (pWatchCharacteristic == nullptr) return;
  char t1T, t1O, t2T, t2O;
  if (inTiebreak) {
    t1T = (tiebreakPoints1 >= 10) ? ('0' + (tiebreakPoints1 / 10)) : ' ';
    t1O = '0' + (tiebreakPoints1 % 10);
    t2T = (tiebreakPoints2 >= 10) ? ('0' + (tiebreakPoints2 / 10)) : ' ';
    t2O = '0' + (tiebreakPoints2 % 10);
  } else {
    formatPadelPoint(team1Point, t1T, t1O);
    formatPadelPoint(team2Point, t2T, t2O);
  }
  char buf[48];
  if (!currentCourtSwapped) {
    snprintf(buf, sizeof(buf), "%c%c%c%c,0,%d,%d,%d,%d,%d",
             t1T, t1O, t2T, t2O,
             team1Games, team2Games, team1Sets, team2Sets, inTiebreak ? 1 : 0);
  } else {
    snprintf(buf, sizeof(buf), "%c%c%c%c,1,%d,%d,%d,%d,%d",
             t2T, t2O, t1T, t1O,
             team2Games, team1Games, team2Sets, team1Sets, inTiebreak ? 1 : 0);
  }
  pWatchCharacteristic->setValue((uint8_t*)buf, strlen(buf));
  pWatchCharacteristic->notify();
  Serial.printf("[BLE-WATCH] Notified client: '%s'\n", buf);
}

void setClockTime(int h, int m, int s) {
  if (h < 0 || h > 23) h = 0;
  if (m < 0 || m > 59) m = 0;
  if (s < 0 || s > 59) s = 0;

  curHour = h;
  curMinute = m;
  curSecond = s;
  lastInternalTick = millis();

  // If RTC hardware is present/running, set its register
  if (rtcAvailable || Rtc.GetIsRunning()) {
    RtcDateTime now = Rtc.GetDateTime();
    int year = (now.IsValid() && now.Year() >= 2024 && now.Year() <= 2099) ? now.Year() : 2026;
    int month = (now.IsValid() && now.Month() >= 1 && now.Month() <= 12) ? now.Month() : 9;
    int day = (now.IsValid() && now.Day() >= 1 && now.Day() <= 31) ? now.Day() : 6;
    Rtc.SetDateTime(RtcDateTime(year, month, day, h, m, s));
    Serial.printf("[RTC] Synced hardware RTC to: %02d:%02d:%02d\n", h, m, s);
    rtcAvailable = true;
  } else {
    Serial.printf("[RTC] Synced software timer to: %02d:%02d:%02d\n", h, m, s);
  }
}

void resetMatchScores() {
  saveScoreState();
  team1Point = POINT_0;
  team2Point = POINT_0;
  team1Games = 0;
  team2Games = 0;
  team1Sets  = 0;
  team2Sets  = 0;
  inTiebreak = false;
  tiebreakPoints1 = 0;
  tiebreakPoints2 = 0;
  matchWon = false;
  matchWonPhase = MATCH_PHASE_NONE;
  currentCourtSwapped = false;
  scoreNeedsUpdate = true;
  notifyWatchScore();
  Serial.println("[PADEL] Match scores reset to 0-0 (0-0, 0-0)");
}

void sendConfigNotification() {
  if (pWatchCharacteristic == nullptr) return;
  char colHex[10];
  snprintf(colHex, sizeof(colHex), "#%02X%02X%02X", cfgClockR, cfgClockG, cfgClockB);
  char buf[128];
  snprintf(buf, sizeof(buf), "CFG,GP=%d,SETS=%d,GAMES=%d,TB=%d,BRT=%d,IDLE=%lu,COL=%s",
           cfgGoldenPoint ? 1 : 0, cfgSetsToWin, cfgGamesPerSet, cfgTiebreak ? 1 : 0,
           cfgBrightness, (unsigned long)cfgIdleTimeoutMs, colHex);
  pWatchCharacteristic->setValue((uint8_t*)buf, strlen(buf));
  pWatchCharacteristic->notify();
  Serial.printf("[BLE-CFG] Notified client: '%s'\n", buf);
}

void parseConfigPayload(const std::string& val) {
  if (val.find("GP=") != std::string::npos || val.find("BRT=") != std::string::npos || val.find("IDLE=") != std::string::npos || val.find("COL=") != std::string::npos) {
    if (val.find("GP=1") != std::string::npos) cfgGoldenPoint = true;
    else if (val.find("GP=0") != std::string::npos) cfgGoldenPoint = false;

    size_t sPos = val.find("SETS=");
    if (sPos != std::string::npos) cfgSetsToWin = atoi(val.substr(sPos + 5).c_str());

    size_t gPos = val.find("GAMES=");
    if (gPos != std::string::npos) cfgGamesPerSet = atoi(val.substr(gPos + 6).c_str());

    if (val.find("TB=1") != std::string::npos) cfgTiebreak = true;
    else if (val.find("TB=0") != std::string::npos) cfgTiebreak = false;

    size_t bPos = val.find("BRT=");
    if (bPos != std::string::npos) {
      int brt = atoi(val.substr(bPos + 4).c_str());
      if (brt >= 10 && brt <= 255) {
        cfgBrightness = (uint8_t)brt;
        pixels.setBrightness(cfgBrightness);
        showPixelsSafe();
      }
    }

    size_t iPos = val.find("IDLE=");
    if (iPos != std::string::npos) {
      long idle = atol(val.substr(iPos + 5).c_str());
      if (idle >= 0) {
        cfgIdleTimeoutMs = (uint32_t)idle;
      }
    }

    size_t cPos = val.find("COL=");
    if (cPos != std::string::npos) {
      std::string hexStr = val.substr(cPos + 4);
      size_t endComma = hexStr.find(',');
      if (endComma != std::string::npos) hexStr = hexStr.substr(0, endComma);
      if (!hexStr.empty() && hexStr[0] == '#') hexStr = hexStr.substr(1);
      if (hexStr.length() >= 6) {
        unsigned int r = 0, g = 0, b = 0;
        if (sscanf(hexStr.c_str(), "%02x%02x%02x", &r, &g, &b) == 3) {
          cfgClockR = (uint8_t)r;
          cfgClockG = (uint8_t)g;
          cfgClockB = (uint8_t)b;
          cfgClockColor = pixels.Color(cfgClockR, cfgClockG, cfgClockB);
          Serial.printf("[CONFIG] Parsed clock color: #%02X%02X%02X\n", cfgClockR, cfgClockG, cfgClockB);
        }
      }
    }
  } else {
    std::vector<std::string> parts;
    size_t pos = 0, nextPos;
    while ((nextPos = val.find(',', pos)) != std::string::npos) {
      parts.push_back(val.substr(pos, nextPos - pos));
      pos = nextPos + 1;
    }
    parts.push_back(val.substr(pos));
    if (parts.size() >= 5) {
      cfgGoldenPoint = (atoi(parts[1].c_str()) != 0);
      cfgSetsToWin   = atoi(parts[2].c_str());
      cfgGamesPerSet = atoi(parts[3].c_str());
      cfgTiebreak    = (atoi(parts[4].c_str()) != 0);
    }
    if (parts.size() >= 6) {
      int brt = atoi(parts[5].c_str());
      if (brt >= 10 && brt <= 255) {
        cfgBrightness = (uint8_t)brt;
        pixels.setBrightness(cfgBrightness);
        showPixelsSafe();
      }
    }
    if (parts.size() >= 7) {
      long idle = atol(parts[6].c_str());
      if (idle >= 0) cfgIdleTimeoutMs = (uint32_t)idle;
    }
    if (parts.size() >= 8) {
      std::string hexStr = parts[7];
      if (!hexStr.empty() && hexStr[0] == '#') hexStr = hexStr.substr(1);
      if (hexStr.length() >= 6) {
        unsigned int r = 0, g = 0, b = 0;
        if (sscanf(hexStr.c_str(), "%02x%02x%02x", &r, &g, &b) == 3) {
          cfgClockR = (uint8_t)r;
          cfgClockG = (uint8_t)g;
          cfgClockB = (uint8_t)b;
          cfgClockColor = pixels.Color(cfgClockR, cfgClockG, cfgClockB);
        }
      }
    }
  }

  if (cfgSetsToWin < 1 || cfgSetsToWin > 3) cfgSetsToWin = 2;
  if (cfgGamesPerSet != 6 && cfgGamesPerSet != 9) cfgGamesPerSet = 6;

  // Persist to NVS Flash
  Preferences cfgPrefs;
  cfgPrefs.begin("padel_cfg", false);
  cfgPrefs.putBool("golden_point", cfgGoldenPoint);
  cfgPrefs.putInt("sets_to_win", cfgSetsToWin);
  cfgPrefs.putInt("games_per_set", cfgGamesPerSet);
  cfgPrefs.putBool("tiebreak", cfgTiebreak);
  cfgPrefs.putUChar("brightness", cfgBrightness);
  cfgPrefs.putULong("idle_timeout", cfgIdleTimeoutMs);
  cfgPrefs.putUChar("clock_r", cfgClockR);
  cfgPrefs.putUChar("clock_g", cfgClockG);
  cfgPrefs.putUChar("clock_b", cfgClockB);
  cfgPrefs.end();

  Serial.printf("[CONFIG] Saved to flash: GP=%d, SetsToWin=%d, GamesPerSet=%d, Tiebreak=%d, Brightness=%d, IdleTimeout=%lu, ClockColor=#%02X%02X%02X\n",
                cfgGoldenPoint, cfgSetsToWin, cfgGamesPerSet, cfgTiebreak, cfgBrightness, (unsigned long)cfgIdleTimeoutMs,
                cfgClockR, cfgClockG, cfgClockB);

  if (currentMode == MODE_CLOCK) {
    renderClock();
  }

  sendConfigNotification();
}

class WatchServerCallbacks : public NimBLEServerCallbacks {
  void onConnect(NimBLEServer* pServer) override {
    Serial.println("[BLE-WATCH] Client connected!");
    notifyWatchScore();
    sendConfigNotification();
  }

  void onDisconnect(NimBLEServer* pServer) override {
    Serial.println("[BLE-WATCH] Client disconnected. Restarting advertising...");
    NimBLEDevice::startAdvertising();
  }
};

class WatchCharCallbacks : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic* pCharacteristic) override {
    std::string val = pCharacteristic->getValue();
    if (val.empty()) return;
    Serial.printf("[BLE-WATCH] Received payload: '%s'\n", val.c_str());

    // 1. Configuration command: "CFG,..."
    if (val.rfind("CFG", 0) == 0) {
      parseConfigPayload(val);
      splashText("CFG ", pixels.Color(0, 180, 0));
      delay(300);
      scoreNeedsUpdate = true;
      return;
    }

    // 2. Time Synchronization command: "TIME,HH:MM:SS" or "TIME,HH:MM"
    if (val.rfind("TIME,", 0) == 0) {
      std::string timePart = val.substr(5);
      int h = 0, m = 0, s = 0;
      if (sscanf(timePart.c_str(), "%d:%d:%d", &h, &m, &s) >= 2) {
        setClockTime(h, m, s);
        splashText("TIME", pixels.Color(0, 220, 100));
        delay(400);
        if (currentMode == MODE_CLOCK) renderClock();
      }
      return;
    }

    // 3. Remote Control commands: "CMD,..."
    if (val.rfind("CMD,", 0) == 0) {
      std::string cmd = val.substr(4);
      lastActivityTime = millis();
      if (cmd == "P1") {
        if (currentMode == MODE_CLOCK) currentMode = MODE_SCOREBOARD;
        addPadelPoint(1);
        bool newSwapped = isCourtSwapped();
        if (newSwapped != currentCourtSwapped) {
          animateCourtSideSwap(newSwapped);
          currentCourtSwapped = newSwapped;
        }
        scoreNeedsUpdate = true;
      } else if (cmd == "P2") {
        if (currentMode == MODE_CLOCK) currentMode = MODE_SCOREBOARD;
        addPadelPoint(2);
        bool newSwapped = isCourtSwapped();
        if (newSwapped != currentCourtSwapped) {
          animateCourtSideSwap(newSwapped);
          currentCourtSwapped = newSwapped;
        }
        scoreNeedsUpdate = true;
      } else if (cmd == "UNDO") {
        if (undoScoreState()) {
          bool newSwapped = isCourtSwapped();
          if (newSwapped != currentCourtSwapped) {
            animateCourtSideSwap(newSwapped);
            currentCourtSwapped = newSwapped;
          }
          notifyWatchScore();
          scoreNeedsUpdate = true;
        }
      } else if (cmd == "RESET") {
        resetMatchScores();
        splashText("RST ", pixels.Color(255, 120, 0));
        delay(300);
      } else if (cmd == "SWAP") {
        currentCourtSwapped = !currentCourtSwapped;
        animateCourtSideSwap(currentCourtSwapped);
        notifyWatchScore();
        scoreNeedsUpdate = true;
      } else if (cmd == "CLOCK") {
        currentMode = MODE_CLOCK;
        renderClock();
      } else if (cmd == "SCORE") {
        currentMode = MODE_SCOREBOARD;
        scoreNeedsUpdate = true;
      } else if (cmd == "REQ" || cmd == "REQ_CFG") {
        sendConfigNotification();
        notifyWatchScore();
      } else if (cmd.rfind("COL,", 0) == 0 || cmd.rfind("COLOR,", 0) == 0) {
        std::string hexStr = (cmd.rfind("COLOR,", 0) == 0) ? cmd.substr(6) : cmd.substr(4);
        if (!hexStr.empty() && hexStr[0] == '#') hexStr = hexStr.substr(1);
        if (hexStr.length() >= 6) {
          unsigned int r = 0, g = 0, b = 0;
          if (sscanf(hexStr.c_str(), "%02x%02x%02x", &r, &g, &b) == 3) {
            cfgClockR = (uint8_t)r;
            cfgClockG = (uint8_t)g;
            cfgClockB = (uint8_t)b;
            cfgClockColor = pixels.Color(cfgClockR, cfgClockG, cfgClockB);
            Serial.printf("[BLE] Live clock color updated: #%02X%02X%02X\n", cfgClockR, cfgClockG, cfgClockB);
            if (currentMode == MODE_CLOCK) renderClock();
          }
        }
      }
      return;
    }

    // 4. Watch score sync string: "SCORE,FLAG[,G1,G2,S1,S2]"
    if (currentMode == MODE_CLOCK) {
      Serial.println("[MODE] Watch command received -> Waking up from Clock Mode to Score Mode!");
      currentMode = MODE_SCOREBOARD;
    }
    lastActivityTime = millis();

    std::string scoreStr = val;
    bool watchSwapped = currentCourtSwapped;

    // Parse comma-separated fields: "SCORE,FLAG[,G1,G2,S1,S2]"
    std::vector<std::string> parts;
    size_t pos = 0, nextPos;
    while ((nextPos = val.find(',', pos)) != std::string::npos) {
      parts.push_back(val.substr(pos, nextPos - pos));
      pos = nextPos + 1;
    }
    parts.push_back(val.substr(pos));

    if (parts.size() >= 1) {
      scoreStr = parts[0];
    }
    if (parts.size() >= 2 && !parts[1].empty()) {
      watchSwapped = (parts[1][0] == '1');
    }

    while (scoreStr.length() < 4) scoreStr += " ";

    saveScoreState();
    if (!watchSwapped) {
      team1Point = parsePadelPoint(scoreStr[0], scoreStr[1]);
      team2Point = parsePadelPoint(scoreStr[2], scoreStr[3]);
    } else {
      team2Point = parsePadelPoint(scoreStr[0], scoreStr[1]);
      team1Point = parsePadelPoint(scoreStr[2], scoreStr[3]);
    }

    // If watch provided games and sets, update them as well:
    if (parts.size() >= 6) {
      int g1 = atoi(parts[2].c_str());
      int g2 = atoi(parts[3].c_str());
      int s1 = atoi(parts[4].c_str());
      int s2 = atoi(parts[5].c_str());
      if (!watchSwapped) {
        team1Games = g1;
        team2Games = g2;
        team1Sets  = s1;
        team2Sets  = s2;
      } else {
        team2Games = g1;
        team1Games = g2;
        team2Sets  = s1;
        team1Sets  = s2;
      }
      Serial.printf("[BLE-WATCH] Synced games (%d-%d) and sets (%d-%d)\n",
                    team1Games, team2Games, team1Sets, team2Sets);
    }

    if (watchSwapped != currentCourtSwapped) {
      animateCourtSideSwap(watchSwapped);
      currentCourtSwapped = watchSwapped;
    }
    scoreNeedsUpdate = true;
  }
};

// ==============================================================================
// RTC & Clock Management
// ==============================================================================
void initClockRtc() {
  Rtc.Begin();
  if (!Rtc.GetIsRunning()) {
    Rtc.SetIsRunning(true);
  }
  if (Rtc.GetIsWriteProtected()) {
    Rtc.SetIsWriteProtected(false);
  }

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
    curHour   = compiledTime.Hour();
    curMinute = compiledTime.Minute();
    curSecond = compiledTime.Second();
    Serial.printf("[RTC] RTC not detected. Using internal timer starting at: %02d:%02d:%02d\n", curHour, curMinute, curSecond);
    setStatusLed(50, 25, 0); // Orange: Software timer mode
  }
  lastInternalTick = millis();
}

void updateClockTime() {
  static uint32_t lastRtcPoll = 0;
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
}

// ==============================================================================
// Button & Interaction Logic
// ==============================================================================
void handleButtonPress(RemoteButton btn) {
  uint32_t now = millis();

  // If currently in Clock Mode, ANY button press wakes up to Scoreboard Mode and displays previous score!
  if (currentMode == MODE_CLOCK) {
    Serial.println("[MODE] Remote Button Pressed -> Waking up from Clock Mode to Score Mode!");
    currentMode = MODE_SCOREBOARD;
    lastActivityTime = now;
    scoreNeedsUpdate = true;
    return; // Do not add a point on wake-up click, preserve the score as it was before!
  }

  lastActivityTime = now;

  // Double Click Detection (within 380ms) -> UNDO
  if (pendingSingleClick && (now - lastPressTime < 380)) {
    pendingSingleClick = false;
    triggerUndoAction = true;
  } else {
    lastPressedButton = btn;
    lastPressTime = now;
    pendingSingleClick = true;
  }
}

// ==============================================================================
// BLE HID Client Implementation
// ==============================================================================
void onHIDNotification(NimBLERemoteCharacteristic* pChar, uint8_t* pData, size_t length, bool isNotify) {
  if (length == 0 || pData == nullptr) return;

  Serial.printf("[HID] Raw (%d bytes): ", length);
  for (size_t i = 0; i < length; i++) Serial.printf("0x%02X ", pData[i]);
  Serial.println();

  // Xiaomi XYLY01 remote report bytes
  if (pData[0] & 0x40) {
    Serial.println("[HID] -> Big Button (Team 1)");
    handleButtonPress(BUTTON_BIG);
    return;
  }
  if (pData[0] & 0x80) {
    Serial.println("[HID] -> Small Button (Team 2)");
    handleButtonPress(BUTTON_SMALL);
    return;
  }

  // Consumer Control report (Volume Up/Down, Shutter)
  if (pData[0] == 0x01 || pData[0] == 0xE9) {
    Serial.println("[HID] -> Button 1 (Shutter/VolUp -> Team 1)");
    handleButtonPress(BUTTON_BIG);
    return;
  }
  if (pData[0] == 0x02 || pData[0] == 0xEA) {
    Serial.println("[HID] -> Button 2 (VolDown -> Team 2)");
    handleButtonPress(BUTTON_SMALL);
    return;
  }

  // Standard keyboard report (Enter / Space)
  if (length >= 3 && pData[2] != 0) {
    uint8_t key = pData[2];
    Serial.printf("[HID] -> Keyboard Key: 0x%02X\n", key);
    if (key == 0x28 || key == 0x80) {
      handleButtonPress(BUTTON_BIG);
    } else {
      handleButtonPress(BUTTON_SMALL);
    }
  }
}

class AdvertisedDeviceCallbacks : public NimBLEAdvertisedDeviceCallbacks {
  void onResult(NimBLEAdvertisedDevice* advertisedDevice) override {
    std::string devName = advertisedDevice->haveName() ? advertisedDevice->getName() : "";
    std::string devAddr = advertisedDevice->getAddress().toString();
    int rssi = advertisedDevice->getRSSI();

    Serial.printf("[SCAN] %s | RSSI: %d | '%s'\n", devAddr.c_str(), rssi, devName.c_str());

    bool isMatch = false;

    // 0. Persistent pairing: instant MAC match if this remote was previously paired
    if (savedRemoteMac.length() > 0 && devAddr == savedRemoteMac.c_str()) {
      Serial.printf("[SCAN] ★ RECOGNIZED PAIRED REMOTE (%s)! Stopping scan to connect...\n", devAddr.c_str());
      isMatch = true;
    }

    // 1. Name match (case-insensitive)
    if (!isMatch && !devName.empty()) {
      std::string lower = devName;
      for (auto &c : lower) c = tolower(c);
      if (lower.find("xiaoyi") != std::string::npos ||
          lower.find("xyly") != std::string::npos ||
          lower.find("shutter") != std::string::npos ||
          lower.find("remote") != std::string::npos ||
          lower.find("selfie") != std::string::npos ||
          lower.find("clicker") != std::string::npos ||
          lower.find("button") != std::string::npos ||
          lower.find("rc") != std::string::npos) {
        isMatch = true;
      }
    }

    // 2. HID Service UUID match (0x1812)
    if (!isMatch && advertisedDevice->haveServiceUUID()) {
      if (advertisedDevice->isAdvertisingService(NimBLEUUID((uint16_t)0x1812))) {
        isMatch = true;
      }
    }

    // 3. HID Appearance match (0x03C0..0x03C4)
    if (!isMatch && advertisedDevice->haveAppearance()) {
      uint16_t app = advertisedDevice->getAppearance();
      if (app >= 0x03C0 && app <= 0x03C4) {
        isMatch = true;
      }
    }

    if (isMatch) {
      Serial.printf("[SCAN] ★ TARGET LOCATED: '%s' (%s)! Stopping scan to connect...\n",
                    devName.c_str(), devAddr.c_str());
      NimBLEDevice::getScan()->stop();
      targetAddress = advertisedDevice->getAddress();
      hasTarget = true;
      doConnect = true;
    }
  }
};

class ClientCallbacks : public NimBLEClientCallbacks {
  void onConnect(NimBLEClient* pClient) override {
    Serial.println("[BLE] Successfully connected to remote!");
    connected = true;
    setStatusLed(0, 50, 0); // Green
  }

  void onDisconnect(NimBLEClient* pClient) override {
    Serial.println("[BLE] Remote disconnected. Cleaning up client and resuming scan...");
    connected = false;
    hasTarget = false;
    setStatusLed(50, 0, 0); // Red
    NimBLEDevice::deleteClient(pClient);
    doScan = true;
  }
};

bool connectToRemote() {
  Serial.printf("[BLE] Connecting to %s...\n", targetAddress.toString().c_str());
  setStatusLed(50, 25, 0); // Orange

  NimBLEClient* pClient = nullptr;
  if (NimBLEDevice::getClientListSize() > 0) {
    pClient = NimBLEDevice::getClientByPeerAddress(targetAddress);
  }
  if (!pClient) {
    pClient = NimBLEDevice::createClient();
    pClient->setClientCallbacks(new ClientCallbacks(), false);
  }

  pClient->setConnectionParams(12, 24, 0, 400); // Low latency
  if (!pClient->connect(targetAddress)) {
    Serial.println("[BLE] Connection failed. Deleting client instance...");
    NimBLEDevice::deleteClient(pClient);
    return false;
  }

  // Ensure services are discovered before querying HID service
  auto* services = pClient->getServices(true);
  NimBLERemoteService* pHidService = pClient->getService(NimBLEUUID((uint16_t)0x1812));
  if (!pHidService) {
    Serial.println("[BLE] No 0x1812 HID service found, listing services:");
    if (services) {
      for (auto* s : *services) {
        Serial.printf("[BLE] Service: %s\n", s->getUUID().toString().c_str());
      }
    }
    pClient->disconnect();
    NimBLEDevice::deleteClient(pClient);
    return false;
  }

  std::vector<NimBLERemoteCharacteristic*>* chars = pHidService->getCharacteristics(true);
  int subCount = 0;
  if (chars) {
    for (auto* pChar : *chars) {
      if (pChar->canNotify()) {
        pChar->subscribe(true, onHIDNotification, true);
        Serial.printf("[BLE] Subscribed to %s (Notify)\n", pChar->getUUID().toString().c_str());
        subCount++;
      } else if (pChar->canIndicate()) {
        pChar->subscribe(false, onHIDNotification, true);
        Serial.printf("[BLE] Subscribed to %s (Indicate)\n", pChar->getUUID().toString().c_str());
        subCount++;
      }
    }
  }

  if (subCount > 0) {
    Serial.printf("[BLE] Remote ready with %d subscribed characteristic(s)!\n", subCount);

    // Persist this working remote's MAC address
    prefs.putString("remote_mac", targetAddress.toString().c_str());
    savedRemoteMac = targetAddress.toString().c_str();

    splashText("CONN", pixels.Color(0, 255, 0));
    delay(600);
    renderPadelScoreboard();
    return true;
  }

  Serial.println("[BLE] No subscribable characteristics found");
  pClient->disconnect();
  NimBLEDevice::deleteClient(pClient);
  return false;
}

// ==============================================================================
// Arduino Setup & Main Loop
// ==============================================================================
void setup() {
  Serial.begin(115200);
  delay(500);

  Serial.println("\n=======================================================");
  Serial.println("   ESP32 Padel Scoreboard - Sets & Match + Clock Edition ");
  Serial.println("   Simultaneous: Remote + Watch + Clock + 24-LED Indicator");
  Serial.println("   136 LEDs: 4x Digits (28ea) + Games/Sets Mod (24)     ");
  Serial.println("=======================================================");

#if defined(CONFIG_IDF_TARGET_ESP32C3)
  pinMode(ONBOARD_LED_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  gpio_set_drive_capability((gpio_num_t)LED_PIN, GPIO_DRIVE_CAP_3);
#endif

  pixels.begin();
  pixels.setBrightness(BRIGHTNESS);
  pixels.clear();

#if !defined(CONFIG_IDF_TARGET_ESP32C3)
  onboardLed.begin();
  onboardLed.setBrightness(50);
#endif
  setStatusLed(0, 0, 50); // Blue: Booting & scanning

  // 1. Initialize BLE Stack as "Padel Display"
  Serial.println("[BLE] Initializing NimBLE stack as 'Padel Display'...");
  NimBLEDevice::init("Padel Display");
  NimBLEDevice::setSecurityAuth(true, true, true);
  NimBLEDevice::setSecurityIOCap(BLE_HS_IO_NO_INPUT_OUTPUT);
  NimBLEDevice::setPower(ESP_PWR_LVL_P9);
  bleInitialized = true;

  // 2. Initialize BLE GATT Server (Watch App Service + FOTA OTA Service)
  NimBLEServer* pServer = NimBLEDevice::createServer();
  pServer->setCallbacks(new WatchServerCallbacks());

  // Create Watch Padel Score Service
  NimBLEService* pWatchService = pServer->createService(WATCH_SERVICE_UUID);
  pWatchCharacteristic = pWatchService->createCharacteristic(
      WATCH_CHARACTERISTIC_UUID,
      NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_NR | NIMBLE_PROPERTY::NOTIFY
  );
  pWatchCharacteristic->setCallbacks(new WatchCharCallbacks());
  pWatchCharacteristic->setValue(" 0 0,0,0,0,0,0");
  pWatchService->start();

  // Create BLE FOTA Server on same server
  BleFota::init(pServer, "Padel Display");
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
  pAdvertising->setName("Padel Display");
  pAdvertising->addServiceUUID(WATCH_SERVICE_UUID);
  pAdvertising->addServiceUUID(BLE_FOTA_SERVICE_UUID);
  pAdvertising->setMinInterval(160); // 100ms
  pAdvertising->setMaxInterval(320); // 200ms
  pAdvertising->start();

  // Initialize Preferences to remember paired remote
  prefs.begin("padel_remote", false);
  savedRemoteMac = prefs.getString("remote_mac", "");
  if (savedRemoteMac.length() > 0) {
    Serial.printf("[BLE] Stored paired remote MAC from previous session: %s\n", savedRemoteMac.c_str());
  }

  // Load Match Rules & Display Configuration from Flash NVS
  Preferences cfgPrefs;
  cfgPrefs.begin("padel_cfg", false);
  cfgGoldenPoint   = cfgPrefs.getBool("golden_point", false);
  cfgGamesPerSet   = cfgPrefs.getInt("games_per_set", 6);
  cfgSetsToWin     = cfgPrefs.getInt("sets_to_win", 2);
  cfgTiebreak      = cfgPrefs.getBool("tiebreak", true);
  cfgBrightness    = cfgPrefs.getUChar("brightness", 180);
  cfgIdleTimeoutMs = cfgPrefs.getULong("idle_timeout", 5 * 60 * 1000);
  cfgClockR        = cfgPrefs.getUChar("clock_r", 0);
  cfgClockG        = cfgPrefs.getUChar("clock_g", 180);
  cfgClockB        = cfgPrefs.getUChar("clock_b", 0);
  cfgPrefs.end();
  cfgClockColor    = pixels.Color(cfgClockR, cfgClockG, cfgClockB);
  pixels.setBrightness(cfgBrightness);
  Serial.printf("[CONFIG] Flash Rules: GP=%d, Sets=%d, Games=%d, TB=%d, Brightness=%d, Idle=%lu ms, ClockColor=#%02X%02X%02X\n",
                cfgGoldenPoint, cfgSetsToWin, cfgGamesPerSet, cfgTiebreak, cfgBrightness, (unsigned long)cfgIdleTimeoutMs,
                cfgClockR, cfgClockG, cfgClockB);

  NimBLEScan* pScan = NimBLEDevice::getScan();
  pScan->setAdvertisedDeviceCallbacks(new AdvertisedDeviceCallbacks(), false);
  pScan->setInterval(80); // Fast 50ms scan interval
  pScan->setWindow(76);   // 95% duty cycle: catches fast button advertising bursts
  pScan->setActiveScan(true);
  pScan->setDuplicateFilter(false); // CRITICAL: NEVER discard duplicate adverts so missed packets can retry!

  // Initialize Hardware RTC & Software Fallback Clock
  initClockRtc();

  // Brief startup splash (safe now that BLE stack is initialized)
  splashText("CLOC", pixels.Color(0, 180, 255));
  delay(500);

  currentCourtSwapped = isCourtSwapped();
  currentMode = MODE_CLOCK; // Panel starts in Clock Mode!
  lastActivityTime = millis();
  renderClock();
}

void loop() {
  if (BleFota::isUpdating()) {
    delay(100);
    return;
  }

  updateClockTime();

  // Check Inactivity Idle Timer:
  // If in Scoreboard Mode and inactivity timer expired, return to Clock Mode!
  if (currentMode == MODE_SCOREBOARD && cfgIdleTimeoutMs > 0) {
    if (millis() - lastActivityTime >= cfgIdleTimeoutMs) {
      Serial.println("[MODE] Inactivity timeout -> Automatically switching to Clock Mode");
      currentMode = MODE_CLOCK;
    }
  }

  // If in Clock Mode, render clock display and blinking colon
  if (currentMode == MODE_CLOCK) {
    static uint32_t lastClockRender = 0;
    if (millis() - lastClockRender >= 80) { // 80ms refresh for smooth 500ms colon blink
      lastClockRender = millis();
      renderClock();
    }
  }

  if (doConnect && hasTarget) {
    doConnect = false;
    if (!connectToRemote()) {
      Serial.println("[BLE] Retrying scan in 300ms...");
      hasTarget = false;
      delay(300);
      doScan = true;
    }
  }

  if (doScan && !connected) {
    doScan = false;
    hasTarget = false;
    setStatusLed(0, 0, 50); // Blue: Scanning
    Serial.println("[BLE] Starting background scan for remote...");
    NimBLEScan* pScan = NimBLEDevice::getScan();
    pScan->clearResults();
    pScan->start(0, nullptr, false);
  }

  // Gentle onboard LED blink while awaiting Bluetooth connection
  static uint32_t lastScanBlink = 0;
  static bool scanBlinkState = false;
  if (!connected && millis() - lastScanBlink > 500) {
    lastScanBlink = millis();
    scanBlinkState = !scanBlinkState;
#if defined(CONFIG_IDF_TARGET_ESP32C3)
    digitalWrite(ONBOARD_LED_PIN, scanBlinkState ? LOW : HIGH);
#else
    onboardLed.setPixelColor(0, scanBlinkState ? onboardLed.Color(0, 0, 40) : 0);
    onboardLed.show();
#endif
  }

  // Handle single-click expiration (380ms timeout)
  if (pendingSingleClick && (millis() - lastPressTime >= 380)) {
    pendingSingleClick = false;

    const char* pointNames[] = { " 0", "15", "30", "40", "Ad" };
    if (lastPressedButton == BUTTON_BIG) {
      addPadelPoint(1);
      Serial.printf("[BUTTON] Big Button -> Team 1 Point! Score: %s - %s (Games: %d-%d | Sets: %d-%d)\n",
                    pointNames[team1Point], pointNames[team2Point], team1Games, team2Games, team1Sets, team2Sets);
      bool newSwapped = isCourtSwapped();
      if (newSwapped != currentCourtSwapped && !triggerGameWonAnimation && !triggerSetWonAnimation && !triggerMatchWonAnimation) {
        animateCourtSideSwap(newSwapped);
        currentCourtSwapped = newSwapped;
      }
      lastActivityTime = millis();
      scoreNeedsUpdate = true;
    } else if (lastPressedButton == BUTTON_SMALL) {
      addPadelPoint(2);
      Serial.printf("[BUTTON] Small Button -> Team 2 Point! Score: %s - %s (Games: %d-%d | Sets: %d-%d)\n",
                    pointNames[team1Point], pointNames[team2Point], team1Games, team2Games, team1Sets, team2Sets);
      bool newSwapped = isCourtSwapped();
      if (newSwapped != currentCourtSwapped && !triggerGameWonAnimation && !triggerSetWonAnimation && !triggerMatchWonAnimation) {
        animateCourtSideSwap(newSwapped);
        currentCourtSwapped = newSwapped;
      }
      lastActivityTime = millis();
      scoreNeedsUpdate = true;
    }
  }

  // Handle Double-click UNDO
  if (triggerUndoAction) {
    triggerUndoAction = false;
    lastActivityTime = millis();
    if (undoScoreState()) {
      const char* pointNames[] = { " 0", "15", "30", "40", "Ad" };
      Serial.printf("[BUTTON] Double Click -> UNDO! Restored: %s - %s (Games: %d-%d | Sets: %d-%d)\n",
                    pointNames[team1Point], pointNames[team2Point], team1Games, team2Games, team1Sets, team2Sets);
      // Quick flash off of the Games/Sets module to confirm undo action
      drawGamesAndSets(0, 0, 0, 0);
      showPixelsSafe();
      delay(80);

      bool newSwapped = isCourtSwapped();
      if (newSwapped != currentCourtSwapped) {
        Serial.printf("[PADEL] Court side switch on Undo! (%s -> %s)\n",
                      currentCourtSwapped ? "Swapped" : "Normal",
                      newSwapped ? "Swapped" : "Normal");
        animateCourtSideSwap(newSwapped);
        currentCourtSwapped = newSwapped;
      }

      notifyWatchScore();
      scoreNeedsUpdate = true;
    } else {
      Serial.println("[BUTTON] Undo pressed, but no history available");
    }
  }

  // 1. Handle Game Won Animation (3 flashes of the winning team's side)
  if (triggerGameWonAnimation) {
    triggerGameWonAnimation = false;
    lastActivityTime = millis();
    uint32_t winColor = (winningTeam == 1) ? pixels.Color(0, 180, 255) : pixels.Color(255, 0, 0);
    Serial.printf("[PADEL] ★ GAME WON by Team %d! Current Games: %d - %d (Sets: %d - %d)\n",
                  winningTeam, team1Games, team2Games, team1Sets, team2Sets);

    int gamesVal = (winningTeam == 1) ? team1Games : team2Games;
    // Determine which side winning team was located on before this transition:
    bool flashLeftSide = (!currentCourtSwapped && winningTeam == 1) || (currentCourtSwapped && winningTeam == 2);

    for (int f = 0; f < 3; f++) {
      pixels.clear();
      // Light up winning team digits and games
      if (flashLeftSide) {
        drawDigit(0, 10, winColor);
        drawDigit(1, gamesVal % 10, winColor);
      } else {
        drawDigit(2, 10, winColor);
        drawDigit(3, gamesVal % 10, winColor);
      }
      drawGamesAndSets(currentCourtSwapped, 1.0f);
      showPixelsSafe();
      delay(200);

      pixels.clear();
      drawGamesAndSets(currentCourtSwapped, 1.0f);
      showPixelsSafe();
      delay(150);
    }

    // Check if court side switch occurs on uneven game sum:
    bool newSwapped = isCourtSwapped();
    if (newSwapped != currentCourtSwapped) {
      Serial.printf("[PADEL] Court side switch! Games: %d-%d (Sum=%d uneven). Transitioning (%s -> %s)...\n",
                    team1Games, team2Games, team1Games + team2Games,
                    currentCourtSwapped ? "Swapped" : "Normal",
                    newSwapped ? "Swapped" : "Normal");
      animateCourtSideSwap(newSwapped);
      currentCourtSwapped = newSwapped;
    }

    notifyWatchScore();
    scoreNeedsUpdate = true;
  }

  // 2. Handle Set Won Animation (Celebratory flash of won set)
  if (triggerSetWonAnimation) {
    triggerSetWonAnimation = false;
    lastActivityTime = millis();
    uint32_t setWinColor = (winningTeam == 1) ? pixels.Color(0, 180, 255) : pixels.Color(255, 0, 0);
    Serial.printf("[PADEL] ★★★ SET WON by Team %d! Sets: %d - %d\n", winningTeam, team1Sets, team2Sets);

    bool flashLeftSide = (!currentCourtSwapped && winningTeam == 1) || (currentCourtSwapped && winningTeam == 2);

    for (int f = 0; f < 4; f++) {
      pixels.clear();
      if (flashLeftSide) {
        drawDigit(0, 13, setWinColor); // 'S'
        drawDigit(1, (winningTeam == 1 ? team1Sets : team2Sets) % 10, setWinColor);
        drawDigit(2, 10, setWinColor); // Blank
        drawDigit(3, 10, setWinColor); // Blank
      } else {
        drawDigit(0, 10, setWinColor); // Blank
        drawDigit(1, 10, setWinColor); // Blank
        drawDigit(2, 13, setWinColor); // 'S'
        drawDigit(3, (winningTeam == 1 ? team1Sets : team2Sets) % 10, setWinColor);
      }
      drawGamesAndSets(currentCourtSwapped, 1.0f);
      showPixelsSafe();
      delay(250);

      pixels.clear();
      drawGamesAndSets(currentCourtSwapped, 1.0f);
      showPixelsSafe();
      delay(150);
    }

    bool newSwapped = isCourtSwapped();
    if (newSwapped != currentCourtSwapped) {
      animateCourtSideSwap(newSwapped);
      currentCourtSwapped = newSwapped;
    }

    notifyWatchScore();
    scoreNeedsUpdate = true;
  }

  // 3. Handle Match Won Animation (Display "SPEL" in winning team's color for 30 seconds, then set scores)
  if (triggerMatchWonAnimation) {
    triggerMatchWonAnimation = false;
    lastActivityTime = millis();
    matchWonPhase = MATCH_PHASE_SPEL;
    matchWonStartTime = millis();
    uint32_t champColor = (winningTeam == 1) ? pixels.Color(0, 180, 255) : pixels.Color(255, 0, 0);
    Serial.printf("[PADEL] 🏆🏆🏆 MATCH WON by Team %d! Final Sets: %d - %d\n",
                  winningTeam, team1Sets, team2Sets);
    Serial.printf("[PADEL] Final Set 1: %d-%d | Set 2: %d-%d (Total Sets: %d)\n",
                  set1Games1, set1Games2, set2Games1, set2Games2, totalSetsPlayed);

    // Initial celebratory greeting (3 pulses of SPEL)
    for (int cycle = 0; cycle < 3; cycle++) {
      splashText("SPEL", champColor);
      delay(220);
      pixels.clear();
      showPixelsSafe();
      delay(120);
    }
    // Hold SPEL solid on screen
    splashText("SPEL", champColor);

    notifyWatchScore();
    scoreNeedsUpdate = false;
  }

  // Manage Match Won State Machine (SPEL for 30s -> then set games on display)
  if (matchWon) {
    if (matchWonPhase == MATCH_PHASE_SPEL) {
      if (millis() - matchWonStartTime >= 30000) { // 30 seconds of SPEL
        Serial.println("[PADEL] 30 seconds SPEL finished -> Showing set scores on display!");
        matchWonPhase = MATCH_PHASE_SET_SCORES;
        renderMatchSetScores();
      }
    } else if (matchWonPhase == MATCH_PHASE_SET_SCORES) {
      // If 3 sets played, periodically alternate between sets every 4s
      if (totalSetsPlayed >= 3) {
        static uint32_t lastSetCycle = 0;
        if (millis() - lastSetCycle >= 4000) {
          lastSetCycle = millis();
          renderMatchSetScores();
        }
      }
    }
  }

  if (scoreNeedsUpdate && currentMode == MODE_SCOREBOARD) {
    scoreNeedsUpdate = false;
    renderPadelScoreboard();
  }

  delay(20);
}
