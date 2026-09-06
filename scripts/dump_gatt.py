import sys
import asyncio
from bleak import BleakClient, BleakScanner

sys.stdout.reconfigure(line_buffering=True)

TARGET_ADDR = "E8:F6:0A:36:6B:B2"

async def run():
    print(f"Connecting to {TARGET_ADDR}...")
    try:
        async with BleakClient(TARGET_ADDR, timeout=12.0) as client:
            print(f"Connected! MTU: {client.mtu_size}")
            print(f"Listing all services & characteristics:")
            for s in client.services:
                print(f"SERVICE: {s.uuid} - {s.description}")
                for c in s.characteristics:
                    print(f"   CHAR: {c.uuid} - {c.properties} - {c.description}")
    except Exception as e:
        print(f"Connection failed: {type(e).__name__}: {e}")

if __name__ == "__main__":
    asyncio.run(run())
