# 🔥 ESP32-CAM & App Integration Guide

## Ultimate Edition: AI + SD Recording + Continuous Monitoring

---

## 🛠️ Step 1: Hardware Wiring (FINAL)

We have optimized the wiring. **NO PIR SENSOR NEEDED**.

| Component | ESP32-CAM Pin | Note |
| :--- | :--- | :--- |
| **Relay Module** | **GPIO 13** | **CHANGED** (Was 12, Was 14) |
| **Buzzer** | GPIO 4 | No Change |
| **PIR Sensor** | **REMOVED** | Not used. AI runs continuously. |
| **SD Card** | **Built-in Slot** | Uses GPIO 14, 15, 2 |

> [!TIP]
> **Why Pin 13 for Relay?**
> Pins 14, 15, and 2 are used by the SD Card. Pin 12 is a "Strapping Pin" that can fail uploads. Pin 13 is free and safe!

---

## 💻 Step 2: Configure & Upload
1. Open `ESP32_CAM_HumoSafe_Complete/ESP32_CAM_HumoSafe_Complete.ino`
2. **Update WiFi**:
   ```cpp
   #define WIFI_SSID "Shanthi"
   #define WIFI_PASSWORD "" (or your password if you have one)
   ```
3. **Format SD Card**: Ensure your SD card is formatted as **FAT32**.
4. **Select Board**: AI-Thinker ESP32-CAM
5. **Upload**!

---

## 📱 Step 3: Features & Testing

### 1. Continuous AI Monitoring
- The camera wakes up every 2 seconds to check for humans.
- **Note**: AI detection is paused while you are watching the Live Stream to ensure smooth video.

### 2. Auto-Recording
- When **HUMAN** is detected:
  - System beeps once.
  - Automatically saves a photo to the SD Card.
  - Saved in `/recordings/` folder.

### 3. App Control
- **LOCK Toggle**: Controls the Relay on **Pin 13**.
- **SIREN Toggle**: Controls the Buzzer on **Pin 4**.

---

## 🔍 Troubleshooting
- **SD Mount Failed?**
  - Check if card is FAT32.
  - Try a different card.
- **Relay not clicking?**
  - Ensure it is on GPIO 13.
  - Check App "Servo Lock" toggle.
