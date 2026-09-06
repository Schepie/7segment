// ==============================================================================
// ESP32 Padel Scoreboard - Xiaomi / YI Bluetooth Remote (XYLY01)
// Version: Direct 4-Digit Edition (Only the 4 7-segment panels, no colon or games/sets)
//
// Remote Specifications:
//   Model: Xiaomi / YI Action Camera Remote (XYLY01, advertised as "XiaoYi_RC")
//   Protocol: BLE HID Report Characteristic (0x2A4D under Service 0x1812)
//   Big Button (Top / Shutter, 0x40): Point for Team 1 (Left / Blue)
//   Small Button (Bottom / Mode, 0x80): Point for Team 2 (Right / Red)
//   Double Click (Within 380ms): UNDO the previous point / game / set!
//
// Physical LED Chain & Wiring Order (112 LEDs Total - Direct Digit Chaining):
//   1. Digit 0 (Team 1 Tens): 28 LEDs (0..27)
//   2. Digit 1 (Team 1 Ones): 28 LEDs (28..55)
//   3. Digit 2 (Team 2 Tens): 28 LEDs (56..83)
//   4. Digit 3 (Team 2 Ones): 28 LEDs (84..111)
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
#include <NimBLEDevice.h>
#include <Preferences.h>
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
#else
  #define LED_PIN           15     // WS2812 Data Pin on ESP32-S3 Zero (GPIO 15)
  #define ONBOARD_RGB_PIN   21     // Waveshare ESP32-S3 Zero On-board RGB (GPIO 21)
#endif

#define NUM_DIGITS        4      // 4 Digits total (2 for Team 1, 2 for Team 2)
#define LEDS_PER_SEGMENT  4      // 4 LEDs per segment
#define LEDS_PER_DIGIT    28     // 7 segments * 4 LEDs = 28 LEDs per digit
#define NUMPIXELS         (NUM_DIGITS * LEDS_PER_DIGIT) // 112 LEDs total (No middle module)
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

inline int getDigitBaseLed(int digitIndex) {
  return digitIndex * LEDS_PER_DIGIT;
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

// ==============================================================================
// Hardware SPI DMA WS2812 Driver (ESP32-C3)
// 100% immune to BLE / CPU preemption glitches. Hardware DMA pushes bits autonomously.
// ==============================================================================
bool bleInitialized = false;

#if defined(CONFIG_IDF_TARGET_ESP32C3)
#include <driver/spi_master.h>

#define NUM_DUMMY_PIXELS  1
#define TOTAL_SPI_PIXELS  (NUMPIXELS + NUM_DUMMY_PIXELS)

static spi_device_handle_t ws2812_spi = nullptr;
static uint8_t* ws2812_dma_buf = nullptr;
static size_t ws2812_dma_buf_size = 0;
static size_t ws2812_led_bytes = 0;
static size_t ws2812_reset_bytes = 0;
static uint32_t spiLookup[256];
static bool spiLookupReady = false;

static void initWs2812SpiDma() {
  if (!spiLookupReady) {
    for (int b = 0; b < 256; b++) {
      uint32_t pattern = 0;
      for (int bit = 7; bit >= 0; bit--) {
        // MSB first on wire: 4 SPI bits per WS2812 bit
        // '0' -> 1000 (312.5ns HIGH, 937.5ns LOW) = 0x8
        // '1' -> 1110 (937.5ns HIGH, 312.5ns LOW) = 0xE
        uint32_t nibble = (b & (1 << bit)) ? 0x0E : 0x08;
        pattern = (pattern << 4) | nibble;
      }
      uint8_t b0 = (pattern >> 24) & 0xFF;
      uint8_t b1 = (pattern >> 16) & 0xFF;
      uint8_t b2 = (pattern >> 8)  & 0xFF;
      uint8_t b3 = pattern & 0xFF;
      spiLookup[b] = (uint32_t)b0 | ((uint32_t)b1 << 8) | ((uint32_t)b2 << 16) | ((uint32_t)b3 << 24);
    }
    spiLookupReady = true;
  }

  if (ws2812_spi == nullptr) {
    // Configure pull-down so MOSI is never pulled high or left floating when SPI is idle
    gpio_set_pull_mode((gpio_num_t)LED_PIN, GPIO_PULLDOWN_ONLY);
    gpio_set_drive_capability((gpio_num_t)LED_PIN, GPIO_DRIVE_CAP_3);

    ws2812_led_bytes = TOTAL_SPI_PIXELS * 3 * 4;
    ws2812_reset_bytes = 200; // 200 bytes * 8 * 312.5ns = 500us of continuous LOW reset!
    ws2812_dma_buf_size = ws2812_led_bytes + ws2812_reset_bytes;

    spi_bus_config_t buscfg = {};
    buscfg.mosi_io_num = LED_PIN;
    buscfg.miso_io_num = -1;
    buscfg.sclk_io_num = -1;
    buscfg.quadwp_io_num = -1;
    buscfg.quadhd_io_num = -1;
    buscfg.max_transfer_sz = ws2812_dma_buf_size + 128;

    esp_err_t err = spi_bus_initialize(SPI2_HOST, &buscfg, SPI_DMA_CH_AUTO);
    if (err != ESP_OK && err != ESP_ERR_INVALID_STATE) {
      Serial.printf("[SPI-DMA] Bus init failed: %d\n", err);
      return;
    }

    spi_device_interface_config_t devcfg = {};
    devcfg.clock_speed_hz = 3200000; // 3.2 MHz (312.5ns/bit)
    devcfg.mode = 0;
    devcfg.spics_io_num = -1;
    devcfg.queue_size = 1;

    err = spi_bus_add_device(SPI2_HOST, &devcfg, &ws2812_spi);
    if (err != ESP_OK) {
      Serial.printf("[SPI-DMA] Device add failed: %d\n", err);
      return;
    }

    ws2812_dma_buf = (uint8_t*)heap_caps_malloc(ws2812_dma_buf_size, MALLOC_CAP_DMA);
    if (ws2812_dma_buf == nullptr) {
      Serial.println("[SPI-DMA] Buffer alloc failed!");
      return;
    }
    memset(ws2812_dma_buf, 0, ws2812_dma_buf_size);
    Serial.println("[SPI-DMA] Hardware SPI DMA WS2812 driver active on GPIO 2 (500us reset + dummy LED)!");
  }
}

static void showWs2812SpiDma() {
  if (ws2812_spi == nullptr || ws2812_dma_buf == nullptr) {
    initWs2812SpiDma();
    if (ws2812_spi == nullptr || ws2812_dma_buf == nullptr) {
      pixels.show();
      return;
    }
  }

  uint8_t* rawPixels = pixels.getPixels();
  if (rawPixels == nullptr) return;

  uint32_t* out32 = (uint32_t*)ws2812_dma_buf;
  size_t numBytes = NUMPIXELS * 3;
  for (size_t i = 0; i < numBytes; i++) {
    out32[i] = spiLookup[rawPixels[i]];
  }

  // Clock in 1 dummy blank pixel (24 bits) to ensure the very last physical LED (LED 111)
  // has all 24 bits pushed completely through its internal shift register into its latch
  out32[numBytes + 0] = spiLookup[0];
  out32[numBytes + 1] = spiLookup[0];
  out32[numBytes + 2] = spiLookup[0];

  // Guarantee trailing reset bytes are strictly 0x00 on every single frame
  memset(ws2812_dma_buf + ws2812_led_bytes, 0, ws2812_reset_bytes);

  spi_transaction_t t = {};
  t.length = ws2812_dma_buf_size * 8; // in bits
  t.tx_buffer = ws2812_dma_buf;
  spi_device_polling_transmit(ws2812_spi, &t);
}
#endif

void showPixelsSafe() {
#if defined(CONFIG_IDF_TARGET_ESP32C3)
  showWs2812SpiDma();
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

void renderBoardWithState(bool swapped, float brightnessFactor) {
  pixels.clear();
  if (brightnessFactor <= 0.001f) {
    showPixelsSafe();
    return;
  }

  uint32_t colorBlue = scaleColor(pixels.Color(0, 80, 255), brightnessFactor);
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

  showPixelsSafe();
}

void animateCourtSideSwap(bool toSwapped) {
  bool fromSwapped = !toSwapped;
  uint32_t cBlue    = pixels.Color(0, 80, 255);
  uint32_t cRed     = pixels.Color(255, 0, 0);
  uint32_t cBlueDim = pixels.Color(0, 20, 65);
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

  // Phase 2: Orbital Crossover Flow across all 4 digits
  // If toSwapped: Blue travels 0 -> 1 -> 2 -> 3 (Top rail)
  //               Red travels 3 -> 2 -> 1 -> 0 (Bottom rail)
  // If !toSwapped: Blue travels 3 -> 2 -> 1 -> 0 (Top rail)
  //                Red travels 0 -> 1 -> 2 -> 3 (Bottom rail)
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

void renderPadelScoreboard() {
  renderBoardWithState(isCourtSwapped(), 1.0f);
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
}

// ==============================================================================
// Button & Interaction Logic
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
  Serial.println("   ESP32 Padel Scoreboard - Direct 4-Digit Edition     ");
  Serial.println("   Big: Team 1 (+1) | Small: Team 2 (+1) | 2x: Undo    ");
  Serial.println("   112 LEDs Total: 4 Digits x 28 LEDs (No middle mod)  ");
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

  // Initialize BLE Stack first so all BLE handles are valid
  Serial.println("[BLE] Initializing NimBLE stack...");
  NimBLEDevice::init("ESP32-Scoreboard");
  NimBLEDevice::setSecurityAuth(true, true, true);
  NimBLEDevice::setSecurityIOCap(BLE_HS_IO_NO_INPUT_OUTPUT);
  NimBLEDevice::setPower(ESP_PWR_LVL_P9);
  bleInitialized = true;

  // Initialize BLE FOTA Server
  NimBLEServer* pServer = NimBLEDevice::createServer();
  BleFota::init(pServer, "Padel-Scoreboard-OTA");
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
  pAdvertising->setName("Padel-Scoreboard-OTA");
  pAdvertising->addServiceUUID(BLE_FOTA_SERVICE_UUID);
  pAdvertising->setMinInterval(320); // 200ms
  pAdvertising->setMaxInterval(640); // 400ms
  pAdvertising->start();

  // Initialize Preferences to remember paired remote
  prefs.begin("padel_remote", false);
  savedRemoteMac = prefs.getString("remote_mac", "");
  if (savedRemoteMac.length() > 0) {
    Serial.printf("[BLE] Stored paired remote MAC from previous session: %s\n", savedRemoteMac.c_str());
  }

  NimBLEScan* pScan = NimBLEDevice::getScan();
  pScan->setAdvertisedDeviceCallbacks(new AdvertisedDeviceCallbacks(), false);
  pScan->setInterval(80); // Fast 50ms scan interval
  pScan->setWindow(76);   // 95% duty cycle: catches fast button advertising bursts
  pScan->setActiveScan(true);
  pScan->setDuplicateFilter(false); // CRITICAL: NEVER discard duplicate adverts so missed packets can retry!

  // Brief startup splash (safe now that BLE stack is initialized)
  splashText("SCAN", pixels.Color(0, 80, 255));
  delay(600);

  currentCourtSwapped = isCourtSwapped();
  renderPadelScoreboard();
}

void loop() {
  if (BleFota::isUpdating()) {
    delay(100);
    return;
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

      bool newSwapped = isCourtSwapped();
      if (newSwapped != currentCourtSwapped) {
        Serial.printf("[PADEL] Court side switch on Undo! (%s -> %s)\n",
                      currentCourtSwapped ? "Swapped" : "Normal",
                      newSwapped ? "Swapped" : "Normal");
        animateCourtSideSwap(newSwapped);
        currentCourtSwapped = newSwapped;
      }
      scoreNeedsUpdate = true;
    } else {
      Serial.println("[BUTTON] Undo pressed, but no history available");
    }
  }

  // 1. Handle Game Won Animation (3 flashes of the winning team's side)
  if (triggerGameWonAnimation) {
    triggerGameWonAnimation = false;
    uint32_t winColor = (winningTeam == 1) ? pixels.Color(0, 80, 255) : pixels.Color(255, 0, 0);
    Serial.printf("[PADEL] ★ GAME WON by Team %d! Current Games: %d - %d (Sets: %d - %d)\n",
                  winningTeam, team1Games, team2Games, team1Sets, team2Sets);

    int gamesVal = (winningTeam == 1) ? team1Games : team2Games;
    // Determine which side winning team was located on before this transition:
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
      showPixelsSafe();
      delay(200);

      pixels.clear();
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
      showPixelsSafe();
      delay(250);

      pixels.clear();
      showPixelsSafe();
      delay(150);
    }

    bool newSwapped = isCourtSwapped();
    if (newSwapped != currentCourtSwapped) {
      animateCourtSideSwap(newSwapped);
      currentCourtSwapped = newSwapped;
    }

    scoreNeedsUpdate = true;
  }

  // 3. Handle Match Won Animation (Champion Victory Celebration)
  if (triggerMatchWonAnimation) {
    triggerMatchWonAnimation = false;
    uint32_t champColor = (winningTeam == 1) ? pixels.Color(0, 80, 255) : pixels.Color(255, 0, 0);
    Serial.printf("[PADEL] 🏆🏆🏆 MATCH WON by Team %d! Final Sets: %d - %d\n",
                  winningTeam, team1Sets, team2Sets);

    for (int cycle = 0; cycle < 5; cycle++) {
      for (int i = 0; i < NUMPIXELS; i++) {
        pixels.setPixelColor(i, champColor);
      }
      showPixelsSafe();
      delay(300);

      pixels.clear();
      showPixelsSafe();
      delay(200);
    }

    bool newSwapped = isCourtSwapped();
    if (newSwapped != currentCourtSwapped) {
      animateCourtSideSwap(newSwapped);
      currentCourtSwapped = newSwapped;
    }

    scoreNeedsUpdate = true;
  }

  if (scoreNeedsUpdate) {
    scoreNeedsUpdate = false;
    renderPadelScoreboard();
  }

  delay(20);
}
