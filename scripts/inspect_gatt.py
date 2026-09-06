import asyncio
from bleak import BleakClient

async def check():
    async with BleakClient("E8:F6:0A:36:6B:B2") as client:
        print("Connected. Discovering services:")
        for s in client.services:
            print(f"Service: {s.uuid} ({s.description})")
            for c in s.characteristics:
                print(f"  Char: {c.uuid} ({c.description}) - Props: {c.properties}")

if __name__ == "__main__":
    asyncio.run(check())
