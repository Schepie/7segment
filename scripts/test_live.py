import serial
import time
import threading
import asyncio
from bleak import BleakClient, BleakScanner

stop_flag = False

def read_serial():
    try:
        s = serial.Serial('COM12', 115200, timeout=0.1)
        s.dtr = True
        s.rts = True
        while not stop_flag:
            line = s.readline()
            if line:
                print(f"[ESP32] {line.decode('latin1', errors='replace').strip()}", flush=True)
            time.sleep(0.02)
        s.close()
    except Exception as e:
        print(f"Serial error: {e}", flush=True)

async def run_ble():
    global stop_flag
    print("[TEST] Scanning for Padel Display...", flush=True)
    dev = await BleakScanner.find_device_by_filter(lambda d, adv: 'padel' in (adv.local_name or '').lower(), timeout=6.0)
    if not dev:
        print("[TEST] Device not found in scan!", flush=True)
        stop_flag = True
        return
    print(f"[TEST] Found {dev.name} ({dev.address}), connecting...", flush=True)
    from bleak import WinRTClientArgs
    args = WinRTClientArgs(use_cached_services=False)
    async with BleakClient(dev, winrt=args, timeout=12.0) as client:
        print(f"[TEST] BLE Connected: {client.is_connected}", flush=True)
        for s in client.services:
            print(f"[TEST-SVC] {s.uuid}", flush=True)
        await asyncio.sleep(1.0)
    print("[TEST] BLE Disconnected", flush=True)
    stop_flag = True

if __name__ == "__main__":
    t = threading.Thread(target=read_serial, daemon=True)
    t.start()
    time.sleep(0.5)
    asyncio.run(run_ble())
