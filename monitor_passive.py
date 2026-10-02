import serial
import time
import sys

try:
    ser = serial.Serial('COM12', 115200, timeout=0.1)
    # Do NOT reset the board! Just listen to whatever is happening right now!
    print("Listening passively on COM12 for 15 seconds...")
    start = time.time()
    while time.time() - start < 15:
        data = ser.read(1024)
        if data:
            sys.stdout.buffer.write(data)
            sys.stdout.buffer.flush()
        time.sleep(0.05)
    ser.close()
except Exception as e:
    print(f"Error: {e}")
