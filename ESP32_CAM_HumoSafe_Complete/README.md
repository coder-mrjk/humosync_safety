# ESP32-CAM HUMOSAFE - Quick Start Guide

## 🚀 Quick Setup Overview

This guide provides a quick reference for setting up your HUMOSAFE ESP32-CAM security system.

---

## 📁 Files Included

| File | Purpose |
|------|---------|
| `ESP32_CAM_HumoSafe_Complete.ino` | Main Arduino sketch |
| `model_data.h` | TensorFlow Lite model (you must generate this) |
| `ESP32_CAM_SETUP_GUIDE.md` | Detailed hardware setup |
| `TEACHABLE_MACHINE_GUIDE.md` | AI model training guide |

---

## ⚡ Quick Start Steps

### 1. Hardware Setup
- Connect components according to [ESP32_CAM_SETUP_GUIDE.md](ESP32_CAM_SETUP_GUIDE.md)
- Key connections:
  - PIR Sensor → GPIO 13
  - RFID RC522 → SPI pins (VCC to 3.3V!)
  - Buzzer → GPIO 4
  - Relay → GPIO 14

### 2. Train AI Model
- Follow [TEACHABLE_MACHINE_GUIDE.md](TEACHABLE_MACHINE_GUIDE.md)
- Create three classes: ANIMALS, HUMANS, OTHERS
- Collect 100+ samples per class
- Export as "Quantized TensorFlow Lite for Microcontrollers"

### 3. Generate Model File
- Convert `model.tflite` to C array
- Replace contents of `model_data.h` with your model
- See instructions in `model_data.h` file

### 4. Configure Arduino Code
Open `ESP32_CAM_HumoSafe_Complete.ino` and update:

```cpp
// WiFi Configuration
#define WIFI_SSID "YOUR_WIFI_SSID"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"

// Authorized RFID UIDs
const String authorizedUIDs[] = {
  "AA:BB:CC:DD",  // Replace with your card UIDs
  "11:22:33:44",
  "FF:EE:DD:CC"
};
```

### 5. Install Required Libraries

In Arduino IDE, install:
- **ESP32 Board Support** (via Board Manager)
- **Firebase ESP Client** by Mobizt
- **MFRC522** by GithubCommunity
- **TensorFlowLite_ESP32** by tanakamasayuki

### 6. Upload Code
1. Connect FTDI programmer to ESP32-CAM
2. Ground GPIO 0 (programming mode)
3. Press RESET button
4. Select board: "AI Thinker ESP32-CAM"
5. Click Upload
6. Remove GPIO 0 jumper
7. Press RESET to run

### 7. Test System
1. Open Serial Monitor (115200 baud)
2. Verify WiFi connection
3. Test PIR sensor
4. Test AI classification
5. Test RFID authorization
6. Check Firebase updates

---

## 🔧 Configuration Checklist

Before first run, verify:

- [ ] All hardware connections correct
- [ ] RC522 connected to 3.3V (NOT 5V!)
- [ ] WiFi credentials updated
- [ ] Firebase credentials correct
- [ ] Authorized RFID UIDs added
- [ ] `model_data.h` contains your trained model
- [ ] All required libraries installed
- [ ] Correct board selected in Arduino IDE

---

## 📊 System Behavior

### State Machine Flow

```
IDLE → PIR Detects Motion → AI Classification
                                    ↓
                    ┌───────────────┼───────────────┐
                    ↓               ↓               ↓
                 HUMAN           ANIMAL          OTHERS
                    ↓               ↓               ↓
            PIR Confirmed?      No Action       No Action
                    ↓               ↓               ↓
            Request RFID        Log Only        Log Only
                    ↓               ↓               ↓
            Scan Card           Return          Return
                    ↓               to              to
            Authorized?         IDLE            IDLE
                    ↓
        ┌───────────┴───────────┐
        ↓                       ↓
    AUTHORIZED            UNAUTHORIZED
        ↓                       ↓
    Open Lock              Trigger Alarm
        ↓                       ↓
    Return to IDLE         Return to IDLE
```

### Detection Logic

**HUMAN Detection:**
- AI detects "HUMANS" with >70% confidence
- PIR sensor confirms motion
- System requests RFID scan
- 10-second timeout for card scan
- Authorized → Open relay (3 seconds)
- Unauthorized → Activate buzzer (5 seconds)

**ANIMAL Detection:**
- AI detects "ANIMALS" with >70% confidence
- No actuator response
- Log to Firebase
- Continue live streaming
- Return to idle

**OTHERS Detection:**
- AI detects "OTHERS" or low confidence
- No actuator response
- Log to Firebase
- Return to idle

---

## 🔍 Troubleshooting

### Common Issues

| Problem | Solution |
|---------|----------|
| Won't compile | Install all required libraries |
| Camera init failed | Use 5V 2A power supply |
| RFID not working | Check 3.3V connection (NOT 5V!) |
| AI always returns "OTHERS" | Replace `model_data.h` with actual model |
| WiFi won't connect | Check SSID/password, move closer to router |
| Firebase errors | Verify API key and database URL |

### Serial Monitor Output

**Normal startup:**
```
╔════════════════════════════════════════════╗
║   HUMOSAFE - AI Security System v1.0      ║
║   ESP32-CAM Complete Implementation        ║
╚════════════════════════════════════════════╝

✓ Hardware initialized
✓ WiFi connected!
IP Address: 192.168.1.100
✓ Camera initialized (96x96 RGB)
✓ Firebase initialized
✓ RFID RC522 initialized
✓ TensorFlow Lite model loaded!

╔════════════════════════════════════════════╗
║          SYSTEM READY - MONITORING         ║
╚════════════════════════════════════════════╝

Stream URL: http://192.168.1.100:80/stream
Waiting for motion...
```

---

## 📱 Firebase Data Structure

Your data will appear in Firebase Realtime Database:

```json
{
  "robot": {
    "status": {
      "online": true,
      "stream_url": "http://192.168.1.100:80/stream",
      "last_sync": 123456,
      "message": "Monitoring..."
    },
    "detection": {
      "class": "HUMANS",
      "confidence": 0.95,
      "pir_confirmed": true,
      "timestamp": 123456
    },
    "rfid": {
      "requested": false,
      "uid": "AA:BB:CC:DD",
      "authorized": true,
      "timestamp": 123456
    },
    "sensors": {
      "pir": false
    },
    "actuators": {
      "buzzer": false,
      "relay": false
    }
  }
}
```

---

## 🎯 Next Steps

After successful setup:

1. **Test thoroughly** in your deployment environment
2. **Collect edge cases** where AI fails
3. **Retrain model** with additional samples
4. **Adjust thresholds** (confidence, timeouts) as needed
5. **Monitor Firebase** for real-time updates
6. **Integrate with Flutter app** for mobile control

---

## 📚 Additional Resources

- [ESP32-CAM Documentation](https://github.com/espressif/esp32-camera)
- [Firebase ESP Client](https://github.com/mobizt/Firebase-ESP-Client)
- [TensorFlow Lite Micro](https://www.tensorflow.org/lite/microcontrollers)
- [Teachable Machine](https://teachablemachine.withgoogle.com)

---

## 🆘 Support

For issues or questions:
1. Check the detailed guides (SETUP_GUIDE.md, TEACHABLE_MACHINE_GUIDE.md)
2. Review Serial Monitor output for error messages
3. Verify all connections and configurations
4. Test components individually before integration

---

**Project**: HUMOSAFE - AI-Powered Security Guardian  
**Version**: 1.0  
**Last Updated**: January 2026
