import asyncio
from bleak import BleakClient, BleakScanner

FOTA_SERVICE_UUID = "fb1e4001-54ae-4a28-9f74-dfccb248601d"
WATCH_SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b"

async def run():
    dev = await BleakScanner.find_device_by_filter(lambda d, adv: 'padel' in (adv.local_name or '').lower(), timeout=10.0)
    if not dev:
        dev = "E8:F6:0A:36:6B:B2"
    print(f"Connecting to {getattr(dev, 'name', dev)} ({getattr(dev, 'address', dev)})...")
    async with BleakClient(dev, timeout=12.0) as client:
        print("Connected!")
        # Try winrt specific direct uuid discovery
        try:
            import uuid
            from winrt.windows.devices.bluetooth import BluetoothCacheMode
            fota_uuid = uuid.UUID(FOTA_SERVICE_UUID)
            res = await client._backend._requester._device.get_gatt_services_for_uuid_async(fota_uuid, BluetoothCacheMode.UNCACHED)
            print("Direct FOTA query result status:", res.status)
            print("Services returned:", len(res.services))
            for s in res.services:
                print("Found FOTA service:", s.uuid)
                chrs = await s.get_characteristics_async(BluetoothCacheMode.UNCACHED)
                print("Characteristics count:", len(chrs.characteristics))
                for c in chrs.characteristics:
                    print("  Char:", c.uuid)
        except Exception as e:
            print("Error in direct query:", e)

if __name__ == "__main__":
    asyncio.run(run())
