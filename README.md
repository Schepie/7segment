# 🎾 ESP32 7-Segment Padel Scoreboard & Digital Clock

A professional, modular, high-visibility electronic scoreboard and real-time clock system built with **ESP32**, **WS2812B addressable LEDs (up to 136 LEDs)**, **Bluetooth Low Energy (BLE)**, **Web Bluetooth API**, and snap-fit 3D-printed 7-segment displays.

The scoreboard acts as the **Master Rules Engine** and single source of truth for the entire match ecosystem, synchronizing in real time with the **Wear OS smartwatch app**, a physical **Xiaomi Bluetooth clicker remote**, and the **companion spectator mobile web app**.

---

## 🌟 System Architecture & Master/Slave Model

In this ecosystem, the **ESP32 Scoreboard is ALWAYS the Master**. It maintains and enforces all match rules, points, games, sets, and tiebreaks:

```
                  ┌─────────────────────────────────────────────────────────┐
                  │                 ESP32 SCOREBOARD MASTER                 │
                  │   (src/main_button_Setsandmatch.cpp / NVS Flash Cfg)    │
                  └───────────────┬─────────────────────────┬───────────────┘
                                  │                         │
                  BLE GATT Server │                         │ BLE Central (HID)
          ("Padel Display" 0x4FAF)│                         │ (Auto-Pairing)
                                  ▼                         ▼
         ┌─────────────────────────────────┐       ┌────────────────────────┐
         │     WEAR OS SMARTWATCH SLAVE    │       │  XIAOMI SHUTTER REMOTE │
         │   • Syncs rules via CMD,REQ     │       │    (XYLY01 Clicker)    │
         │   • Touch & voice point scoring │       │  • Big Btn: Team 1 (Pt)│
         │   • NFC & QR spectator sharing  │       │  • Sml Btn: Team 2 (Pt)│
         └────────────────┬────────────────┘       │  • Dbl Click: UNDO     │
                          │                        └────────────────────────┘
                          │ HTTPS REST
                          │ (Netlify Functions)
                          ▼
         ┌─────────────────────────────────┐
         │     SPECTATOR WEB APP SLAVE     │
         │   (https://padelpunten.netlify) │
         │   • Real-time match observer    │
         │   • Read-only rules display     │
         │   • Single Team Focus modes     │
         └─────────────────────────────────┘
```

* **Master Rules Enforcement:** Match rules (Golden Point vs. Advantage, Best of 3 sets vs. 1 set, 6 vs. 9 games per set, Tiebreak) are stored in ESP32 Non-Volatile Flash (`NVS`) and transmitted to clients on connect via `CFG,...`. Clients cannot alter rules during play.
* **Slave Synchronization:** The Wear OS app and spectator web app act as clients. They receive configuration broadcasts and mirror the official master state.
* **Web Bluetooth Direct Control:** Court administrators can configure match rules, brightness, sleep timeouts, and RTC time directly via the [Scoreboard Mobile Controller](https://schepie.github.io/7segment/settings.html).

---

## 🎨 Unified Team Color Standard

To avoid confusion between players, spectators, and hardware displays, all components adhere strictly to this unified color mapping:

| Component | Team 1 (Left / Serving) | Team 2 (Right / Receiving) | Sets Indicator |
| :--- | :---: | :---: | :---: |
| **Color** | **BLUE** | **RED** | **GOLD / YELLOW** |
| **ESP32 WS2812B RGB** | `RGB(0, 180, 255)` | `RGB(255, 0, 0)` | `RGB(255, 180, 0)` |
| **Web Controller (`settings.html`)** | `#00d2ff` | `#ff3366` | `#ffb300` |
| **Wear OS Watch App** | `#1E88E5` | `#E53935` | `#FFB300` |
| **Spectator Mobile Web App** | `#3b82f6` | `#ef4444` | `#eab308` |
| **Xiaomi Remote Button** | **Big Button (Top / Shutter)** | **Small Button (Bottom / Mode)** | N/A |
| **Physical Display Position** | **Digits 0 & 1 (Left)** | **Digits 2 & 3 (Right)** | **Middle Module (LEDs 56..79)** |

---

## 📖 Firmware Editions & Programs

All firmware source files reside in [`src/`](src/) and can be compiled using PlatformIO:

### 1. Flagship: Sets & Match Dual-Role Edition — [src/main_button_Setsandmatch.cpp](src/main_button_Setsandmatch.cpp) *(Recommended)*
The ultimate tournament firmware with simultaneous multi-device connectivity and dedicated Games & Sets indicators:
* **Simultaneous Connections:** Operates as a **BLE Central** (connected to the Xiaomi Remote clicker) **AND** a **BLE Peripheral** (advertising as `"Padel Display"` for the Wear OS watch and web controller).
* **24-LED Games & Sets Module (LEDs 56..79):**
  * Left column (Team 1 Blue): 9 Game LEDs (bottom-to-top) + 2 Set LEDs.
  * Right column (Team 2 Red): 2 Set LEDs + 9 Game LEDs (top-to-bottom).
* **Hardware SPI DMA Driver (ESP32-C3):** Pushes WS2812 bitstreams via hardware SPI MOSI (`GPIO 2`) with DMA buffering. Completely immune to BLE radio interrupts, preemption, or flicker.
* **NVS Flash Persistence (`padel_cfg`):** Remembers match settings, LED brightness, idle timeouts, and paired remote MAC across power cuts.
* **Inactivity Idle Timer:** Automatically fades to Digital Clock mode after a configurable idle period (e.g. 5 minutes without activity).
* **Official Rules Engine:**
  * Advantage (`Ad`) vs. Golden Point / Punto de Oro (`GP`).
  * Sets to win (1 or 2).
  * Games per set (6 or 9).
  * Tiebreak mode at 6-6 (or 8-8) with alternating court side-swap tracking.
  * 30-step historical Undo buffer.
* **End-of-Match Celebration:** Victory animations (`GAmE`) and automated cycling through past set scores (`6-4`, `3-6`, `7-6`).

### 2. Unified 3-in-1 Firmware — [src/main_combined.cpp](src/main_combined.cpp)
Cycle between 3 distinct modes using a single onboard push-button (**BOOT** button on `GPIO 9` or `GPIO 0`):
* **Mode 0: Digital Clock (`CLOC`):** Displays 24-hour real-time clock synced via DS1302 RTC or computer build time.
* **Mode 1: BLE Padel Scoreboard (`SCOR`):** Standard BLE GATT server.
* **Mode 2: Xiaomi Shutter Remote Scoreboard (`ShUt`):** Direct BLE Central clicker connection.

### 3. Standalone Programs
* **[src/main_clock.cpp](src/main_clock.cpp):** Lightweight dedicated digital wall clock with smooth 6-second color crossfades.
* **[src/main.cpp](src/main.cpp):** Dedicated BLE GATT peripheral receiver.
* **[src/main_button.cpp](src/main_button.cpp):** Standalone Xiaomi remote clicker receiver (4 digits only).
* **[src/main_dual_4digits.cpp](src/main_dual_4digits.cpp):** Simultaneous remote + BLE watch connection without middle LED module.

---

## 📱 Web Bluetooth Controller & Settings App

Control the scoreboard directly from any smartphone, tablet, or laptop browser (Chrome, Edge, Bluefy) without installing an app:

🔗 **Live Controller URL:** [https://schepie.github.io/7segment/settings.html](https://schepie.github.io/7segment/settings.html)

### Features:
1. **Court Tab:** Live mirrored score digits, quick scoring buttons (+1 Team 1 Blue, +1 Team 2 Red), Undo, Reset Match, Court Side Swap, and Mode Switch (Clock / Scoreboard).
2. **Display Tab:** Real-time brightness slider (0..255), auto-sleep / idle timeout selector (Never, 1m, 5m, 10m, 15m, 30m), and one-tap **Sync Phone Time** button (sets the DS1302 RTC to local browser time).
3. **Rules Tab (Master Config):** Set Golden Point, Sets to Win (1 vs 3), Games per Set (6 vs 9), and Tiebreak rules. Automatically saves to ESP32 Flash memory and notifies connected smartwatches.
4. **Offline PWA Support:** Add to your mobile home screen with high-resolution icons for instant court-side launching.

---

## 📷 Xiaomi / YI Bluetooth Remote Controls (XYLY01)

The scoreboard connects directly to the Xiaomi / YI Action Camera Remote (`XiaoYi_RC`) over BLE HID (Characteristic `0x2A4D` under Service `0x1812`).

```
           ┌────────────────────────┐
           │        (  ○  )         │  <--- BIG BUTTON (0x40)
           │      Top Shutter       │       • Single Click: +1 Point Team 1 (Left / Blue)
           │                        │       • Double Click: UNDO Previous Point
           │                        │
           │        [  ■  ]         │  <--- SMALL BUTTON (0x80)
           │      Bottom Mode       │       • Single Click: +1 Point Team 2 (Right / Red)
           │                        │       • Double Click: UNDO Previous Point
           └────────────────────────┘
```

* **Single Click:**
  * **Big Button:** Adds a point to **Team 1 (Blue)** (` 0` $\to$ `15` $\to$ `30` $\to$ `40` $\to$ `Ad` $\to$ Game Won).
  * **Small Button:** Adds a point to **Team 2 (Red)**.
* **Double Click (Either Button within 380ms):**
  * Reverts the match state to the previous point, game, or set from the 30-entry history stack.
* **Auto-Pairing:** The ESP32 scans for `XiaoYi_RC`, pairs automatically, and persists the MAC address to NVS flash for instant reconnects on startup.

---

## 📡 Bluetooth Low Energy (BLE) Protocol Specification

The ESP32 runs a BLE GATT Server advertising as `"Padel Display"`.

### GATT Identifiers:
* **Device Name:** `Padel Display`
* **GATT Service UUID:** `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
* **GATT Characteristic UUID:** `beb5483e-36e1-4688-b7f5-ea07361b26a8`
* **Client Characteristic Configuration (CCCD):** `00002902-0000-1000-8000-00805f9b34fb` (Enable notifications: `0x0001`)

### Packet Formats:

#### 1. Configuration Broadcast (`CFG,...`)
Sent automatically upon client connection, or in response to `CMD,REQ_CFG`:
```
"CFG,GP=0,SETS=2,GAMES=6,TB=1,BRT=180,IDLE=300000"
      │    │      │       │    │       └── Inactivity idle timeout in ms (300000 = 5 min)
      │    │      │       │    └────────── LED Brightness (0 - 255)
      │    │      │       └─────────────── Tiebreak Enabled (1 = Yes, 0 = No)
      │    │      └─────────────────────── Games per Set (6 or 9)
      │    └────────────────────────────── Sets to Win (1 = Single set, 2 = Best of 3)
      └─────────────────────────────────── Golden Point (1 = Punto de Oro, 0 = Advantage)
```
Clients can write this string to update and persist rules into ESP32 flash.

#### 2. Live Score Notification (`SCORE,...`)
Notified whenever points, games, sets, or court sides change:
```
"1530,0,1,2,0,0,0"
 │ │ │ │ │ │ │ └── In Tiebreak Mode (0 = Normal, 1 = Tiebreak active)
 │ │ │ │ │ │ └──── Team 2 Sets Won
 │ │ │ │ │ └────── Team 1 Sets Won
 │ │ │ │ └──────── Team 2 Games Won
 │ │ │ └────────── Team 1 Games Won
 │ │ └──────────── Court Side Swapped Flag (0 = Normal, 1 = Swapped ends)
 │ └────────────── Team 2 Points (" 0", "15", "30", "40", "Ad")
 └──────────────── Team 1 Points (" 0", "15", "30", "40", "Ad")
```
*In Tiebreak mode*, points represent tiebreak rally points: `" 4 3,0,6,6,1,1,1"`.

#### 3. Control Commands (`CMD,...`)
Written by clients (Watch or Web Controller) to trigger actions:
* `CMD,P1`: Increment point for Team 1 (Blue).
* `CMD,P2`: Increment point for Team 2 (Red).
* `CMD,UNDO`: Step back one state in history.
* `CMD,RESET`: Reset the match to 0-0.
* `CMD,SWAP`: Manually toggle court side display orientation.
* `CMD,CLOCK`: Force the display into Digital Clock mode.
* `CMD,SCORE`: Wake up display into Scoreboard mode.
* `CMD,REQ` / `CMD,REQ_CFG`: Request the ESP32 to immediately notify current configuration and score.

#### 4. Time Synchronization (`TIME,...`)
Written by `settings.html` to calibrate the onboard DS1302 RTC:
```
"TIME,14:35:00"
```

---

## 🔌 Hardware Wiring & Pinout

### 1. LED Chain Routing (136 LEDs Total)
One continuous data line connects all modules in series:

```
ESP32 DIN (GPIO 2) ──> [ Digit 0 ] ──> [ Digit 1 ] ──> [ Games & Sets ] ──> [ Digit 2 ] ──> [ Digit 3 ]
                       (28 LEDs)       (28 LEDs)       (24 LEDs)            (28 LEDs)       (28 LEDs)
                       LEDs 0..27      LEDs 28..55     LEDs 56..79          LEDs 80..107    LEDs 108..135
                       Team 1 Tens     Team 1 Ones     Middle Module        Team 2 Tens     Team 2 Ones
```

### 2. Segment Wiring per Digit (4 LEDs $\times$ 7 segments = 28 LEDs)
* **Standard Digits (Digits 1, 2, 3):**
  * Segment 0 (BL - Bottom-Left): LEDs `0..3`
  * Segment 1 (B  - Bottom): LEDs `4..7`
  * Segment 2 (BR - Bottom-Right): LEDs `8..11`
  * Segment 3 (M  - Middle): LEDs `12..15`
  * Segment 4 (TL - Top-Left): LEDs `16..19`
  * Segment 5 (T  - Top): LEDs `20..23`
  * Segment 6 (TR - Top-Right): LEDs `24..27`
* **Digit 0 Hardware Variation (`PANEL0_CUSTOM_WIRING`):**
  * Handled automatically in firmware mapping (`panel0SegmentMap`): Slot 0=`TR`, Slot 1=`T`, Slot 2=`TL`, Slot 3=`M`, Slot 4=`BR`, Slot 5=`B`, Slot 6=`BL`.

### 3. Games & Sets Indicator Module (LEDs 56..79)
* **Left Column (Team 1 Blue, bottom to top):**
  * LEDs 56..64 (Indices 0..8): Games G1..G9
  * LED 65 (Index 9): Blank spacer
  * LEDs 66..67 (Indices 10..11): Sets S1..S2
* **Right Column (Team 2 Red, top to bottom):**
  * LEDs 68..69 (Indices 12..13): Sets S2 (top) & S1 (lower)
  * LED 70 (Index 14): Blank spacer
  * LEDs 71..79 (Indices 15..23): Games G9 down to G1

### 4. Microcontroller Pinout Table

| Function | ESP32-C3 SuperMini *(Recommended)* | Waveshare ESP32-S3 Zero |
| :--- | :---: | :---: |
| **WS2812 DIN Data Pin** | **`GPIO 2`** (Hardware SPI MOSI) | **`GPIO 15`** |
| **Status LED** | `GPIO 8` (Active LOW) | `GPIO 21` (WS2812 RGB) |
| **Mode / Boot Button** | `GPIO 9` | `GPIO 0` |
| **RTC DS1302 CLK (SCLK)** | `GPIO 4` | `GPIO 4` |
| **RTC DS1302 DAT (I/O)** | `GPIO 5` | `GPIO 5` |
| **RTC DS1302 RST (CE)** | `GPIO 3` | `GPIO 6` |

---

## ⚡ Building & Uploading (PlatformIO)

The project includes preconfigured environments in [`platformio.ini`](platformio.ini):

| Target Microcontroller | Firmware Feature Set | PlatformIO Environment |
| :--- | :--- | :--- |
| **ESP32-C3 SuperMini** | **Flagship (Sets & Match + Module)** | `esp32c3_supermini_button` |
| ESP32-C3 SuperMini | Unified 3-in-1 (Clock / Score / Remote) | `esp32c3_supermini_combined` |
| ESP32-C3 SuperMini | Standalone Clock | `esp32c3_supermini_clock` |
| **ESP32-S3 Zero** | Flagship (Sets & Match + Module) | `esp32s3_zero_button` |
| ESP32-S3 Zero | Unified 3-in-1 (Clock / Score / Remote) | `esp32s3_zero_combined` |

### CLI Build & Flash:
```powershell
# Build and upload flagship firmware to ESP32-C3 SuperMini
pio run -e esp32c3_supermini_button -t upload

# Monitor serial output at 115200 baud
pio device monitor -b 115200
```

---

## 🖨️ 3D Printing Assets (`/scad`)

All enclosure, digit, bracket, and mounting files are open-source OpenSCAD designs:
* `7segment.scad`: Modular snap-together 7-segment digit housings with integrated diffuser slots.
* `7segment_hinged_bracket.scad`: Heavy-duty hinged wall and court-fence brackets with locking pins.
* `remote_strap_holder.scad`: Ergonomic clip for wearing the Xiaomi Shutter remote on a wristband or racket lanyard.
* `games_sets_bracket.scad`: Middle module housing for the 24-LED column array.

---

## 👤 Author
**Geert Schepers**
