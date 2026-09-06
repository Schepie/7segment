import asyncio
from bleak import BleakScanner

FOTA_SERVICE_UUID = "fb1e4001-54ae-4a28-9f74-dfccb248601d"

async def scan():
    print("Scanning for BLE devices for 5 seconds...")
    devices_and_adv = await BleakScanner.discover(timeout=5.0, return_adv=True)
    found = []
    for d, adv in devices_and_adv.values():
        name = adv.local_name or d.name or "Unknown"
        uuids = [str(u).lower() for u in (adv.service_uuids or [])]
        print(f"  [{d.address}] {name} (RSSI: {adv.rssi}) - UUIDs: {uuids}")
        if ("padel" in name.lower() or "esp32" in name.lower()) or (FOTA_SERVICE_UUID in uuids):
            found.append((d, adv))
    
    print("\n--- Matching FOTA Devices ---")
    for d, adv in found:
        name = adv.local_name or d.name or "Unknown"
        print(f"  ★ Found: {name} ({d.address})")

if __name__ == "__main__":
    asyncio.run(scan())
