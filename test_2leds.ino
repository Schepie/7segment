#include <Adafruit_NeoPixel.h>

// Configuration
#define PIN        2   // GPIO pin connected to the WS2812 data line
#define NUMPIXELS  2   // Only steer 2 LEDs

Adafruit_NeoPixel pixels(NUMPIXELS, PIN, NEO_GRB + NEO_KHZ800);

// Color structure
struct ColorItem {
  const char* name;
  const char* description;
  uint8_t r;
  uint8_t g;
  uint8_t b;
};

// High visibility daylight colors
const ColorItem colors[] = {
  {"Geel-groen",   "~555 nm (Piek ooggevoeligheid)",        180, 255,   0},
  {"Helder groen", "~520-540 nm (Hoge helderheid)",           0, 255,   0},
  {"Rood-oranje",  "~590-620 nm (Hoog omgevingscontrast)",  255,  60,   0},
  {"Koud wit",     "~6500K (Volledig spectrum)",            255, 255, 255}
};

const int NUM_COLORS = sizeof(colors) / sizeof(colors[0]);

void setup() {
  Serial.begin(115200);
  pixels.begin();
  pixels.setBrightness(255); // 100% Helderheid
  pixels.clear();
  pixels.show();

  Serial.println("=========================================================");
  Serial.println("   2-LED Daglicht-Zichtbaarheidstest (100% Helderheid)   ");
  Serial.println("   4s AAN -> 2s UIT tussen de kleuren                    ");
  Serial.println("=========================================================");
}

void loop() {
  for (int c = 0; c < NUM_COLORS; c++) {
    Serial.print("\n[AAN] Kleur: ");
    Serial.print(colors[c].name);
    Serial.print(" | ");
    Serial.println(colors[c].description);

    // Zet beide LEDs aan in de gekozen kleur (4 seconden)
    for (int i = 0; i < NUMPIXELS; i++) {
      pixels.setPixelColor(i, pixels.Color(colors[c].r, colors[c].g, colors[c].b));
    }
    pixels.show();
    delay(4000);

    // 2 seconden UIT tussen de kleuren
    Serial.println("[UIT] LEDs 2s uitgeschakeld...");
    pixels.clear();
    pixels.show();
    delay(2000);
  }
}
