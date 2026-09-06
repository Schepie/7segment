# 🎾 ESP32 7-Segment Padel Scoreboard & Digital Clock

A modular, high-visibility electronic scoreboard and real-time clock system built with **ESP32**, **WS2812B addressable LEDs (114 LEDs total)**, **Bluetooth Low Energy (BLE)**, and 3D-printed snap-fit 7-segment displays.

---

## 🌟 Features Overview

* **3-in-1 Unified Firmware (`main_combined.cpp`):** Switch on the fly between **Digital Clock**, **BLE Scoreboard (Phone/Watch App)**, and **Xiaomi Shutter Remote Controller** using a single push button.
* **Seamless Standalone Modes:** Dedicated standalone firmware options are also provided if you only need a single function.
* **Xiaomi / YI Action Camera Remote Support (XYLY01):** Score directly from the court with single-click scoring and double-click undo.
* **Wear OS & Web App Integration:** BLE GATT server connects directly to a Galaxy Watch or mobile/web browser.
* **Official Padel Scoring Engine:** Full support for `0 -> 15 -> 30 -> 40`, Deuce, Advantage (`Ad`), Game clinches, and a 30-step Undo stack.
* **Smooth Color Crossfades & Animations:** Silky 50 FPS transitions, victory splash screens (`GAmE`), mode splashes (`CLOC`, `SCOR`, `ShUt`), and side-swap wipes.

---

## 🕹️ Mode Switching (The Button)

In the unified firmware ([src/main_combined.cpp](src/main_combined.cpp)), you can cycle through all 3 modes using a single button:

| Board | Pin | Default Button | Wiring for External Button |
| :--- | :---: | :--- | :--- |
| **Waveshare ESP32-S3 Zero** | **`GPIO 0`** | Built-in **BOOT** button | Connect between `GPIO 0` and `GND` |
| **ESP32-C3 SuperMini** | **`GPIO 9`** | Built-in **BOOT** button | Connect between `GPIO 9` and `GND` |

> [!TIP]
> **No extra wiring required to test!** You can simply press the onboard **BOOT** button on your ESP32-S3 Zero or C3 to switch modes immediately.

### Mode Progression:
Each button press cycles to the next mode and shows a 700ms splash screen on the 7-segment display:

```
┌──────────────┐      Button      ┌──────────────┐      Button      ┌──────────────┐
│  Mode 0:     │  ─────────────>  │  Mode 1:     │  ─────────────>  │  Mode 2:     │
│  "CLOC"      │      Press       │  "SCOR"      │      Press       │  "ShUt"      │
│  (Clock)     │                  │ (Scoreboard) │                  │  (Remote)    │
└──────────────┘                  └──────────────┘                  └──────────────┘
       ▲                                                                   │
       └───────────────────────── Button Press ────────────────────────────┘
```

---

## 📖 The Programs Explained

### 1. Unified Firmware — [src/main_combined.cpp](src/main_combined.cpp) *(Recommended)*
Combines all three modes into a single image with smart power/radio management (disables BLE advertising/scanning when in non-BLE modes):
* **Mode 0: Digital Clock (`CLOC`)**
  * Displays hours and minutes (`HH:MM`) with a blinking colon (500ms on/off).
  * Reads real-time from an optional **DS1302 RTC** module.
  * If no RTC is connected, automatically initializes an internal software clock synced to your computer's compile time (`__TIME__`).
  * Smooth 6-second cosine color crossfade across an 8-color palette.
* **Mode 1: BLE Padel Scoreboard (`SCOR`)**
  * Acts as a **BLE GATT Server** advertising as `"Padel Display"`.
  * Receives score payloads (`"1530"`, `"Ad40"`, `" 0 0"`) from the Wear OS app or Web App.
  * Team 1 is displayed in **Blue** (Digits 0 & 1), Team 2 in **Red** (Digits 2 & 3), and Colon in **White**.
  * Supports automatic side-swap wipe animation.
* **Mode 2: Xiaomi Shutter Remote Scoreboard (`ShUt`)**
  * Acts as a **BLE Central / Client** scanning for and auto-connecting to the Xiaomi / YI remote (`XiaoYi_RC` / `XYLY01`).
  * Runs the full Padel scoring rules directly on the display without needing a phone or watch!

---

### 2. Standalone Clock — [src/main_clock.cpp](src/main_clock.cpp)
A lightweight, dedicated 4-digit clock with colon. Ideal if the display is permanently mounted as a wall clock.
* Includes DS1302 driver and internal software clock fallback.
* Configurable 12h/24h format and leading zero blanking.

---

### 3. Standalone BLE Scoreboard Server — [src/main.cpp](src/main.cpp)
Dedicated BLE GATT server designed to communicate with the **Wear OS Watch App** and browser interface.
* GATT Service UUID: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
* Characteristic UUID: `beb5483e-36e1-4688-b7f5-ea07361b26a8`

---

### 4. Standalone Remote Scoreboard — [src/main_button.cpp](src/main_button.cpp)
Dedicated BLE Central firmware connecting directly to the Xiaomi / YI action camera shutter remote. Ideal for standalone court play where only the physical remote is used.

---

### 5. Dual-Control Edition — [src/main_dual_4digits.cpp](src/main_dual_4digits.cpp) *(New)*
Simultaneous dual-role firmware with integrated **24-LED Games & Sets Indicator Module** (136 LEDs total: 4 digits $\times$ 28 LEDs + 24 LEDs in the middle module).
* **Simultaneous Connections:** Runs as a **BLE Central** (connecting to the Xiaomi Remote clicker) **AND** as a **BLE Peripheral** (advertising as `"Padel Display"` with GATT service `4fafc201-1fb5-459e-8fcc-c5c9c331914b` for the Wear OS watch app and web dashboard).
* **Games & Sets Indicator Module (LEDs 56..79):** Dedicated middle module showing live games (G1..G9) and sets (S1..S2) won by each team with full court side-swap symmetry.
* **Bidirectional Real-Time Sync:** Points and games scored on the court via the Xiaomi remote immediately notify the watch over BLE (`"SCORE,FLAG,G1,G2,S1,S2"`), while points tapped on the watch update the scoreboard and middle module in real time.
* **Hardware SPI DMA Driver (ESP32-C3):** Glitch-free WS2812 driving on GPIO 2 with 500µs reset and trailing dummy bit flush, completely immune to BLE radio interrupts.
* **Unified Team Color Scheme:** Team 1 is **Red** (Left / Big Button / Top on Watch), Team 2 is **Blue** (Right / Small Button / Bottom on Watch), Sets in **Gold/Yellow**.
* **Court Side-Swap Transition:** Silky orbital crossover animation when teams switch ends on uneven game counts.

---

## 📷 Xiaomi / YI Bluetooth Remote Controls (XYLY01)

The Xiaomi / YI Action Camera Remote communicates via standard BLE HID reports (Characteristic `0x2A4D` under Service `0x1812`).

```
           ┌────────────────────────┐
           │        (  ○  )         │  <--- BIG BUTTON (0x40)
           │      Top Shutter       │       • Single Click: +1 Point Team 1 (Left / Red)
           │                        │       • Double Click: UNDO Previous Point
           │                        │
           │        [  ■  ]         │  <--- SMALL BUTTON (0x80)
           │      Bottom Mode       │       • Single Click: +1 Point Team 2 (Right / Blue)
           │                        │       • Double Click: UNDO Previous Point
           └────────────────────────┘
```

* **Single Click:**
  * **Big Button:** Adds a point to **Team 1 (Red)** (` 0` $\to$ `15` $\to$ `30` $\to$ `40` $\to$ `Ad` $\to$ Game Won).
  * **Small Button:** Adds a point to **Team 2 (Blue)**.
* **Double Click (Either Button within 380ms):**
  * **UNDO:** Reverts the score to the previous point from the 30-entry history stack.
* **Game Won / Set Won:**
  * Flashes winning team's side and displays set / match champion animations.

---

## 🔌 Hardware Wiring & Pinout

### 1. LED Strip Chain (114 WS2812B LEDs Total)
The strip runs in one continuous data chain through the digits and colon:

```
ESP32 DIN ──> [ Digit 0 ] ──> [ Digit 1 ] ──> [ Colon ] ──> [ Digit 2 ] ──> [ Digit 3 ]
              (28 LEDs)       (28 LEDs)       (2 LEDs)       (28 LEDs)       (28 LEDs)
              LEDs 0..27      LEDs 28..55     LEDs 56..57    LEDs 58..85     LEDs 86..113
              Team 1 (Tens)   Team 1 (Ones)   Center Dots    Team 2 (Tens)   Team 2 (Ones)
```

### 2. Segment Wiring per Digit (4 LEDs per segment = 28 LEDs)

#### Standard Panels (Digits 1, 2, 3):
Each standard 7-segment digit routes sequentially:
* **Segment 0 (BL - Bottom-Left):** LEDs `0..3`
* **Segment 1 (B  - Bottom):** LEDs `4..7`
* **Segment 2 (BR - Bottom-Right):** LEDs `8..11`
* **Segment 3 (M  - Middle):** LEDs `12..15`
* **Segment 4 (TL - Top-Left):** LEDs `16..19`
* **Segment 5 (T  - Top):** LEDs `20..23`
* **Segment 6 (TR - Top-Right):** LEDs `24..27`

#### First Panel (Digit 0) Hardware Variation:
On the physical prototype of Digit 0 (Panel 1), the first soldered segment in the chain is **Top-Right (TR)** instead of Bottom-Left (BL). The firmware steers Digit 0 seamlessly via `panel0SegmentMap[7]` (`PANEL0_CUSTOM_WIRING`):
* **Slot 0 (LEDs 0..3):** `TR` (Top-Right)
* **Slot 1 (LEDs 4..7):** `T`  (Top)
* **Slot 2 (LEDs 8..11):** `TL` (Top-Left)
* **Slot 3 (LEDs 12..15):** `M`  (Middle)
* **Slot 4 (LEDs 16..19):** `BR` (Bottom-Right)
* **Slot 5 (LEDs 20..23):** `B`  (Bottom)
* **Slot 6 (LEDs 24..27):** `BL` (Bottom-Left)
*(All subsequent panels use standard wiring)*

### 3. Microcontroller Pin Assignments

| Function | ESP32-S3 Zero (Waveshare) | ESP32-C3 SuperMini |
| :--- | :---: | :---: |
| **WS2812 DIN** | `GPIO 15` | `GPIO 2` |
| **Mode Switch Button** | `GPIO 0` (BOOT) | `GPIO 9` (BOOT) |
| **Onboard Status LED** | `GPIO 21` (WS2812 RGB) | `GPIO 8` (Active LOW) |
| **RTC DS1302 CLK (SCLK)** | `GPIO 4` | `GPIO 4` |
| **RTC DS1302 DAT (I/O)** | `GPIO 5` | `GPIO 5` |
| **RTC DS1302 RST (CE)** | `GPIO 6` | `GPIO 3` |

---

## ⚡ Building & Uploading (PlatformIO)

The project uses `build_src_filter` in [platformio.ini](platformio.ini) to keep all programs organized without file collisions.

### Environment Matrix:

| Target Microcontroller | Firmware | PlatformIO Environment |
| :--- | :--- | :--- |
| **ESP32-S3 Zero** *(Default)* | **Unified (All-in-One)** | `esp32s3_zero_combined` |
| ESP32-S3 Zero | Standalone Scoreboard | `esp32s3_zero` |
| ESP32-S3 Zero | Standalone Clock | `esp32s3_zero_clock` |
| ESP32-S3 Zero | Standalone Remote | `esp32s3_zero_button` |
| **ESP32-C3 SuperMini** | **Unified (All-in-One)** | `esp32c3_supermini_combined` |
| ESP32-C3 SuperMini | Standalone Scoreboard | `esp32c3_supermini` |
| ESP32-C3 SuperMini | Standalone Clock | `esp32c3_supermini_clock` |
| ESP32-C3 SuperMini | Standalone Remote | `esp32c3_supermini_button` |

### How to Flash:
1. Open this repository in **VS Code** with the **PlatformIO** extension.
2. In the bottom status bar, select your target environment (e.g. `env:esp32s3_zero_combined`).
3. Click the **Upload (→)** button, or run in the terminal:
   ```powershell
   # Flash the combined 3-in-1 firmware to ESP32-S3 Zero
   pio run -e esp32s3_zero_combined -t upload
   ```
