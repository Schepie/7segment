#include <Adafruit_NeoPixel.h>

// Configuration
#define PIN        15 // Change this to the data pin you are using on your ESP32-S2 Zero
#define NUMPIXELS  28 // 7 segments * 4 LEDs per segment = 28 LEDs

Adafruit_NeoPixel pixels(NUMPIXELS, PIN, NEO_GRB + NEO_KHZ800);

// Segment order according to your diagram:
// 0: A (Top-Left)
// 1: B (Top)
// 2: C (Top-Right)
// 3: D (Middle)
// 4: E (Bottom-Left)
// 5: F (Bottom)
// 6: G (Bottom-Right)

// This array defines which segments to turn on for numbers 0-9.
// 1 means segment is ON, 0 means segment is OFF.
// Order: A, B, C, D, E, F, G
const byte numbers[10][7] = {
  {1, 1, 1, 0, 1, 1, 1}, // 0
  {0, 0, 1, 0, 0, 0, 1}, // 1
  {0, 1, 1, 1, 1, 1, 0}, // 2
  {0, 1, 1, 1, 0, 1, 1}, // 3
  {1, 0, 1, 1, 0, 0, 1}, // 4
  {1, 1, 0, 1, 0, 1, 1}, // 5
  {1, 1, 0, 1, 1, 1, 1}, // 6
  {0, 1, 1, 0, 0, 0, 1}, // 7
  {1, 1, 1, 1, 1, 1, 1}, // 8
  {1, 1, 1, 1, 0, 1, 1}  // 9
};

// This array maps our logical segment index (0=A, 1=B, ..., 6=G) 
// to the starting LED index for that segment.
// IMPORTANT: This assumes your data line is wired sequentially:
// A -> B -> C -> D -> E -> F -> G
// If you wired them in a different order, simply change these starting indices!
const int segmentStartIndices[7] = {
  0,  // Segment A (Top-Left) starts at LED 0
  4,  // Segment B (Top) starts at LED 4
  8,  // Segment C (Top-Right) starts at LED 8
  12, // Segment D (Middle) starts at LED 12
  16, // Segment E (Bottom-Left) starts at LED 16
  20, // Segment F (Bottom) starts at LED 20
  24  // Segment G (Bottom-Right) starts at LED 24
};

void setup() {
  pixels.begin();
  pixels.setBrightness(50); // Set a safe brightness (0-255) so it doesn't draw too much power
  pixels.show();            // Initialize all pixels to 'off'
}

void loop() {
  // Loop from 0 to 9 infinitely
  for (int num = 0; num <= 9; num++) {
    displayNumber(num);
    delay(1000); // Wait 1 second between numbers
  }
}

void displayNumber(int num) {
  pixels.clear(); // Turn off all pixels first

  // Set the color for the digit (Red in this case)
  // Format: pixels.Color(Red, Green, Blue)
  uint32_t color = pixels.Color(255, 0, 0); 
  
  // Loop through each of the 7 segments
  for (int segment = 0; segment < 7; segment++) {
    // If the segment should be ON for the current number
    if (numbers[num][segment] == 1) {
      
      // Get where this segment starts in the LED strip
      int startPixel = segmentStartIndices[segment];
      
      // Turn on the 4 LEDs for this segment
      for (int i = 0; i < 4; i++) {
        pixels.setPixelColor(startPixel + i, color);
      }
    }
  }
  
  pixels.show(); // Update the display with the new data
}
