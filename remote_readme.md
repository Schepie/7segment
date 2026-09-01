# Xiaomi / YI Bluetooth Remote (XYLY01) Integration Manual

This document details the hardware configuration, Bluetooth Low Energy (BLE) HID communication protocol, button mapping, and 7-segment display driver settings for the **Xiaomi / YI Action Camera Remote (Model: XYLY01 / XiaoYi_RC)** communicating with an **ESP32-S3 Zero** (or Lolin S3 Mini).

---

## 1. Hardware Specifications

| Component | Specification |
| :--- | :--- |
| **Microcontroller** | Waveshare ESP32-S3 Zero (4MB Flash, DIO mode, USB CDC on boot) |
| **Bluetooth Remote** | Xiaomi / YI Remote (Model: `XYLY01`, Advertised Name: `XiaoYi_RC`) |
| **Display Panel** | 2x Chained 7-Segment Modules (56 WS2812B LEDs total: 2 digits $\times$ 7 segments $\times$ 4 LEDs) |
| **WS2812 DIN Pin** | **`GPIO 15`** |
| **Onboard RGB Status LED** | **`GPIO 21`** (ESP32-S3 Zero onboard WS2812) |
| **LED Index Offset** | **`+1 LED`** (`#define LED_START_OFFSET 1`) for mechanical alignment inside diffusers |

---

## 2. PlatformIO Board Configuration (`platformio.ini`)

Because the ESP32-S3 Zero features 4MB flash (rather than 8MB), `platformio.ini` requires the following explicit flash configuration:

```ini
[env:esp32s3_zero]
platform = espressif32
board = esp32-s3-devkitc-1
board_build.mcu = esp32s3
board_build.flash_mode = dio
board_upload.flash_size = 4MB
board_build.partitions = default.csv
framework = arduino
build_flags = 
	-DARDUINO_USB_CDC_ON_BOOT=1
	-DARDUINO_USB_MODE=1
lib_deps = 
	adafruit/Adafruit NeoPixel
	h2zero/NimBLE-Arduino @ ^1.4.2
	makuna/RTC @ ^2.4.3
```

---

## 3. BLE HID Communication & Protocol (NimBLE)

### A. Discovery & Identification
- **Advertised Device Names:** `XiaoYi_RC`, `XYLY01`, or standard HID devices advertising Service `0x1812`.
- **Target Remote MAC Address:** e.g. `04:e6:76:b2:8a:b6`.

### B. Security & Connection Parameters
- The remote operates with **Just Works / Auto-confirm** bonding:
  ```cpp
  NimBLEDevice::init("ESP32-S3-Scoreboard");
  NimBLEDevice::setSecurityAuth(true, true, true); // Bonding + MITM + Secure Connections
  NimBLEDevice::setSecurityIOCap(BLE_HS_IO_NO_INPUT_OUTPUT);
  NimBLEDevice::setPower(ESP_PWR_LVL_P9);
  ```
- **Connection Timing (Prevent Dropouts):**
  ```cpp
  bleClient->setConnectionParams(24, 40, 0, 400); // 30ms - 50ms interval, 4s supervision timeout
  ```
- **Subscribing to HID Notifications:**
  Subscribe to all characteristics with `canNotify()` or `canIndicate()` under Service `0x1812` (particularly Report Characteristic `0x2A4D`) with `pChar->subscribe(true, onHIDNotification, true)`.

---

## 4. Remote Button Packet Structure (XYLY01)

The remote transmits **3-byte notification payloads** to Characteristic `0x2A4D`:

| Button / Action | Raw Notification Bytes | Logic State | Action Triggered |
| :--- | :--- | :--- | :--- |
| **Big Button (Top / Shutter)** | `0x40 0x00 0x00` | Pressed | **Count UP (+1)** |
| **Small Button (Bottom / Mode)** | `0x80 0x00 0x00` | Pressed | **Count DOWN (-1)** |
| **Button Release** | `0x00 0x00 0x00` | Released | Evaluates click count & timing |

---

## 5. Interaction & Scoring Controls

```
           ┌────────────────────────┐
           │        (  ○  )         │  <--- BIG BUTTON (0x40)
           │      Top Shutter       │       • Single Click: Count UP (+1)
           │                        │       • Double Click: Next Color
           │                        │
           │        [  ■  ]         │  <--- SMALL BUTTON (0x80)
           │      Bottom Mode       │       • Single Click: Count DOWN (-1)
           │                        │       • Double Click: Next Color
           └────────────────────────┘
```

- **Single Click:**
  - **Big Button:** Increases score from $1 \to 99$.
  - **Small Button:** Decreases score from $99 \to 1$.
- **Double Click (Either Button):**
  - Detected within a **`380ms`** window.
  - Cycles through 8 curated color presets:
    1. Cyan / Ice Blue (`0, 220, 255`)
    2. Vivid Red (`255, 0, 0`)
    3. Emerald Green (`0, 255, 60`)
    4. Sunset Orange (`255, 75, 0`)
    5. Golden Yellow (`255, 200, 0`)
    6. Electric Purple (`180, 20, 255`)
    7. Pure White (`255, 255, 255`)
    8. Hot Pink (`255, 20, 150`)
- **Visual Feedback:**
  - Double-clicking flashes the new color twice on the display for immediate confirmation.

---

## 6. Onboard Status LED Codes (GPIO 21)

| LED Color | Meaning |
| :--- | :--- |
| **Blue** | Booting & scanning for remote |
| **Orange** | Establishing connection & exchanging BLE keys |
| **Green** | Successfully connected and actively receiving scores |
| **Red** | Connection error / link lost (auto-resumes scanning) |

---

## 7. 7-Segment Wiring & Offsets

```cpp
#define LED_PIN           15     // GPIO 15
#define NUM_DIGITS        2      // 2 Digits
#define LEDS_PER_SEGMENT  4      // 4 LEDs per segment
#define LEDS_PER_DIGIT    28     // 7 segments * 4 = 28 LEDs per digit
#define LED_START_OFFSET  1      // +1 LED shift to align physical channels
#define NUMPIXELS         (NUM_DIGITS * LEDS_PER_DIGIT + LED_START_OFFSET)
```

### Segment Wiring Order:
- `Seg A`: Bottom-Left ($0 \to 3$)
- `Seg B`: Bottom ($4 \to 7$)
- `Seg C`: Bottom-Right ($8 \to 11$)
- `Seg D`: Middle ($12 \to 15$)
- `Seg E`: Top-Left ($16 \to 19$)
- `Seg F`: Top ($20 \to 23$)
- `Seg G`: Top-Right ($24 \to 27$)
