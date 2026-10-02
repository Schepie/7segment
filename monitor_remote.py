import serial
import time
import sys

try:
    ser = serial.Serial('COM12', 115200, timeout=0.1)
    # Trigger reset on ESP32-C3
    ser.setDTR(False)
    ser.setRTS(True)
    time.sleep(0.1)
    ser.setRTS(False)
    ser.setDTR(True)
    print("Reset triggered. Listening for 10 seconds...")
    start = time.time()
    while time.time() - start < 10:
        data = ser.read(1024)
        if data:
            sys.stdout.buffer.write(data)
            sys.stdout.buffer.flush()
        time.sleep(0.05)
    ser.close()
except Exception as e:
    print(f"Error: {e}")
