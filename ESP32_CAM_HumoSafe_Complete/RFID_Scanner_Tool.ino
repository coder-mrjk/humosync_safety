/*
 * ============================================================================
 * HUMOSAFE - RFID Scanner Tool
 * Use this to find the UID of your RFID cards
 * ============================================================================
 */

#include <SPI.h>
#include <MFRC522.h>

// ESP32-CAM Pin Definitions for RC522
#define SS_PIN  15
#define RST_PIN 2
#define SCK_PIN 14
#define MOSI_PIN 13
#define MISO_PIN 12

MFRC522 rfid(SS_PIN, RST_PIN);

void setup() {
  Serial.begin(115200);
  SPI.begin(SCK_PIN, MISO_PIN, MOSI_PIN, SS_PIN);
  rfid.PCD_Init();

  Serial.println("\n\n===============================================");
  Serial.println("       HUMOSAFE RFID SCANNER READY");
  Serial.println("===============================================");
  Serial.println("Please obtain your card UID by scanning it...");
}

void loop() {
  // Look for new cards
  if (!rfid.PICC_IsNewCardPresent()) return;
  if (!rfid.PICC_ReadCardSerial()) return;

  Serial.print("💳 UID Tag Found: ");
  String content = "";
  for (byte i = 0; i < rfid.uid.size; i++) {
    Serial.print(rfid.uid.uidByte[i] < 0x10 ? " 0" : " ");
    Serial.print(rfid.uid.uidByte[i], HEX);
    content.concat(String(rfid.uid.uidByte[i] < 0x10 ? "0" : ""));
    content.concat(String(rfid.uid.uidByte[i], HEX));
  }
  Serial.println();
  
  content.toUpperCase();
  // Format as AA:BB:CC:DD for the main code
  String formattedUID = "";
  for (int i = 0; i < content.length(); i += 2) {
    if (i > 0) formattedUID += ":";
    formattedUID += content.substring(i, i + 2);
  }
  
  Serial.print("📋 Copy this to your code: \"");
  Serial.print(formattedUID);
  Serial.println("\"");
  Serial.println("-----------------------------------------------\n");

  rfid.PICC_HaltA();
  rfid.PCD_StopCrypto1();
  delay(1000);
}
