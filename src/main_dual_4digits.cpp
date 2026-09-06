// ==============================================================================
// ESP32 Padel Scoreboard - Dual Control Edition (Watch App + Xiaomi Remote)
// Version: Direct 4-Digit Edition (Only the 4 7-segment panels, no colon or games/sets)
//
// Dual-Role BLE Architecture:
//   1. BLE Central (Client): Actively connects to Xiaomi / YI Bluetooth Remote (XYLY01)
//      - Big Button (0x40): Point for Team 1
//      - Small Button (0x80): Point for Team 2
//      - Double Click (<380ms): UNDO previous point / game
//   2. BLE Peripheral (Server): Advertises as "Padel Display" for Watch App (Garmin/WearOS/Apple)
//      - Service UUID: 4fafc201-1fb5-459e-8fcc-c5c9c331914b
//      - Characteristic UUID: beb5483e-36e1-4688-b7f5-ea07361b26a8
//      - Watch can read/write "SCORE,SWITCH" (e.g. "1530,0", " 0 0,1")
//      - Remote button presses automatically notify the watch in real time!
//   3. BLE FOTA Server: Allows wireless Web Bluetooth firmware updates (ota.html)
//
// Physical LED Chain & Wiring Order (136 LEDs Total):
//   1. Digit 0 (Team 1 Tens):            28 LEDs (0..27)
//   2. Digit 1 (Team 1 Ones):            28 LEDs (28..55)
//   3. Games & Sets Indicator Module:    24 LEDs (56..79)
//      - Left Column (Team on Left, Bottom to Top):
//        * LEDs 56..64 (Indices 0..8):   Games G1..G9 (bottom to top)
//        * LED 65      (Index 9):        Blank Spacer Gap (Always OFF)
//        * LEDs 66..67 (Indices 10..11): Sets S1, S2 (bottom to top)
//      - Right Column (Team on Right, Top to Bottom):
//        * LEDs 68..69 (Indices 12..13): Sets S2=top, S1=lower
//        * LED 70      (Index 14):       Blank Spacer Gap (Always OFF)
//        * LEDs 71..79 (Indices 15..23): Games G9=top down to G1=bottom
//   4. Digit 2 (Team 2 Tens):            28 LEDs (80..107)
//   5. Digit 3 (Team 2 Ones):            28 LEDs (108..135)
// ==============================================================================

#include <Arduino.h>
#include <Adafruit_NeoPixel.h>
#include <NimBLEDevice.h>
#include <Preferences.h>
#include "ble_fota.h"
#include <vector>
#if defined(ESP32)
  #include "driver/gpio.h"
#endif

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
#define GAMES_SETS_LEDS   24     // 2 columns * 12 LEDs for Games & Sets Module
#define NUMPIXELS         (NUM_DIGITS * LEDS_PER_DIGIT + GAMES_SETS_LEDS) // 136 LEDs total
#define BRIGHTNESS        180    // LED brightness (0 - 255)

// Team Color Definitions:
// Team 1: Red (Big Button / Top on Watch / Left on Board)
// Team 2: Blue (Small Button / Bottom on Watch / Right on Board)
#define COLOR_TEAM1_RED   pixels.Color(255, 0, 0)
#define COLOR_TEAM2_BLUE  pixels.Color(0, 80, 255)

// ==============================================================================
// Watch App BLE Service & Characteristic UUIDs
// ==============================================================================
#define WATCH_SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define WATCH_CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// Forward declaration
static NimBLECharacteristic* pWatchCharacteristic = nullptr;
void notifyWatchScore();

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
  bool courtSwapped;
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

// Court side tracking:
// In padel/tennis, teams switch ends only when the game count becomes uneven (after game 1, 3, 5, 7, 9...).
// On even game sums (1-1, 4-0, 2-2, etc.), teams stay on their current side (nothing changes).
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
  int totalGames = team1Games + team2Games;
  return ((totalGames + 1) / 2) % 2 == 1;
}

bool triggerGameWonAnimation  = false;
bool triggerSetWonAnimation   = false;
bool triggerMatchWonAnimation = false;
int winningTeam = 0;
bool triggerUndoAction = false;
bool scoreNeedsUpdate = true;

// Remote interaction tracking
enum RemoteButton { BUTTON_NONE, BUTTON_BIG, BUTTON_SMALL };
volatile RemoteButton lastPressedButton = BUTTON_NONE;
volatile uint32_t lastPressTime = 0;
volatile bool pendingSingleClick = false;

// BLE Central State & Persistent Pairing (Xiaomi Remote)
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

inline int getDigitBaseLed(int digitIndex) {
  if (digitIndex < 2) {
    return digitIndex * LEDS_PER_DIGIT;
  } else {
    return (digitIndex * LEDS_PER_DIGIT) + GAMES_SETS_LEDS;
  }
}

inline int getGamesSetsBaseLed() {
  return 2 * LEDS_PER_DIGIT; // Index 56 (LEDs 56..79)
}

// 7-Segment Hardware Remapping (Panel 1 Custom Wiring)
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

inline uint32_t scaleColor(uint32_t color, float factor) {
  if (factor <= 0.0f) return 0;
  if (factor >= 1.0f) return color;
  uint8_t r = (uint8_t)(((color >> 16) & 0xFF) * factor);
  uint8_t g = (uint8_t)(((color >> 8) & 0xFF) * factor);
  uint8_t b = (uint8_t)((color & 0xFF) * factor);
  return pixels.Color(r, g, b);
}

void getTeamDigits(int team, int &tens, int &ones) {
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
// Module is wired between Digit 1 (end at LED 55) and Digit 2 (start at LED 80)
//   - Left Column (Team on Left, Bottom to Top):
//     * LEDs 56..64 (Indices 0..8):   Games 1..9 (bottom to top)
//     * LED 65      (Index 9):        Blank Spacer Gap (Always OFF)
//     * LEDs 66..67 (Indices 10..11): Sets 1, 2 (bottom to top)
//   - Right Column (Team on Right, Top to Bottom):
//     * LEDs 68..69 (Indices 12..13): Sets 2 (top), 1 (lower)
//     * LED 70      (Index 14):       Blank Spacer Gap (Always OFF)
//     * LEDs 71..79 (Indices 15..23): Games 9 (top) down to 1 (bottom)
// ==============================================================================
void drawGamesAndSets(bool swapped, float brightnessFactor) {
  if (brightnessFactor <= 0.001f) return;
  int base = getGamesSetsBaseLed(); // LED index 56

  int leftGames   = !swapped ? team1Games : team2Games;
  int leftSets    = !swapped ? team1Sets  : team2Sets;
  uint32_t leftGameColor = scaleColor(!swapped ? COLOR_TEAM1_RED : COLOR_TEAM2_BLUE, brightnessFactor);
  uint32_t leftSetColor  = scaleColor(pixels.Color(255, 200, 0), brightnessFactor);

  int rightGames  = !swapped ? team2Games : team1Games;
  int rightSets   = !swapped ? team2Sets  : team1Sets;
  uint32_t rightGameColor = scaleColor(!swapped ? COLOR_TEAM2_BLUE : COLOR_TEAM1_RED, brightnessFactor);
  uint32_t rightSetColor  = scaleColor(pixels.Color(255, 200, 0), brightnessFactor);

  // 1. Left Column Games (base + 0..8: G1..G9 bottom to top)
  for (int g = 0; g < 9; g++) {
    pixels.setPixelColor(base + g, (g < leftGames) ? leftGameColor : 0);
  }

  // 2. Left Column Spacer Gap (base + 9): Always OFF
  pixels.setPixelColor(base + 9, 0);

  // 3. Left Column Sets (base + 10..11: S1, S2 bottom to top)
  pixels.setPixelColor(base + 10, (leftSets >= 1) ? leftSetColor : 0);
  pixels.setPixelColor(base + 11, (leftSets >= 2) ? leftSetColor : 0);

  // 4. Right Column Sets (base + 12..13: S2 top, S1 lower)
  pixels.setPixelColor(base + 13, (rightSets >= 1) ? rightSetColor : 0);
  pixels.setPixelColor(base + 12, (rightSets >= 2) ? rightSetColor : 0);

  // 5. Right Column Spacer Gap (base + 14): Always OFF
  pixels.setPixelColor(base + 14, 0);

  // 6. Right Column Games (base + 15..23: G9 down to G1)
  for (int g = 0; g < 9; g++) {
    int ledIdx = base + 23 - g;
    pixels.setPixelColor(ledIdx, (g < rightGames) ? rightGameColor : 0);
  }
}

void renderBoardWithState(bool swapped, float brightnessFactor) {
  pixels.clear();
  if (brightnessFactor <= 0.001f) {
    showPixelsSafe();
    return;
  }

  uint32_t colorRed  = scaleColor(COLOR_TEAM1_RED,  brightnessFactor);
  uint32_t colorBlue = scaleColor(COLOR_TEAM2_BLUE, brightnessFactor);

  int t1Tens, t1Ones, t2Tens, t2Ones;
  getTeamDigits(1, t1Tens, t1Ones);
  getTeamDigits(2, t2Tens, t2Ones);

  if (!swapped) {
    // Normal: Team 1 (Red) on Left (0, 1), Team 2 (Blue) on Right (2, 3)
    drawDigit(0, t1Tens, colorRed);
    drawDigit(1, t1Ones, colorRed);
    drawDigit(2, t2Tens, colorBlue);
    drawDigit(3, t2Ones, colorBlue);
  } else {
    // Swapped: Team 2 (Blue) on Left (0, 1), Team 1 (Red) on Right (2, 3)
    drawDigit(0, t2Tens, colorBlue);
    drawDigit(1, t2Ones, colorBlue);
    drawDigit(2, t1Tens, colorRed);
    drawDigit(3, t1Ones, colorRed);
  }

  // Draw Games & Sets module in the middle (LEDs 56..79)
  drawGamesAndSets(swapped, brightnessFactor);

  showPixelsSafe();
}

void animateCourtSideSwap(bool toSwapped) {
  bool fromSwapped = !toSwapped;
  uint32_t cRed     = COLOR_TEAM1_RED;
  uint32_t cBlue    = COLOR_TEAM2_BLUE;
  uint32_t cRedDim  = pixels.Color(65, 0, 0);
  uint32_t cBlueDim = pixels.Color(0, 20, 65);
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

  // Phase 2: Orbital Crossover Flow across all 4 digits
  const int numFrames = 7;
  for (int frame = 0; frame < numFrames; frame++) {
    pixels.clear();

    if (toSwapped) {
      switch (frame) {
        case 0:
          drawSegment(0, 4, cRed);  // TL
          drawSegment(0, 5, cRed);  // T
          drawSegment(3, 2, cBlue); // BR
          drawSegment(3, 1, cBlue); // B
          break;
        case 1:
          drawSegment(0, 5, cRedDim);
          drawSegment(0, 6, cRed);  // TR
          drawSegment(1, 4, cRed);  // TL
          drawSegment(1, 5, cRed);  // T
          drawSegment(3, 1, cBlueDim);
          drawSegment(3, 0, cBlue); // BL
          drawSegment(2, 2, cBlue); // BR
          drawSegment(2, 1, cBlue); // B
          break;
        case 2:
          drawSegment(1, 5, cRed);  // T
          drawSegment(1, 6, cRed);  // TR
          drawSegment(1, 3, cRedDim); // M trail
          drawSegment(2, 1, cBlue); // B
          drawSegment(2, 0, cBlue); // BL
          drawSegment(2, 3, cBlueDim); // M trail
          break;
        case 3:
          drawSegment(1, 6, cRed);   // TR
          drawSegment(1, 3, cWhite); // Center net pulse
          drawSegment(2, 4, cRed);   // TL
          drawSegment(2, 0, cBlue);  // BL
          drawSegment(2, 3, cWhite); // Center net pulse
          drawSegment(1, 2, cBlue);  // BR
          break;
        case 4:
          drawSegment(2, 4, cRedDim);
          drawSegment(2, 5, cRed);  // T
          drawSegment(2, 6, cRed);  // TR
          drawSegment(2, 3, cRedDim);
          drawSegment(1, 2, cBlueDim);
          drawSegment(1, 1, cBlue); // B
          drawSegment(1, 0, cBlue); // BL
          drawSegment(1, 3, cBlueDim);
          break;
        case 5:
          drawSegment(2, 5, cRedDim);
          drawSegment(3, 4, cRed);  // TL
          drawSegment(3, 5, cRed);  // T
          drawSegment(3, 6, cRed);  // TR
          drawSegment(1, 1, cBlueDim);
          drawSegment(0, 2, cBlue); // BR
          drawSegment(0, 1, cBlue); // B
          drawSegment(0, 0, cBlue); // BL
          break;
        case 6:
          drawSegment(2, 5, cRed);
          drawSegment(2, 3, cRed);
          drawSegment(3, 5, cRed);
          drawSegment(3, 3, cRed);
          drawSegment(0, 1, cBlue);
          drawSegment(0, 3, cBlue);
          drawSegment(1, 1, cBlue);
          drawSegment(1, 3, cBlue);
          break;
      }
    } else {
      switch (frame) {
        case 0:
          drawSegment(3, 6, cRed);  // TR
          drawSegment(3, 5, cRed);  // T
          drawSegment(0, 0, cBlue); // BL
          drawSegment(0, 1, cBlue); // B
          break;
        case 1:
          drawSegment(3, 5, cRedDim);
          drawSegment(3, 4, cRed);  // TL
          drawSegment(2, 6, cRed);  // TR
          drawSegment(2, 5, cRed);  // T
          drawSegment(0, 1, cBlueDim);
          drawSegment(0, 2, cBlue); // BR
          drawSegment(1, 0, cBlue); // BL
          drawSegment(1, 1, cBlue); // B
          break;
        case 2:
          drawSegment(2, 5, cRed);  // T
          drawSegment(2, 4, cRed);  // TL
          drawSegment(2, 3, cRedDim); // M trail
          drawSegment(1, 1, cBlue); // B
          drawSegment(1, 2, cBlue); // BR
          drawSegment(1, 3, cBlueDim); // M trail
          break;
        case 3:
          drawSegment(2, 4, cRed);   // TL
          drawSegment(2, 3, cWhite); // Center net pulse
          drawSegment(1, 6, cRed);   // TR
          drawSegment(1, 2, cBlue);  // BR
          drawSegment(1, 3, cWhite); // Center net pulse
          drawSegment(2, 0, cBlue);  // BL
          break;
        case 4:
          drawSegment(1, 6, cRedDim);
          drawSegment(1, 5, cRed);  // T
          drawSegment(1, 4, cRed);  // TL
          drawSegment(1, 3, cRedDim);
          drawSegment(2, 0, cBlueDim);
          drawSegment(2, 1, cBlue); // B
          drawSegment(2, 2, cBlue); // BR
          drawSegment(2, 3, cBlueDim);
          break;
        case 5:
          drawSegment(1, 5, cRedDim);
          drawSegment(0, 6, cRed);  // TR
          drawSegment(0, 5, cRed);  // T
          drawSegment(0, 4, cRed);  // TL
          drawSegment(2, 1, cBlueDim);
          drawSegment(3, 0, cBlue); // BL
          drawSegment(3, 1, cBlue); // B
          drawSegment(3, 2, cBlue); // BR
          break;
        case 6:
          drawSegment(0, 5, cRed);
          drawSegment(0, 3, cRed);
          drawSegment(1, 5, cRed);
          drawSegment(1, 3, cRed);
          drawSegment(2, 1, cBlue);
          drawSegment(2, 3, cBlue);
          drawSegment(3, 1, cBlue);
          drawSegment(3, 3, cBlue);
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

void renderPadelScoreboard() {
  renderBoardWithState(currentCourtSwapped, 1.0f);
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
  int len = strlen(text);
  for (int i = 0; i < NUM_DIGITS; i++) {
    char c = (i < len) ? text[i] : ' ';
    drawChar(i, c, color);
  }
  showPixelsSafe();
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
    scoreHistory[historyCount].courtSwapped = currentCourtSwapped;
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
    scoreHistory[SCORE_HISTORY_DEPTH - 1].courtSwapped = currentCourtSwapped;
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
  return true;
}

void addPadelPoint(int team) {
  saveScoreState();

  // If match was already completed, the next button click starts a brand-new match!
  if (matchWon) {
    matchWon = false;
    team1Sets = 0;
    team2Sets = 0;
    team1Games = 0;
    team2Games = 0;
    team1Point = POINT_0;
    team2Point = POINT_0;
    currentCourtSwapped = false;
    saveScoreState();
  }

  bool gameWon = false;
  int gameWinner = 0;

  if (team == 1) {
    if (team1Point == POINT_40) {
      if (team2Point == POINT_40) {
        team1Point = POINT_AD; // 40-40 -> Ad-40
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
        team2Point = POINT_AD; // 40-40 -> 40-Ad
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

    // Check Set Won condition:
    // Padel: Win set at 6 games with >=2 lead, or tiebreak at 7 games
    bool setWon = false;
    if (gameWinner == 1) {
      if ((team1Games >= 6 && (team1Games - team2Games >= 2)) || team1Games >= 7) {
        setWon = true;
        team1Sets++;
      }
    } else {
      if ((team2Games >= 6 && (team2Games - team1Games >= 2)) || team2Games >= 7) {
        setWon = true;
        team2Sets++;
      }
    }

    if (setWon) {
      // Check Match Won condition (best of 3 sets: 2 sets won)
      if (team1Sets >= 2 || team2Sets >= 2) {
        matchWon = true;
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

  // Notify connected watch of new score
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
  formatPadelPoint(team1Point, t1T, t1O);
  formatPadelPoint(team2Point, t2T, t2O);
  char buf[32];
  if (!currentCourtSwapped) {
    snprintf(buf, sizeof(buf), "%c%c%c%c,0,%d,%d,%d,%d",
             t1T, t1O, t2T, t2O,
             team1Games, team2Games, team1Sets, team2Sets);
  } else {
    snprintf(buf, sizeof(buf), "%c%c%c%c,1,%d,%d,%d,%d",
             t2T, t2O, t1T, t1O,
             team2Games, team1Games, team2Sets, team1Sets);
  }
  pWatchCharacteristic->setValue((uint8_t*)buf, strlen(buf));
  pWatchCharacteristic->notify();
  Serial.printf("[BLE-WATCH] Notified watch: '%s'\n", buf);
}

// ==============================================================================
// BLE Server Callbacks (Watch App)
// ==============================================================================
class WatchServerCallbacks : public NimBLEServerCallbacks {
  void onConnect(NimBLEServer* pServer) override {
    Serial.println("[BLE-WATCH] Watch connected!");
    notifyWatchScore();
  }

  void onDisconnect(NimBLEServer* pServer) override {
    Serial.println("[BLE-WATCH] Watch disconnected. Restarting advertising...");
    NimBLEDevice::startAdvertising();
  }
};

class WatchCharCallbacks : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic* pCharacteristic) override {
    std::string val = pCharacteristic->getValue();
    if (val.empty()) return;
    Serial.printf("[BLE-WATCH] Received score payload: '%s'\n", val.c_str());

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
      // When watch is swapped, chars 0..1 are Team 2 and 2..3 are Team 1
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
// Button & Interaction Logic (Xiaomi Remote)
// ==============================================================================
void handleButtonPress(RemoteButton btn) {
  uint32_t now = millis();

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
// BLE HID Client Implementation (Xiaomi Remote)
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
    // Ensure peripheral advertising continues so watch can connect simultaneously
    NimBLEDevice::startAdvertising();
  }

  void onDisconnect(NimBLEClient* pClient) override {
    Serial.println("[BLE] Remote disconnected. Cleaning up client and resuming scan...");
    connected = false;
    hasTarget = false;
    setStatusLed(50, 0, 0); // Red
    NimBLEDevice::deleteClient(pClient);
    doScan = true;
    NimBLEDevice::startAdvertising();
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

  pClient->setConnectionParams(12, 12, 0, 150); // Fast 15ms interval
  pClient->setConnectTimeout(5);

  if (!pClient->connect(targetAddress, true)) {
    Serial.println("[BLE] Failed to connect. Returning to scan.");
    setStatusLed(50, 0, 0);
    return false;
  }

  // Save successful pairing MAC
  if (savedRemoteMac != targetAddress.toString().c_str()) {
    savedRemoteMac = targetAddress.toString().c_str();
    prefs.putString("remote_mac", savedRemoteMac);
    Serial.printf("[BLE] Persistently saved remote MAC: %s\n", savedRemoteMac.c_str());
  }

  Serial.println("[BLE] Discovering HID Service (0x1812)...");
  NimBLERemoteService* pHidService = pClient->getService(NimBLEUUID((uint16_t)0x1812));
  if (pHidService == nullptr) {
    Serial.println("[BLE] Failed to find HID service (0x1812)");
    pClient->disconnect();
    return false;
  }

  std::vector<NimBLERemoteCharacteristic*>* pChars = pHidService->getCharacteristics(true);
  if (pChars == nullptr || pChars->empty()) {
    Serial.println("[BLE] No characteristics found in HID service");
    pClient->disconnect();
    return false;
  }

  int subCount = 0;
  for (auto pChar : *pChars) {
    if (pChar->getUUID().equals(NimBLEUUID((uint16_t)0x2A4D))) { // Report characteristic
      if (pChar->canNotify()) {
        if (pChar->subscribe(true, onHIDNotification)) {
          Serial.printf("[BLE] Subscribed to HID Report char: %s (handle: 0x%04X)\n",
                        pChar->getUUID().toString().c_str(), pChar->getHandle());
          subCount++;
        }
      }
    }
  }

  if (subCount == 0) {
    for (auto pChar : *pChars) {
      if (pChar->canNotify()) {
        if (pChar->subscribe(true, onHIDNotification)) {
          Serial.printf("[BLE] Fallback subscribed to: %s\n", pChar->getUUID().toString().c_str());
          subCount++;
        }
      }
    }
  }

  return (subCount > 0);
}

// ==============================================================================
// Arduino Setup & Main Loop
// ==============================================================================
void setup() {
  Serial.begin(115200);
  delay(500);

  Serial.println("\n=======================================================");
  Serial.println(" ESP32 Padel Scoreboard - Dual Control Edition         ");
  Serial.println(" Simultaneous: Watch App (Server) + Xiaomi Remote (HID)");
  Serial.println(" 136 LEDs Total: 4 Digits + 24-LED Games & Sets Module ");
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

  // 1. Initialize BLE Stack with Dual-Role capabilities
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

  // Create BLE FOTA OTA Service on same server
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

  // 3. Start Advertising as "Padel Display" with Watch App Service UUID
  NimBLEAdvertising* pAdvertising = NimBLEDevice::getAdvertising();
  pAdvertising->setName("Padel Display");
  pAdvertising->addServiceUUID(WATCH_SERVICE_UUID);
  pAdvertising->start();
  Serial.println("[BLE] Advertising started as 'Padel Display' (Watch Service ready)!");

  // 4. Initialize Preferences for Xiaomi Remote persistent pairing
  prefs.begin("padel_remote", false);
  savedRemoteMac = prefs.getString("remote_mac", "");
  if (savedRemoteMac.length() > 0) {
    Serial.printf("[BLE] Stored paired remote MAC from previous session: %s\n", savedRemoteMac.c_str());
  }

  // 5. Start Background BLE Scanner for Xiaomi / YI Remote
  NimBLEScan* pScan = NimBLEDevice::getScan();
  pScan->setAdvertisedDeviceCallbacks(new AdvertisedDeviceCallbacks(), false);
  pScan->setInterval(100); // 62.5ms interval
  pScan->setWindow(50);    // 50% duty cycle: leaves 50% airtime for watch advertising!
  pScan->setActiveScan(true);
  pScan->setDuplicateFilter(false);

  // Brief startup splash
  splashText("DUAL", pixels.Color(0, 80, 255));
  delay(600);

  currentCourtSwapped = isCourtSwapped();
  renderPadelScoreboard();
}

void loop() {
  if (BleFota::isUpdating()) {
    delay(100);
    return;
  }

  // Handle connection trigger from scanner
  if (doConnect && hasTarget) {
    doConnect = false;
    if (!connectToRemote()) {
      Serial.println("[BLE] Retrying scan in 300ms...");
      hasTarget = false;
      delay(300);
      doScan = true;
    }
  }

  // Resume background scan if remote disconnected
  if (doScan && !connected) {
    doScan = false;
    hasTarget = false;
    setStatusLed(0, 0, 50); // Blue: Scanning
    Serial.println("[BLE] Starting background scan for remote...");
    NimBLEScan* pScan = NimBLEDevice::getScan();
    pScan->clearResults();
    pScan->start(0, nullptr, false);
  }

  // Gentle onboard LED blink while awaiting Bluetooth remote connection
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
      scoreNeedsUpdate = true;
    } else if (lastPressedButton == BUTTON_SMALL) {
      addPadelPoint(2);
      Serial.printf("[BUTTON] Small Button -> Team 2 Point! Score: %s - %s (Games: %d-%d | Sets: %d-%d)\n",
                    pointNames[team1Point], pointNames[team2Point], team1Games, team2Games, team1Sets, team2Sets);
      scoreNeedsUpdate = true;
    }
  }

  // Handle Double-click UNDO
  if (triggerUndoAction) {
    triggerUndoAction = false;
    if (undoScoreState()) {
      const char* pointNames[] = { " 0", "15", "30", "40", "Ad" };
      Serial.printf("[BUTTON] Double Click -> UNDO! Restored: %s - %s (Games: %d-%d | Sets: %d-%d)\n",
                    pointNames[team1Point], pointNames[team2Point], team1Games, team2Games, team1Sets, team2Sets);

      // Quick flash off of the Games/Sets module to visually confirm undo action
      pixels.clear();
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
    uint32_t winColor = (winningTeam == 1) ? COLOR_TEAM1_RED : COLOR_TEAM2_BLUE;
    Serial.printf("[PADEL] ★ GAME WON by Team %d! Current Games: %d - %d (Sets: %d - %d)\n",
                  winningTeam, team1Games, team2Games, team1Sets, team2Sets);

    int gamesVal = (winningTeam == 1) ? team1Games : team2Games;
    bool flashLeftSide = (!currentCourtSwapped && winningTeam == 1) || (currentCourtSwapped && winningTeam == 2);

    for (int f = 0; f < 3; f++) {
      pixels.clear();
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
    uint32_t goldColor = pixels.Color(255, 200, 0);
    Serial.printf("[PADEL] ★★★ SET WON by Team %d! Sets: %d - %d\n", winningTeam, team1Sets, team2Sets);

    for (int f = 0; f < 4; f++) {
      pixels.clear();
      drawDigit(0, 13, goldColor); // 'S'
      drawDigit(1, (winningTeam == 1 ? team1Sets : team2Sets) % 10, goldColor);
      drawDigit(2, 10, goldColor);
      drawDigit(3, 10, goldColor);
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

  // 3. Handle Match Won Animation (Champion Victory Celebration)
  if (triggerMatchWonAnimation) {
    triggerMatchWonAnimation = false;
    uint32_t champColor = (winningTeam == 1) ? COLOR_TEAM1_RED : COLOR_TEAM2_BLUE;
    Serial.printf("[PADEL] 🏆🏆🏆 MATCH WON by Team %d! Final Sets: %d - %d\n",
                  winningTeam, team1Sets, team2Sets);

    for (int cycle = 0; cycle < 5; cycle++) {
      for (int i = 0; i < NUMPIXELS; i++) {
        pixels.setPixelColor(i, champColor);
      }
      showPixelsSafe();
      delay(300);

      pixels.clear();
      drawGamesAndSets(currentCourtSwapped, 1.0f);
      showPixelsSafe();
      delay(200);
    }

    bool newSwapped = isCourtSwapped();
    if (newSwapped != currentCourtSwapped) {
      animateCourtSideSwap(newSwapped);
      currentCourtSwapped = newSwapped;
    }

    notifyWatchScore();
    scoreNeedsUpdate = true;
  }

  if (scoreNeedsUpdate) {
    scoreNeedsUpdate = false;
    renderPadelScoreboard();
  }

  delay(20);
}
