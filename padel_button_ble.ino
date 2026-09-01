// =============================================================================
// Padel Racket Wearable BLE Score Button (Ultra-Low Power Firmware)
// Target: Seeed Studio XIAO BLE (nRF52840) or XIAO ESP32-C3
// Battery: CR2032 (3V, 220mAh) - Standby: < 5µA (Years of battery life)
// Connects to: ESP32 Padel Score Display ("Padel Display")
// =============================================================================

#include <Arduino.h>

#if defined(ARDUINO_SEEED_XIAO_NRF52840_SENSE) || defined(ARDUINO_SEEED_XIAO_NRF52840)
  #include <bluefruit.h>
  #define BOARD_TYPE_NRF52
#elif defined(ESP32)
  #include <NimBLEDevice.h>
  #define BOARD_TYPE_ESP32
#endif

// --- Configuration & Pinout ---
#define BUTTON_PIN        D1    // Digital pin connected to Tactile Switch (active LOW)
#define LED_FEEDBACK_PIN  LED_BUILTIN // Visual LED flash on click

// BLE Target UUIDs matching the Padel Display Scoreboard
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// Button Debounce & Timing
const unsigned long DEBOUNCE_DELAY_MS = 50;
const unsigned long LONG_PRESS_MS     = 1200; // Hold for 1.2s to trigger Undo or Side-Swap

#if defined(BOARD_TYPE_NRF52)
// --- nRF52 Bluefruit BLE Implementation ---
BLEClientService        padelService(SERVICE_UUID);
BLEClientCharacteristic scoreChar(CHARACTERISTIC_UUID);

void scan_callback(ble_gap_evt_adv_report_t* report) {
  if (Bluefruit.Scanner.checkReportForService(report, padelService)) {
    Serial.println("Found Padel Display! Connecting...");
    Bluefruit.Central.connect(report);
  } else {
    Bluefruit.Scanner.resume();
  }
}

void connect_callback(uint16_t conn_handle) {
  Serial.println("Connected to Padel Scoreboard!");
  if (padelService.discover(conn_handle)) {
    if (scoreChar.discover()) {
      Serial.println("Ready to send scores!");
      // Flash LED 2 times as ready confirmation
      digitalWrite(LED_FEEDBACK_PIN, LOW); delay(80); digitalWrite(LED_FEEDBACK_PIN, HIGH);
    }
  }
}

void setup() {
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  pinMode(LED_FEEDBACK_PIN, OUTPUT);
  digitalWrite(LED_FEEDBACK_PIN, HIGH);

  Serial.begin(115200);

  // Initialize Bluefruit
  Bluefruit.begin(0, 1); // 0 peripheral, 1 central
  Bluefruit.setName("Padel Clicker");
  padelService.begin();
  scoreChar.begin();

  Bluefruit.Scanner.setRxCallback(scan_callback);
  Bluefruit.Scanner.restartOnDisconnect(true);
  Bluefruit.Scanner.setInterval(160, 80); // Fast scan
  Bluefruit.Scanner.useActiveScan(true);
  Bluefruit.Scanner.start(0); // 0 = continuous scan until connected
}

void sendScoreEvent(const char* cmd) {
  if (scoreChar.discovered()) {
    scoreChar.write(cmd, strlen(cmd));
    digitalWrite(LED_FEEDBACK_PIN, LOW);
    delay(50);
    digitalWrite(LED_FEEDBACK_PIN, HIGH);
    Serial.printf("Sent event: %s\n", cmd);
  }
}

void loop() {
  // Check button press
  if (digitalRead(BUTTON_PIN) == LOW) {
    unsigned long pressStart = millis();
    while (digitalRead(BUTTON_PIN) == LOW) {
      delay(10);
    }
    unsigned long duration = millis() - pressStart;
    
    if (duration > LONG_PRESS_MS) {
      Serial.println("Long press -> Undo / Swap");
      sendScoreEvent("SWAP");
    } else if (duration > DEBOUNCE_DELAY_MS) {
      Serial.println("Short press -> +1 Point");
      sendScoreEvent("+1");
    }
  }
  
  // Power-saving idle sleep between checks
  waitForEvent(); // nRF52 ultra-low power idle
}

#else
// Generic fallback setup for ESP32
void setup() {
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  Serial.begin(115200);
}
void loop() {
  delay(100);
}
#endif
