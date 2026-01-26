#include <WiFi.h>
#include <WebServer.h>

// ============================================
// WiFi Configuration - CHANGE THESE!
// ============================================
const char* ssid = "KARTHI";        // Your mobile hotspot name
const char* password = "12345678"; // Your mobile hotspot password

// ============================================
// L298N Motor Driver Pin Configuration
// ============================================
// Left Motors
#define IN1 19  // Forward
#define IN2 18  // Backward
#define ENA 16  // Speed Control (PWM)

// Right Motors
#define IN3 5   // Backward
#define IN4 23  // Forward
#define ENB 4   // Speed Control (PWM)

// Motor speed settings (0-255)
int motorSpeed = 150;  // Default speed

// ============================================
// Web Server Setup
// ============================================
WebServer server(80);

// ============================================
// SETUP FUNCTION
// ============================================
void setup() {
  // Initialize Serial Monitor
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n\n=================================");
  Serial.println("ESP32 Robot Car Controller (API Mode)");
  Serial.println("=================================");
  
  // Configure motor control pins as outputs
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);
  pinMode(ENA, OUTPUT);
  pinMode(ENB, OUTPUT);
  
  // Stop all motors at startup
  stopMotors();
  
  // Set initial speed
  analogWrite(ENA, motorSpeed);
  analogWrite(ENB, motorSpeed);
  
  // Connect to WiFi
  Serial.println("\nConnecting to WiFi...");
  Serial.print("SSID: ");
  Serial.println(ssid);
  
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n\n✓ WiFi Connected Successfully!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
    Serial.println("=================================");
  } else {
    Serial.println("\n\n✗ WiFi Connection Failed!");
  }
  
  // Configure web server routes
  server.on("/", handleRoot);
  server.on("/forward", handleForward);
  server.on("/backward", handleBackward);
  server.on("/left", handleLeft);
  server.on("/right", handleRight);
  server.on("/stop", handleStop);
  server.on("/speed", handleSpeed);
  
  // Start web server
  server.enableCORS(true);
  server.begin();
  Serial.println("Web Server Started!");
}

// ============================================
// MAIN LOOP
// ============================================
void loop() {
  server.handleClient();
}

// ============================================
// WEB SERVER HANDLERS
// ============================================

void handleRoot() {
  server.send(200, "text/plain", "Robot Car API Online. Use /forward, /backward, /left, /right, /stop");
}

void handleForward() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  moveForward();
  server.send(200, "text/plain", "FORWARD");
  Serial.println("CMD: FORWARD");
}

void handleBackward() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  moveBackward();
  server.send(200, "text/plain", "BACKWARD");
  Serial.println("CMD: BACKWARD");
}

void handleLeft() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  turnLeft();
  server.send(200, "text/plain", "LEFT");
  Serial.println("CMD: LEFT");
}

void handleRight() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  turnRight();
  server.send(200, "text/plain", "RIGHT");
  Serial.println("CMD: RIGHT");
}

void handleStop() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  stopMotors();
  server.send(200, "text/plain", "STOP");
  Serial.println("CMD: STOP");
}

void handleSpeed() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  if (server.hasArg("value")) {
    motorSpeed = server.arg("value").toInt();
    motorSpeed = constrain(motorSpeed, 0, 255);
    
    // Apply new speed if motors are running
    analogWrite(ENA, motorSpeed);
    analogWrite(ENB, motorSpeed);
    
    server.send(200, "text/plain", "SPEED_SET");
    Serial.print("CMD: SPEED ");
    Serial.println(motorSpeed);
  } else {
    server.send(400, "text/plain", "MISSING_VALUE");
  }
}

// ============================================
// MOTOR CONTROL FUNCTIONS
// ============================================

void moveForward() {
  // Ensure speed is applied
  analogWrite(ENA, motorSpeed);
  analogWrite(ENB, motorSpeed);
  
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  
  digitalWrite(IN4, HIGH);
  digitalWrite(IN3, LOW);
}

void moveBackward() {
  analogWrite(ENA, motorSpeed);
  analogWrite(ENB, motorSpeed);
  
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  
  digitalWrite(IN4, LOW);
  digitalWrite(IN3, HIGH);
}

void turnLeft() {
  analogWrite(ENA, motorSpeed);
  analogWrite(ENB, motorSpeed);
  
  // Left motors backward
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  
  // Right motors forward
  digitalWrite(IN4, HIGH);
  digitalWrite(IN3, LOW);
}

void turnRight() {
  analogWrite(ENA, motorSpeed);
  analogWrite(ENB, motorSpeed);
  
  // Left motors forward
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  
  // Right motors backward
  digitalWrite(IN4, LOW);
  digitalWrite(IN3, HIGH);
}

void stopMotors() {
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);
}