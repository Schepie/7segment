#include <Arduino.h>
#include <Adafruit_NeoPixel.h>

// =========================================================================
// Configuration
// =========================================================================
#define PIN               2   // GPIO pin connected to WS2812 data line (ESP32-C3: GPIO 2)
#define LEDS_PER_SEGMENT  4   // Number of WS2812 LEDs in each segment
#define NUM_SEGMENTS      3   // Number of segments to cycle through (1 to 7)
#define ACTIVE_SEGMENTS   3   // Number of segments lit up at the same time (1 to 7)
#define NUMPIXELS         112 // Total LEDs on strip (supports 1, 2, or 4 digits; unused stay OFF)
#define BRIGHTNESS        255 // Maximum brightness (0 - 255)
#define COLOR_HOLD_MS     2000 // 2 seconds per color

Adafruit_NeoPixel pixels(NUMPIXELS, PIN, NEO_GRB + NEO_KHZ800);

// =========================================================================
// Segment Definitions & Descriptions
// =========================================================================
struct SegmentInfo {
  const char* name;
  const char* position;
  int startLed;
};

// Full 7-segment layout based on physical wiring (0=A, 1=B, ..., 6=G)
const SegmentInfo segments[] = {
  {"Segment A", "Top-Left",     0 * LEDS_PER_SEGMENT},
  {"Segment B", "Top",          1 * LEDS_PER_SEGMENT},
  {"Segment C", "Top-Right",    2 * LEDS_PER_SEGMENT},
  {"Segment D", "Middle",       3 * LEDS_PER_SEGMENT},
  {"Segment E", "Bottom-Left",  4 * LEDS_PER_SEGMENT},
  {"Segment F", "Bottom",       5 * LEDS_PER_SEGMENT},
  {"Segment G", "Bottom-Right", 6 * LEDS_PER_SEGMENT}
};

const int TOTAL_AVAILABLE_SEGMENTS = sizeof(segments) / sizeof(segments[0]);

// =========================================================================
// Color Definitions
// Order: Green -> Red -> Blue -> Orange -> Yellow -> White
// =========================================================================
struct ColorItem {
  const char* name;
  uint8_t r;
  uint8_t g;
  uint8_t b;
};

const ColorItem colors[] = {
  {"Green",   0,   255, 0  },
  {"Red",     255, 0,   0  },
  {"Blue",    0,   0,   255},
  {"Orange",  255, 100, 0  },
  {"Yellow",  255, 230, 0  },
  {"White",   255, 255, 255}
};

const int NUM_COLORS = sizeof(colors) / sizeof(colors[0]);

unsigned long cycleCounter = 0;

void setup() {
  Serial.begin(115200);
  pixels.begin();
  pixels.setBrightness(BRIGHTNESS);
  pixels.clear();
  pixels.show();

  delay(1000); // Small pause for USB CDC Serial to attach

  Serial.println("\n=======================================================");
  Serial.println("   7-Segment Multi-Segment Color Cycle Program         ");
  Serial.println("=======================================================");
  Serial.printf("Cycling across %d segments, %d active simultaneously (Brightness: %d/255).\n", 
                NUM_SEGMENTS, ACTIVE_SEGMENTS, BRIGHTNESS);
  Serial.println("Color sequence (2s each): Green -> Red -> Blue -> Orange -> Yellow -> White");
  Serial.println("Cycles continuously until power off.");
  Serial.println("=======================================================\n");
}

void loop() {
  cycleCounter++;
  Serial.printf("\n--- Starting Full Cycle #%lu ---\n", cycleCounter);

  int maxSegments = (NUM_SEGMENTS > TOTAL_AVAILABLE_SEGMENTS) ? TOTAL_AVAILABLE_SEGMENTS : NUM_SEGMENTS;
  int activeCount = (ACTIVE_SEGMENTS > TOTAL_AVAILABLE_SEGMENTS) ? TOTAL_AVAILABLE_SEGMENTS : ACTIVE_SEGMENTS;

  // Iterate across segments
  for (int segIdx = 0; segIdx < maxSegments; segIdx++) {
    Serial.printf("\n>>> Active Segments: ");
    for (int a = 0; a < activeCount; a++) {
      int cur = (segIdx + a) % maxSegments;
      Serial.printf("%s (%s)%s", segments[cur].name, segments[cur].position, (a < activeCount - 1) ? ", " : " <<<\n");
    }

    // Toggle through each color for 2 seconds on all active segments
    for (int colIdx = 0; colIdx < NUM_COLORS; colIdx++) {
      const ColorItem& col = colors[colIdx];

      Serial.printf("  -> Color [%d/%d]: %-7s | RGB(%3d, %3d, %3d) for 2s\n",
                    colIdx + 1, NUM_COLORS, col.name, col.r, col.g, col.b);

      // Turn off all LEDs first
      pixels.clear();

      // Light up all active segments
      uint32_t activeColor = pixels.Color(col.r, col.g, col.b);
      for (int a = 0; a < activeCount; a++) {
        int cur = (segIdx + a) % maxSegments;
        for (int i = 0; i < LEDS_PER_SEGMENT; i++) {
          pixels.setPixelColor(segments[cur].startLed + i, activeColor);
        }
      }

      pixels.show();

      // Hold this color for 2 seconds (2000 ms)
      delay(COLOR_HOLD_MS);
    }
  }

  // Turn off display briefly before repeating the cycle
  pixels.clear();
  pixels.show();
}
