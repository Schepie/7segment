import os
import glob
import re

Import("env")

# Patch Adafruit_NeoPixel esp.c with correct WS2812 T0H timing (300ns instead of 400ns)
# 400ns causes zeros to be decoded as ones (green glitch) on ESP32-C3 under bus capacitance
def patch_neopixel_esp(source, target, env):
    libdeps_dir = env.subst("$PROJECT_LIBDEPS_DIR")
    for path in glob.glob(os.path.join(libdeps_dir, "**", "esp.c"), recursive=True):
        try:
            with open(path, "r") as f:
                content = f.read()
            changed = False

            # 1. Patch ESP-IDF 5 RMT timing (duration0=3 for 300ns, duration1=9 for 900ns)
            # Adafruit default has duration0 = 4 (400ns), which violates WS2812 T0H max (380ns)
            pattern_idf5 = re.compile(
                r"(\}\s*else\s*\{\s*led_data\[i\]\.level0\s*=\s*1;\s*led_data\[i\]\.duration0\s*=)\s*4;(\s*led_data\[i\]\.level1\s*=\s*0;\s*led_data\[i\]\.duration1\s*=)\s*8;"
            )
            if pattern_idf5.search(content):
                content = pattern_idf5.sub(r"\g<1> 3;\g<2> 9;", content)
                changed = True
                print(f"[PATCH] Adjusted ESP-IDF 5 WS2812 T0H timing to 300ns in {path}")

            # 2. Patch Legacy ESP-IDF 3/4 macros
            if "#define WS2812_T0H_NS (400)" in content:
                content = content.replace("#define WS2812_T0H_NS (400)", "#define WS2812_T0H_NS (300)")
                content = content.replace("#define WS2812_T0L_NS (850)", "#define WS2812_T0L_NS (950)")
                content = content.replace("#define WS2812_T1H_NS (800)", "#define WS2812_T1H_NS (750)")
                content = content.replace("#define WS2812_T1L_NS (450)", "#define WS2812_T1L_NS (500)")
                changed = True
                print(f"[PATCH] Adjusted Legacy WS2812 timing macros in {path}")

            # 3. Add drive strength configuration to RMT pin in espShow
            if "rmtPin = pin;" in content and "gpio_set_drive_capability" not in content:
                content = content.replace("rmtPin = pin;", "gpio_set_drive_capability((gpio_num_t)pin, GPIO_DRIVE_CAP_3);\n        rmtPin = pin;")
                changed = True
                print(f"[PATCH] Added GPIO_DRIVE_CAP_3 to RMT pin in {path}")

            if changed:
                with open(path, "w") as f:
                    f.write(content)
        except Exception as e:
            print(f"[PATCH] Error checking {path}: {e}")

patch_neopixel_esp(None, None, env)
