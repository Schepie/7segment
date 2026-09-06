#ifndef BLE_FOTA_H
#define BLE_FOTA_H

// ==============================================================================
// Universal BLE FOTA (Bluetooth Low Energy Firmware Over-The-Air) Service
// Allows flashing firmware wirelessly via Web Bluetooth from Chrome/Edge
// ==============================================================================

#include <Arduino.h>
#include <NimBLEDevice.h>
#include <Update.h>

#define BLE_FOTA_SERVICE_UUID  "fb1e4001-54ae-4a28-9f74-dfccb248601d"
#define BLE_FOTA_CHAR_CONTROL  "fb1e4002-54ae-4a28-9f74-dfccb248601d"
#define BLE_FOTA_CHAR_DATA     "fb1e4003-54ae-4a28-9f74-dfccb248601d"

// OTA Commands
#define FOTA_CMD_START   0x01
#define FOTA_CMD_END     0x02
#define FOTA_CMD_ABORT   0x03

// OTA Status Responses
#define FOTA_RESP_OK       0x01
#define FOTA_RESP_SUCCESS  0x02
#define FOTA_RESP_PROGRESS 0x05
#define FOTA_RESP_ERROR    0x0F

class BleFota {
public:
  typedef void (*ProgressCallback)(int percent);
  typedef void (*StatusCallback)(bool inProgress, bool success);

  static void init(NimBLEServer* pServer, const char* advName = "Padel-Scoreboard-OTA") {
    getInstance().setupService(pServer, advName);
  }

  static void setCallbacks(ProgressCallback progCb, StatusCallback statusCb) {
    getInstance().progressCb = progCb;
    getInstance().statusCb = statusCb;
  }

  static bool isUpdating() {
    return getInstance().inProgress;
  }

private:
  BleFota() : pServer(nullptr), pControlChar(nullptr), pDataChar(nullptr),
              inProgress(false), totalSize(0), bytesWritten(0), lastPercent(-1),
              progressCb(nullptr), statusCb(nullptr) {}

  static BleFota& getInstance() {
    static BleFota instance;
    return instance;
  }

  NimBLEServer* pServer;
  NimBLECharacteristic* pControlChar;
  NimBLECharacteristic* pDataChar;
  bool inProgress;
  size_t totalSize;
  size_t bytesWritten;
  int lastPercent;
  ProgressCallback progressCb;
  StatusCallback statusCb;

  void setupService(NimBLEServer* server, const char* advName) {
    pServer = server;
    if (!pServer) return;

    NimBLEService* pService = pServer->createService(BLE_FOTA_SERVICE_UUID);
    if (!pService) {
      Serial.println("[FOTA] Failed to create FOTA service");
      return;
    }

    // Control Characteristic: Write + Notify
    pControlChar = pService->createCharacteristic(
      BLE_FOTA_CHAR_CONTROL,
      NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::NOTIFY
    );
    pControlChar->setCallbacks(new ControlCallbacks(*this));

    // Data Characteristic: Write Without Response + Write
    pDataChar = pService->createCharacteristic(
      BLE_FOTA_CHAR_DATA,
      NIMBLE_PROPERTY::WRITE_NR | NIMBLE_PROPERTY::WRITE
    );
    pDataChar->setCallbacks(new DataCallbacks(*this));

    NimBLEDevice::setMTU(517);
    pService->start();

    // Advertise FOTA Service
    NimBLEAdvertising* pAdvertising = NimBLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(BLE_FOTA_SERVICE_UUID);
    pAdvertising->setScanResponse(true);

    Serial.println("[FOTA] BLE FOTA GATT Service initialized successfully with MTU 517.");
  }

  static void rebootTask(void* param) {
    vTaskDelay(pdMS_TO_TICKS(1000));
    Serial.println("[FOTA] Disconnecting BLE clients...");
    if (NimBLEDevice::getServer()) {
      auto peers = NimBLEDevice::getServer()->getPeerDevices();
      for (auto peerId : peers) {
        NimBLEDevice::getServer()->disconnect(peerId);
      }
    }
    if (NimBLEDevice::getAdvertising()) {
      NimBLEDevice::getAdvertising()->stop();
    }
    if (NimBLEDevice::getScan()) {
      NimBLEDevice::getScan()->stop();
    }
    vTaskDelay(pdMS_TO_TICKS(200));

    Serial.println("[FOTA] Deinitializing Bluetooth hardware...");
    NimBLEDevice::deinit(true);
    vTaskDelay(pdMS_TO_TICKS(300));

    Serial.println("[FOTA] Clean rebooting into new firmware...");
    ESP.restart();
    vTaskDelete(NULL);
  }

  void handleControl(uint8_t* pData, size_t length) {
    if (length == 0) return;
    uint8_t cmd = pData[0];

    if (cmd == FOTA_CMD_START && length >= 5) {
      totalSize = (size_t)(pData[1] | (pData[2] << 8) | (pData[3] << 16) | (pData[4] << 24));
      bytesWritten = 0;
      lastPercent = -1;

      Serial.printf("[FOTA] Starting OTA transfer, expected size: %u bytes\n", totalSize);

      if (!Update.begin(totalSize, U_FLASH)) {
        Serial.printf("[FOTA] Update.begin failed! Error: %d\n", Update.getError());
        uint8_t resp[2] = { FOTA_RESP_ERROR, (uint8_t)Update.getError() };
        pControlChar->setValue(resp, 2);
        pControlChar->notify();
        if (statusCb) statusCb(false, false);
        return;
      }

      inProgress = true;
      uint16_t peerMtu = 23;
      std::vector<uint16_t> peers = pServer->getPeerDevices();
      if (!peers.empty()) {
        peerMtu = pServer->getPeerMTU(peers[0]);
      }
      uint16_t maxPayload = (peerMtu > 3) ? (peerMtu - 3) : 20;
      Serial.printf("[FOTA] Flash ready. Peer ATT MTU: %u (max payload: %u)\n", peerMtu, maxPayload);

      uint8_t resp[4] = { FOTA_RESP_OK, 0x00, (uint8_t)(maxPayload & 0xFF), (uint8_t)((maxPayload >> 8) & 0xFF) };
      pControlChar->setValue(resp, 4);
      pControlChar->notify();
      if (statusCb) statusCb(true, false);
      if (progressCb) progressCb(0);

    } else if (cmd == FOTA_CMD_END) {
      Serial.println("[FOTA] Finishing OTA...");
      if (Update.end(true)) {
        if (Update.isFinished()) {
          Serial.println("[FOTA] ★ Update successfully written and verified!");
          uint8_t resp[2] = { FOTA_RESP_SUCCESS, 0x00 };
          pControlChar->setValue(resp, 2);
          pControlChar->notify();
          inProgress = false;
          if (statusCb) statusCb(false, true);

          // Schedule reboot after BLE notification is sent
          xTaskCreate(rebootTask, "fota_reboot", 2048, NULL, 5, NULL);
          return;
        }
      }

      Serial.printf("[FOTA] Update failed or not finished. Error: %d\n", Update.getError());
      uint8_t resp[2] = { FOTA_RESP_ERROR, (uint8_t)Update.getError() };
      pControlChar->setValue(resp, 2);
      pControlChar->notify();
      inProgress = false;
      if (statusCb) statusCb(false, false);

    } else if (cmd == FOTA_CMD_ABORT) {
      Serial.println("[FOTA] OTA aborted by client");
      Update.abort();
      inProgress = false;
      if (statusCb) statusCb(false, false);
    }
  }

  void handleData(uint8_t* pData, size_t length) {
    if (!inProgress || length == 0) return;

    size_t written = Update.write(pData, length);
    if (written > 0) {
      bytesWritten += written;
      if (totalSize > 0) {
        int percent = (int)((bytesWritten * 100) / totalSize);
        if (percent != lastPercent) {
          lastPercent = percent;
          if (progressCb) progressCb(percent);

          // Notify progress every 5%
          if (percent % 5 == 0) {
            uint8_t resp[2] = { FOTA_RESP_PROGRESS, (uint8_t)percent };
            pControlChar->setValue(resp, 2);
            pControlChar->notify();
          }
        }
      }
    } else {
      Serial.printf("[FOTA] Write chunk failed at offset %u\n", bytesWritten);
    }
  }

  class ControlCallbacks : public NimBLECharacteristicCallbacks {
  public:
    ControlCallbacks(BleFota& parent) : fota(parent) {}
    void onWrite(NimBLECharacteristic* pChar) override {
      std::string val = pChar->getValue();
      fota.handleControl((uint8_t*)val.data(), val.length());
    }
  private:
    BleFota& fota;
  };

  class DataCallbacks : public NimBLECharacteristicCallbacks {
  public:
    DataCallbacks(BleFota& parent) : fota(parent) {}
    void onWrite(NimBLECharacteristic* pChar) override {
      std::string val = pChar->getValue();
      fota.handleData((uint8_t*)val.data(), val.length());
    }
  private:
    BleFota& fota;
  };
};

#endif // BLE_FOTA_H
