# 🎾 Development of the 7-Segment Padel Scoreboard & Apps Ecosystem
## Engineering Presentation & Slide Notes

> **Interactive Presentation Deck:** Open [`presentation.html`](presentation.html) in any modern browser for full-screen slide transitions, keyboard controls (`←`/`→`/`Space`), speaker notes (`N`), slide overview grid (`O`), and an embedded interactive score simulator.

---

### Slide 1: System Architecture & Vision
**Title:** ESP32 7-Segment Padel Scoreboard & Digital Clock  
**Category:** System Architecture & Vision

- **The Problem:** Padel rallies are fast-paced, high-intensity, and often result in disputes over points, games, and court side swaps. Existing commercial scoreboards are bulky, fragile, expensive ($500+), or require manual turning.
- **The Solution:** A high-visibility 136-LED scoreboard built with **WS2813 addressable LEDs** (featuring a dual-signal backup data line to prevent cascade dropouts), where the **ESP32 microcontroller is always the Master** and single source of truth. Dual-role Bluetooth Low Energy (BLE) connects directly to an on-racket Xiaomi clicker, Wear OS smartwatches, and a zero-install mobile web controller.
- **Dual Mode:** When idle for a configurable period (e.g., 5 minutes), the display smoothly crossfades into an ambient 24-hour digital wall clock driven by a DS1302 RTC chip.

---

### Slide 2: Phase 1 — Mechanical & 3D CAD Engineering (OpenSCAD)
**Title:** Modular OpenSCAD Parametric Design  
**Category:** Phase 1 • Mechanical Engineering

- **Parametric 7-Segment Digit Housings (`7segment_pogo.scad`):**
  - Light-isolation diffuser channels preventing light bleed between adjacent segments.
  - 4 LEDs per segment (28 LEDs per digit), perfectly scaled for 20+ meter court visibility.
  - Pogo-pin and magnetic side pockets enabling solderless daisy chaining.
- **Central Games & Sets Module (`games_sets_pogo_snap_individual_dots.scad`):**
  - 24 addressable LEDs in a dual-column vertical ladder.
  - Left column: Team 1 (Blue) Games 1–9 + Sets 1–2.
  - Right column: Team 2 (Red) Sets 1–2 + Games 9–1.
- **The Padel Court Mesh Hook Bracket (`panel_seam_u_hook_bracket.scad`):**
  - **Ball Impact Engineering:** Rather than hanging the display inside the court where smash balls hit at 120+ km/h, the U-profile hook suspends the scoreboard *safely behind* the court's 50x50 mm steel wire fence.
  - The fence wire absorbs all impact kinetic energy while the LEDs shine through the wire openings.
- **Desktop 8° Tilt Cradle Stand (`display_stand.scad`):**
  - Dual M3 direct-mount pass-through bolting directly into panel backplate brass inserts, eliminating joint flex.

---

### Slide 3: Phase 2 — Electronics, Wiring & Power Topologies
**Title:** LED Serial Bus & Microcontroller Hardware  
**Category:** Phase 2 • Electronics & Power Topologies

- **Continuous 136-LED Serial Data Stream:**
  ```
  ESP32 DIN (GPIO 2) ──> [ Digit 0 ] ──> [ Digit 1 ] ──> [ Games & Sets ] ──> [ Digit 2 ] ──> [ Digit 3 ]
                         (28 LEDs)       (28 LEDs)       (24 LEDs)            (28 LEDs)       (28 LEDs)
  ```
- **Microcontroller Pinout (ESP32-C3 SuperMini):**
  - Hardware SPI MOSI on `GPIO 2`, status LED on `GPIO 8`, DS1302 RTC on `GPIO 4 / 5 / 3`.
- **Panel 0 Custom Segment Translation (`panel0SegmentMap`):**
  - Mechanical symmetry required reversing the ribbon connector on Digit 0. Firmware remaps the hardware order to logical segments in constant time.
- **DS1302 Real-Time Clock:**
  - Onboard coin-cell backup ensures accurate timekeeping across court power interruptions.

---

### Slide 4: Phase 3 — The Critical Firmware Breakthrough: Hardware SPI DMA vs. BLE
**Title:** The Critical Breakthrough: Hardware SPI DMA vs. BLE  
**Category:** Phase 3 • Embedded Firmware Engineering

- **The Real-World Failure (Neopixel Bit-Banging):**
  - Standard libraries (Adafruit NeoPixel) use cycle-counted software loops to generate the 800 kHz LED waveform.
  - In our dual-role architecture, the ESP32 BLE radio generates frequent high-priority hardware interrupts.
  - **Symptom:** High BLE transmission rates corrupted the bit-bang timing, causing random flashes, color tearing, and dropped frames.
- **The Engineering Solution (Hardware SPI DMA):**
  - Replaced bit-banging with the **ESP32-C3 Hardware SPI MOSI peripheral with Direct Memory Access (DMA)**.
  - WS2813 bits are converted into a DMA bit buffer and transferred to `GPIO 2` by hardware silicon.
  - **Zero CPU overhead and 100% immunity to BLE interrupts**, delivering flicker-free LED animations.
- **Why WS2813 & Reset Pulse Compensation:**
  - **Dual-Signal Line:** WS2813 features a backup data line (`BIN`), ensuring that if any single LED fails, the signal bypasses it without breaking the rest of the display.
  - **Reset Timing:** WS2813 chips require a >280 µs reset pulse (compared to 50 µs on older LEDs). We padded the DMA transmission frame with trailing zeros to guarantee clean frame latching.

---

### Slide 5: Phase 4 — Master Rules Engine & State Machine
**Title:** The Scoreboard is Always the Master  
**Category:** Phase 4 • Embedded Logic & Rules Engine

- **The Master/Slave Model:**
  - All match rules, points, games, sets, and side swaps are computed exclusively on the ESP32.
  - Clients (Wear OS watches, web apps) are pure displays and control inputs. They cannot overwrite rules during play.
- **Official Padel Logic:**
  - Golden Point (*Punto de Oro*) vs. Advantage (`Ad`).
  - Sets to win (1 or 2; best of 3).
  - Games per set (6 or 9).
  - Tiebreak mode at 6–6 (or 8–8) with white `tb` and `Stb` (Super Tiebreak) badges.
- **30-Step Historical Undo Stack:**
  - Every point change pushes full match state onto a circular ring buffer.
  - Double-clicking either button on the remote or tapping Undo instantly reverts erroneous points.
- **Non-Volatile Storage (NVS Flash):**
  - Rules, brightness, idle timeouts, and paired remote MAC addresses persist across power cycles.

---

### Slide 6: Phase 5 — Dual-Role BLE & Protocol Specification
**Title:** Dual-Role BLE Architecture & GATT Protocol  
**Category:** Phase 5 • Wireless Networking

- **Dual-Role Operation (NimBLE-Arduino):**
  - **BLE Central:** Scans and connects to the Xiaomi / YI Shutter Remote (XYLY01) over HID Service `0x1812`.
  - **BLE Peripheral:** Advertises GATT Server `"Padel Display"` (UUID `0x4FAF`), handling connections from watches and web browsers.
- **Remote Button Mapping (XYLY01):**
  - Single Click Top Button (`0x40`): Team 1 (+1 Point)
  - Single Click Bottom Button (`0x80`): Team 2 (+1 Point)
  - Double Click (within 380 ms): Undo previous point
- **GATT Protocol (Characteristic `0xBEB5`):**
  - `SCORE,...`: Live scores notification (`"1530,0,1,2,0,0,0"`).
  - `CFG,...`: Configuration broadcast (`"CFG,GP=0,SETS=2,GAMES=6,TB=1,BRT=180,IDLE=300000"`).
  - `CMD,...`: Remote control commands (`CMD,P1`, `CMD,P2`, `CMD,UNDO`, `CMD,RESET`, `CMD,SWAP`, `CMD,CLOCK`).
  - `TIME,...`: Clock synchronization (`"TIME,14:35:00"`).

---

### Slide 7: Phase 6 — Mobile Web Controller PWA (`index.html`)
**Title:** Zero-Install Mobile Controller PWA  
**Category:** Phase 6 • Companion Web Application

- **Web Bluetooth API:**
  - Directly pairs with the ESP32 from Chrome, Edge, and iOS Bluefy without App Store or Play Store friction.
- **Three Core Tabs:**
  1. **Court Tab:** Live mirrored digits, large tactile score buttons, side swap, undo, and mode switch.
  2. **Display Tab:** Debounced brightness slider (0–255), auto-idle sleep timeout selector, and one-tap **Sync Phone Time**.
  3. **Rules Tab:** Configure Golden Point, sets, games, and tiebreak presets.
- **PWA Capabilities:**
  - Offline Service Worker (`sw.js`), Apple touch icons, and dark/light mode themes with instant anti-flash localStorage initialization.
- **BLE Write Debouncing:**
  - A 60 ms animation-frame throttle queue prevents rapid slider gestures from congesting the BLE connection.

---

### Slide 8: Phase 7 — Wear OS Companion & Spectator Ecosystem
**Title:** Wear OS Smartwatch & Spectator Web App  
**Category:** Phase 7 • Wearables & Cloud Spectators

- **Wear OS Smartwatch Companion:**
  - Designed for players preferring wrist scoring over racket remotes.
  - Touch interface with distinct haptic vibration pulses for points, game points, and set wins.
  - Queries master rules via `CMD,REQ` on connection.
- **Spectator Web Observer (`padelpunten.netlify.app`):**
  - External web app allowing clubhouse spectators to monitor ongoing matches via lightweight REST synchronization.
- **Unified Team Color Standard:**
  - Team 1: Electric Blue (`#00d2ff` / `RGB(0, 180, 255)`)
  - Team 2: Vivid Red (`#ff3366` / `RGB(255, 0, 0)`)
  - Sets & Ladder: Amber Gold (`#ffb300` / `RGB(255, 180, 0)`)

---

### Slide 9: Phase 8 — Wireless Browser-Based OTA Firmware Updates
**Title:** Wireless Browser-Based OTA Updates  
**Category:** Phase 8 • Maintenance & Field Deployments

- **The Problem:** Scoreboards mounted high on court walls or behind wire cages cannot be easily cabled via USB to a laptop.
- **The Solution:** A dedicated browser flasher (`ota.html`) communicating over Web Bluetooth.
- **Engineering Features:**
  - 512-byte chunked MTU packet slicing.
  - Dual ESP32 OTA partitions (`ota_0`, `ota_1`) with automated CRC validation and rollback protection.
  - Python CLI companion script (`scripts/ble_ota_flash.py`) for automated CI/CD flashing.

---

### Slide 10: Phase 9 — Interactive Showcase & Commercial Simulator
**Title:** Interactive Web Simulator & Showcase  
**Category:** Phase 9 • Commercialization & Virtual Testing

- **Purpose:** Prior to mass 3D printing and hardware assembly, `showcase.html` provided an interactive virtual playground.
- **Virtual Scoreboard & Racket Remote:**
  - Fully animated 7-segment digits, 24-LED ladder, and virtual clicker simulating single and double-click actions.
- **Market & Pricing Survey:**
  - Embedded feedback widget gathering player and court club feedback on DIY kits, pre-assembled packages, and price points.

---

### Slide 11: Phase 10 — Real-World Testing & Key Engineering Iterations
**Title:** Real-World Engineering Iterations  
**Category:** Phase 10 • Git History & Field Iterations

1. **Court Side Swap Inversion (`85f3d6f`):** Fixed bug where touch targets inverted relative to physical display orientation during end swaps.
2. **Tiebreak Badging (`067e33a`):** Added white `tb` and `Stb` badges so players know when points count rallies (1..7) instead of normal tennis points.
3. **Brightness Slider Flooding (`985b6fd`):** Debounced slider events to eliminate watchdog timeouts during rapid dragging.
4. **Ambient Clock Crossfading (`f2769cf`):** Added smooth 6-second color crossfade transitions for clubhouse clock mode.
5. **Racket Strap Mount (`285b92c`):** Created 3D printable racket lanyard and wrist strap holders to prevent clicker drops.
6. **Snap-Fit 3D Print Tolerances (`cbdffa0`):** Tuned 0.25 mm bead interferences for support-free diffuser snap-fitting.

---

### Slide 12: Architecture Summary & Future Roadmap
**Title:** Architecture Summary & Future Roadmap  
**Category:** Conclusion & Future Vision

- **Multidisciplinary Synergy:**
  - **Mechanical:** OpenSCAD parametric design, mesh hook protection, cradle stand.
  - **Embedded:** ESP32 C++, Hardware SPI DMA, NimBLE dual-role.
  - **Web Applications:** Web Bluetooth API, Service Worker PWA, OTA updates.
- **Future Roadmap:**
  - **ESP-NOW Court Mesh:** Interconnecting all court scoreboards to a master clubhouse tournament board.
  - **Voice-Activated Scoring:** Offline keyword spotting for hands-free scoring (*"Point Blue"*).
  - **Automated Video Highlights:** Remote double-click triggering timestamp bookmarks on court IP cameras.

---

## 🛠️ How to Present
- **To present directly in browser:** Open [`presentation.html`](presentation.html) and press `F` for Fullscreen.
- **To view speaker notes:** Press `N` to open the notes drawer.
- **To view slide thumbnail grid:** Press `O` or click the Overview button.
- **To print/export to PDF:** Use `Ctrl + P` (or `Cmd + P` on Mac) and choose "Save as PDF" — the stylesheet includes dedicated `@media print` rules for clean slide-per-page rendering.
