#include <Arduino.h>
#include <Adafruit_NeoPixel.h>
#include <NimBLEDevice.h>

// Configuration
#define PIN        15 // Change this to the data pin you are using on your ESP32-S2 Zero
// 4 digits * 7 segments * 4 LEDs = 112 LEDs
#define NUMPIXELS  112 

Adafruit_NeoPixel pixels(NUMPIXELS, PIN, NEO_GRB + NEO_KHZ800);

// BLE Configuration
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

std::string currentScore = "0000";
bool newScoreReceived = false;

// Segment order according to your diagram
const byte numbers[12][7] = {
  {1, 1, 1, 0, 1, 1, 1}, // 0
  {0, 0, 1, 0, 0, 0, 1}, // 1
  {0, 1, 1, 1, 1, 1, 0}, // 2
  {0, 1, 1, 1, 0, 1, 1}, // 3
  {1, 0, 1, 1, 0, 0, 1}, // 4
  {1, 1, 0, 1, 0, 1, 1}, // 5
  {1, 1, 0, 1, 1, 1, 1}, // 6
  {0, 1, 1, 0, 0, 0, 1}, // 7
  {1, 1, 1, 1, 1, 1, 1}, // 8
  {1, 1, 1, 1, 0, 1, 1}, // 9
  {0, 0, 0, 0, 0, 0, 0}, // 10: Blank
  {1, 1, 1, 1, 1, 0, 1}  // 11: 'A' for Advantage
};

const int segmentStartIndices[7] = {
  24, // Segment A
  20, // Segment B
  16, // Segment C
  12, // Segment D
  8,  // Segment E
  4,  // Segment F
  0   // Segment G
};

void displayScore(std::string score, bool swapped);

class MyCallbacks: public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic* pCharacteristic, NimBLEConnInfo& connInfo) override {
        std::string value = pCharacteristic->getValue();

        if (value.length() > 0) {
            currentScore = value;
            newScoreReceived = true;
            Serial.printf("Received new score: %s\n", currentScore.c_str());
        }
    }
};

bool triggerConnectAnimation = false;

class MyServerCallbacks: public NimBLEServerCallbacks {
    void onConnect(NimBLEServer* pServer) {
        Serial.println("Client connected");
        triggerConnectAnimation = true;
    }

    void onDisconnect(NimBLEServer* pServer) {
        Serial.println("Client disconnected. Restarting advertising...");
        NimBLEDevice::startAdvertising();
    }
};

void setup() {
  Serial.begin(115200); // Initialize serial communication for debugging

  pixels.begin();
  pixels.setBrightness(50);
  pixels.show();

  // Initialize BLE (Bluetooth Low Energy)
  // Set the device name that clients will see
  NimBLEDevice::init("Padel Display");
  
  // Create the BLE Server
  NimBLEServer* pServer = NimBLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  
  // Create the BLE Service using the predefined UUID
  NimBLEService* pService = pServer->createService(SERVICE_UUID);
  NimBLECharacteristic* pCharacteristic = pService->createCharacteristic(
                                         CHARACTERISTIC_UUID,
                                         NIMBLE_PROPERTY::WRITE | 
                                         NIMBLE_PROPERTY::WRITE_NR |
                                         NIMBLE_PROPERTY::READ
                                       );
  pCharacteristic->setCallbacks(new MyCallbacks());
  pCharacteristic->setValue("0000");
  
  // Start the service
  pService->start();
  
  // Start the server
  pServer->start();
  
  NimBLEAdvertising* pAdvertising = NimBLEDevice::getAdvertising();
  pAdvertising->setName("Padel Display");
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->start();
  
  Serial.println("BLE Server started. Waiting for connections...");
  
  // Display initial score
  displayScore(currentScore, false);
}

bool isSwitched = false;

void displayScore(std::string score, bool swapped);

void animateSwap() {
  // Simple wipe effect: turn off LEDs one by one sequentially
  for (int i = 0; i < NUMPIXELS; i++) {
    pixels.setPixelColor(i, 0); // Turn off current pixel
    pixels.show();              // Apply change
    delay(2);                   // Small delay for visual effect
  }
  delay(100); // Short pause before the new score appears on the display
}

void loop() {
  if (triggerConnectAnimation) {
    triggerConnectAnimation = false;
    // Flash all blue 3 times
    for(int j = 0; j < 3; j++) {
      for(int i = 0; i < NUMPIXELS; i++) {
        pixels.setPixelColor(i, pixels.Color(0, 0, 255));
      }
      pixels.show();
      delay(150);
      pixels.clear();
      pixels.show();
      delay(150);
    }
    // Restore the score after flashing
    displayScore(currentScore, isSwitched);
  }

  if (newScoreReceived) {
    newScoreReceived = false; // Reset the flag
    
    std::string scoreStr = "0000";
    bool newIsSwitched = isSwitched;
    
    // Parse the received score string. Expected format: "SCORE,SWITCH_FLAG"
    // e.g., "1530,1" meaning score is 15-30 and sides are switched
    size_t commaPos = currentScore.find(',');
    if (commaPos != std::string::npos) {
      scoreStr = currentScore.substr(0, commaPos); // Extract the score part
      std::string flag = currentScore.substr(commaPos + 1); // Extract the flag
      newIsSwitched = (flag == "1"); // Flag "1" means sides are switched
    } else {
      scoreStr = currentScore; // fallback if no comma/flag is present
    }
    
    // If we detect a switch in sides, trigger the swap animation
    if (newIsSwitched != isSwitched) {
      animateSwap();
      isSwitched = newIsSwitched;
    }
    
    // Update the display with the new score and switch state
    displayScore(scoreStr, isSwitched);
  }
  
  delay(10);
}

void displayScore(std::string score, bool swapped) {
  pixels.clear(); // Turn off all LEDs before drawing the new score
  
  // Define team colors
  uint32_t colorRed = pixels.Color(255, 0, 0);
  uint32_t colorBlue = pixels.Color(0, 0, 255);
  
  // TESTING OVERRIDE: 
  // We currently only render the 2nd digit (index 1 of the string) 
  // to the physical LEDs 0-27 (the single 7-segment display).
  if (score.length() > 1) {
    int d = 1; // 2nd digit
    char c = score[d];
    int numIndex = 10; // Default to blank
    
    if (c >= '0' && c <= '9') {
      numIndex = c - '0';
    } else if (c == 'A' || c == 'a') {
      numIndex = 11; // Advantage
    }
    
    // Left side (digits 0 and 1) gets one color, right side (digits 2 and 3) gets the other
    uint32_t digitColor;
    if (!swapped) {
        digitColor = (d < 2) ? colorBlue : colorRed;
    } else {
        digitColor = (d < 2) ? colorRed : colorBlue;
    }
    
    // Force offset to 0 so it renders on the single physical 7-segment display
    int digitOffset = 0;
    
    for (int segment = 0; segment < 7; segment++) {
      if (numbers[numIndex][segment] == 1) {
        int startPixel = digitOffset + segmentStartIndices[segment];
        for (int i = 0; i < 4; i++) {
          pixels.setPixelColor(startPixel + i, digitColor);
        }
      }
    }
  }
  
  pixels.show();  
}
