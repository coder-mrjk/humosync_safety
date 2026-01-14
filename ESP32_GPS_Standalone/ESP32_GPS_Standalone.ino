/*
 * ============================================================================
 * HUMOSAFE - GPS TRACKING MODULE
 * Platform: DOIT ESP32 DevKit V1
 * Sensor: Ublox Neo M8N
 * Backend: Firebase Realtime Database
 * ============================================================================
 * 
 * This device runs INDEPENDENTLY of the ESP32-CAM.
 * It reads GPS coordinates and pushes them to 'robot/status/gps'.
 */

#include <WiFi.h>
#include <TinyGPS++.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// ⚙️ WIFI & FIREBASE CREDENTIALS (SAME AS ESP32-CAM)
#define WIFI_SSID "YOUR_WIFI_SSID" 
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"

#define API_KEY "AIzaSyBJeAwdfaYlQQjv6Gj0SjZm4_SfZuKkKCc"
#define DATABASE_URL "https://humosync-safety-default-rtdb.asia-southeast1.firebasedatabase.app/"
#define USER_EMAIL "goatkarthi7@gmail.com"
#define USER_PASSWORD "Karthi@161212"

// 🔌 PINS
// ESP32 DevKit V1 usually has plenty of pins.
// Connecting GPS defaults:
// VCC -> 5V (or 3.3V check module)
// GND -> GND
// GPS TX -> GPIO 16 (RX2)
// GPS RX -> GPIO 17 (TX2) - Not strictly needed if only reading

#define RXD2 16
#define TXD2 17
#define GPS_BAUD 9600

// OBJECTS
TinyGPSPlus gps;
HardwareSerial gpsSerial(2); // Use UART 2

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

void setup() {
  Serial.begin(115200);
  
  // Start GPS Serial
  gpsSerial.begin(GPS_BAUD, SERIAL_8N1, RXD2, TXD2);
  Serial.println("\n🛰️ GPS Module Initializing...");

  // Connect to WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println();
  Serial.print("Connected: ");
  Serial.println(WiFi.localIP());

  // Connect to Firebase
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;
  
  // Assign the callback function for the long running token generation task
  config.token_status_callback = tokenStatusCallback; 

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop() {
  // 1. Read GPS Data constantly
  while (gpsSerial.available() > 0) {
    gps.encode(gpsSerial.read());
  }

  // 2. Push to Firebase periodically
  static unsigned long lastUpload = 0;
  if (millis() - lastUpload > 3000) { // Every 3 seconds
    if (gps.location.isValid()) {
      Serial.printf("📍 Lat: %.6f, Lng: %.6f\n", gps.location.lat(), gps.location.lng());
      
      if (Firebase.ready()) {
        FirebaseJson json;
        json.set("lat", gps.location.lat());
        json.set("lng", gps.location.lng());
        json.set("accuracy", gps.hdop.hdop() * 5); // Estimated accuracy in meters
        json.set("satellites", gps.satellites.value());
        json.set("timestamp", millis());

        // Push to 'robot/status/gps' so the app picks it up automatically
        // This merges with the existing 'robot/status' from the ESP32-CAM
        Firebase.RTDB.setJSON(&fbdo, "robot/status/gps", &json);
      }
    } else {
      Serial.println("⌛ Waiting for valid GPS signal...");
    }
    lastUpload = millis();
  }
}
