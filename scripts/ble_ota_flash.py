import sys
import os
import time
import asyncio
from bleak import BleakClient, BleakScanner

FOTA_SERVICE_UUID = "fb1e4001-54ae-4a28-9f74-dfccb248601d"
FOTA_CHAR_CONTROL = "fb1e4002-54ae-4a28-9f74-dfccb248601d"
FOTA_CHAR_DATA    = "fb1e4003-54ae-4a28-9f74-dfccb248601d"

async def main():
    bin_path = "firmware_4digits.bin"
    if len(sys.argv) > 1:
        bin_path = sys.argv[1]

    if not os.path.isfile(bin_path):
        print(f"ERROR: Firmware file '{bin_path}' not found!")
        sys.exit(1)

    file_size = os.path.getsize(bin_path)
    print(f"==================================================")
    print(f"   ESP32 BLE FOTA Flasher                         ")
    print(f"   Target Binary: {bin_path} ({file_size:,} bytes)")
    print(f"==================================================")

    with open(bin_path, "rb") as f:
        firmware_data = f.read()

    target_address = "E8:F6:0A:36:6B:B2"
    target_device = None

    print(f"Searching for target device ({target_address} or 'Padel*')...")
    devices_and_adv = await BleakScanner.discover(timeout=5.0, return_adv=True)
    for d, adv in devices_and_adv.values():
        name = adv.local_name or d.name or ""
        uuids = [str(u).lower() for u in (adv.service_uuids or [])]
        if d.address.upper() == target_address.upper():
            target_device = d
            print(f"Found target device by address: {name} ({d.address})")
            break
        if "padel" in name.lower() or FOTA_SERVICE_UUID in uuids:
            target_device = d
            print(f"Found matching device: {name} ({d.address})")
            break

    if not target_device:
        print(f"Target device not found in active scan. Attempting direct connection to {target_address}...")
        target_device = target_address

    print(f"Connecting to {target_device}...")

    start_ack_event = asyncio.Event()
    finish_ack_event = asyncio.Event()
    last_error = None
    esp_reported_mtu = 0

    def notification_handler(sender, data):
        nonlocal last_error, esp_reported_mtu
        if not data:
            return
        resp = data[0]
        if resp == 0x01: # FOTA_RESP_OK
            if len(data) >= 4:
                esp_reported_mtu = data[2] | (data[3] << 8)
            start_ack_event.set()
        elif resp == 0x02: # FOTA_RESP_SUCCESS
            finish_ack_event.set()
        elif resp == 0x05: # FOTA_RESP_PROGRESS
            pct = data[1] if len(data) > 1 else 0
            # Progress notification from ESP32
        elif resp == 0x0F: # FOTA_RESP_ERROR
            err_code = data[1] if len(data) > 1 else 0
            last_error = f"ESP32 reported error code: {err_code}"
            print(f"\n[ESP32 ERROR] {last_error}")
            start_ack_event.set()
            finish_ack_event.set()

    async with BleakClient(target_device, timeout=15.0) as client:
        print(f"Connected: {client.is_connected}")
        print(f"Negotiated MTU: {client.mtu_size}")

        ctrl_char = None
        data_char = None
        for s in client.services:
            print(f"Service: {s.uuid}")
            for c in s.characteristics:
                print(f"  Char: {c.uuid} ({c.properties})")
                if c.uuid.lower() == FOTA_CHAR_CONTROL.lower():
                    ctrl_char = c
                elif c.uuid.lower() == FOTA_CHAR_DATA.lower():
                    data_char = c

        if not ctrl_char or not data_char:
            print(f"ERROR: Could not find FOTA characteristics! ctrl={ctrl_char}, data={data_char}")
            return

        print("Subscribing to FOTA Control notifications...")
        await client.start_notify(ctrl_char, notification_handler)

        # 1. Send START command
        print(f"Sending FOTA START command for {file_size} bytes...")
        start_cmd = bytearray([
            0x01,
            file_size & 0xFF,
            (file_size >> 8) & 0xFF,
            (file_size >> 16) & 0xFF,
            (file_size >> 24) & 0xFF
        ])
        await client.write_gatt_char(ctrl_char, start_cmd, response=True)

        print("Waiting for flash partition preparation ACK...")
        try:
            await asyncio.wait_for(start_ack_event.wait(), timeout=6.0)
        except asyncio.TimeoutError:
            print("Warning: No START ACK received within 6s, proceeding anyway...")

        if last_error:
            print(f"Aborting OTA due to error: {last_error}")
            return

        # 2. Determine chunk size
        # Safe chunk size for Windows BLE
        chunk_size = min(client.mtu_size - 3, 240) if client.mtu_size > 23 else 20
        if esp_reported_mtu > 0:
            chunk_size = min(chunk_size, esp_reported_mtu)
        if chunk_size < 20:
            chunk_size = 20

        print(f"Streaming firmware using chunk size: {chunk_size} bytes...")
        start_time = time.time()
        offset = 0
        packet_count = 0
        last_pct_printed = -1

        while offset < file_size:
            chunk = firmware_data[offset : offset + chunk_size]
            try:
                await client.write_gatt_char(data_char, chunk, response=False)
            except Exception as e:
                # Fallback to with response if write_without_response fails
                try:
                    await client.write_gatt_char(data_char, chunk, response=True)
                except Exception as e2:
                    print(f"\nWrite error at offset {offset}: {e2}")
                    raise

            offset += len(chunk)
            packet_count += 1

            # Pacing: brief pause every 10 packets to avoid Windows BLE buffer congestion
            if packet_count % 10 == 0:
                await asyncio.sleep(0.008)

            pct = int((offset * 100) / file_size)
            if pct != last_pct_printed:
                last_pct_printed = pct
                elapsed = time.time() - start_time
                speed = (offset / 1024.0) / elapsed if elapsed > 0 else 0
                bar_len = 30
                filled = int(bar_len * pct // 100)
                bar = "=" * filled + "-" * (bar_len - filled)
                print(f"\rProgress: [{bar}] {pct:3d}% ({offset/1024:.0f}/{file_size/1024:.0f} KB, {speed:.1f} KB/s)", end="", flush=True)

        elapsed = time.time() - start_time
        print(f"\nAll bytes transferred in {elapsed:.1f}s ({file_size/1024/elapsed:.1f} KB/s).")
        print("Finalizing flash write and verifying checksum...")

        # 3. Send END command
        await asyncio.sleep(0.3)
        end_cmd = bytearray([0x02])
        await client.write_gatt_char(ctrl_char, end_cmd, response=True)

        print("Waiting for ESP32 verification and reboot trigger...")
        try:
            await asyncio.wait_for(finish_ack_event.wait(), timeout=8.0)
            if last_error:
                print(f"FAILED: {last_error}")
            else:
                print("SUCCESS: Firmware flashed and verified successfully!")
                print("The ESP32 is now rebooting into the new 4-digit scoreboard firmware.")
        except asyncio.TimeoutError:
            print("Note: Device may have rebooted immediately without sending ACK.")
            print("Check scoreboard display for startup sequence.")

if __name__ == "__main__":
    asyncio.run(main())
