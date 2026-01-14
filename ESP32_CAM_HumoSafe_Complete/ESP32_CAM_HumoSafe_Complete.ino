/*
 * ============================================================================
 * HUMOSAFE - ESP32-CAM Complete Security System
 * Ultimate Edition v5.2 - Firebase-ESP32 & TFLite Fixes
 * ============================================================================
 * 
 * CORE FEATURES:
 * 1. 📹 Live Video Stream -> Flutter App Dashboard
 * 2. 🧠 Three-Class AI -> Continuous Monitoring
 * 3. 💾 SD Card Recording -> Auto-save on Person Detection
 * 4. 📱 App Control -> Toggle Siren/Lock remotely
 * 5. ☁️ Real-time Firebase Sync
 * 
 * PLATFORM: ESP32-CAM (AI-Thinker)
 * AUTHOR: HUMOSAFE Team
 * DATE: January 2026
 * ============================================================================
 */

#include "esp_camera.h"
#include <WiFi.h>
#include "SD_MMC.h"
#include "FS.h"
#include <FirebaseESP32.h> 

// TensorFlow Lite Dependencies
// NOTE: Must install "TensorFlowLite_ESP32" by Tanmay Data / SRi
// DO NOT use "Arduino_TensorFlowLite"
#include "tensorflow/lite/micro/micro_error_reporter.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/micro/micro_mutable_op_resolver.h"
#include "tensorflow/lite/schema/schema_generated.h"
// #include "version.h" // Sometimes needed depending on lib version

// Custom Model Files
#include "person_detect_model_data.h"
#include "model_settings.h"

// ============================================================================
// ⚙️ USER CONFIGURATION
// ============================================================================

// 📶 WiFi Credentials (UPDATE THESE!)
#define WIFI_SSID "Shanthi" 
#define WIFI_PASSWORD "12345678"

// 🔥 Firebase Credentials (EXISTING PROJECT)
#define API_KEY "AIzaSyBJeAwdfaYlQQjv6Gj0SjZm4_SfZuKkKCc"
#define DATABASE_URL "https://humosync-safety-default-rtdb.asia-southeast1.firebasedatabase.app/"
#define USER_EMAIL "goatkarthi7@gmail.com"
#define USER_PASSWORD "Karthi@161212"

// 🔌 Pin Definitions
#define BUZZER_PIN 4        // Active Buzzer
#define RELAY_PIN 13        // Relay Module (Moved to 13 - Safe from SD/Boot conflicts)
// SD Card uses: GPIO 14 (CLK), 15 (CMD), 2 (D0) in 1-bit mode

// ⏱️ Timing Settings
#define INFERENCE_INTERVAL_MS 2000    // Run AI every 2 seconds

// ============================================================================
// 📸 CAMERA CONFIGURATION (AI-Thinker Model)
// ============================================================================
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27
#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

// ============================================================================
// 📦 GLOBAL OBJECTS & VARIABLES
// ============================================================================

// Firebase
FirebaseData fbdo;
FirebaseData streamData; 
FirebaseAuth auth;
FirebaseConfig config;

// Web Server
WiFiServer server(80);

// SD Card
bool sdReady = false;

// TFLite Globals
namespace {
  tflite::ErrorReporter* error_reporter = nullptr;
  const tflite::Model* model = nullptr;
  tflite::MicroInterpreter* interpreter = nullptr;
  TfLiteTensor* input_tensor = nullptr;
  constexpr int kTensorArenaSize = 136 * 1024; 
  uint8_t tensor_arena[kTensorArenaSize];
}

// System States
enum SystemState {
  STATE_IDLE,
  STATE_AI_PROCESSING,
  STATE_HUMAN_DETECTED,
  STATE_RECORDING,
  STATE_ANIMAL_DETECTED,
  STATE_OTHERS_DETECTED
};

SystemState currentState = STATE_IDLE;

// Runtime Variables
String lastDetectedClass = "OTHERS";
float lastConfidence = 0.0;
unsigned long lastInferenceTime = 0;
bool streamActive = false;
String localIP = "";
bool manualSiren = false;
bool manualLock = true; 

// ============================================================================
// 🛠️ FUNCTION PROTOTYPES
// ============================================================================
void initSystem();
void initSDCard();
void handleStream();
void runAI();
void updateAppStatus();
void listenToAppCommands();
void sendDetection(String cls, float conf);
void controlActuators(bool buzzer, bool relay);
void saveFrameToSD(camera_fb_t * fb);

// ============================================================================
// 🚀 MAIN SETUP
// ============================================================================
void setup() {
  Serial.begin(115200);
  Serial.println("\n🚀 HUMOSAFE SYSTEM CONNECTING...");
  
  initSystem();
  
  // Start listening for commands
  if (Firebase.ready()) {
    Firebase.beginStream(streamData, "robot/commands");
    Firebase.setStreamCallback(streamData, streamCallback, streamTimeoutCallback);
  }
  
  // Initial Status Update
  Serial.println("✓ System Ready & Listening to App");
  updateAppStatus();
}

// ============================================================================
// 🔄 MAIN LOOP
// ============================================================================
void loop() {
  // 1. Maintain Logic Flow
  handleStream(); // Web server for video

  // 2. State Machine Logic
  switch (currentState) {
    case STATE_IDLE:
      // Continuous Monitoring: Run AI every X seconds
      if (millis() - lastInferenceTime > INFERENCE_INTERVAL_MS) {
        currentState = STATE_AI_PROCESSING;
      }
      break;

    case STATE_AI_PROCESSING:
      runAI();
      lastInferenceTime = millis();
      
      if (lastDetectedClass == "HUMANS" && lastConfidence >= 0.70) {
        currentState = STATE_HUMAN_DETECTED;
      } else if (lastDetectedClass == "ANIMALS" && lastConfidence >= 0.70) {
        currentState = STATE_ANIMAL_DETECTED;
      } else {
        currentState = STATE_OTHERS_DETECTED; // Back to Idle
      }
      break;

    case STATE_HUMAN_DETECTED:
      Serial.println("👤 Human Detected - Recording Evidence");
      currentState = STATE_RECORDING;
      // Quick beep to alert
      digitalWrite(BUZZER_PIN, HIGH); delay(100); digitalWrite(BUZZER_PIN, LOW);
      break;

    case STATE_RECORDING:
      {
         camera_fb_t * fb = esp_camera_fb_get();
         if(fb) {
           saveFrameToSD(fb);
           esp_camera_fb_return(fb);
         }
      }
      currentState = STATE_IDLE; // Reset to idle after recording
      break;

    case STATE_ANIMAL_DETECTED:
      Serial.println("🐾 Animal - Log Only");
      currentState = STATE_IDLE;
      break;
      
    case STATE_OTHERS_DETECTED:
      currentState = STATE_IDLE;
      break;
  }
  
  // 3. Manual Overrides (App Control)
  if (manualSiren) {
    digitalWrite(BUZZER_PIN, HIGH); 
  } else {
    digitalWrite(BUZZER_PIN, LOW); 
  }
}

// ============================================================================
// 📱 APP COMMAND LISTENER
// ============================================================================
void streamCallback(FirebaseStream data) {
  String path = data.dataPath();
  String value = data.payload();
  
  Serial.print(" Command Received: ");
  Serial.print(path);
  Serial.print(" -> ");
  Serial.println(value);

  if (path == "/siren") {
    manualSiren = (value == "true");
    controlActuators(manualSiren, false);
  }
  else if (path == "/servo_lock") { 
    manualLock = (value == "true");
    if (!manualLock) {
       digitalWrite(RELAY_PIN, HIGH); // Unlock
       delay(2000); // 2 sec pulse
       digitalWrite(RELAY_PIN, LOW);  // Lock again
    }
  }
  else if (path == "/emergency") {
    if (value == "true") {
      ESP.restart(); 
    }
  }
}

void streamTimeoutCallback(bool timeout) {
  if (timeout) Serial.println("⚠️ Stream Timeout - Reconnecting...");
}

// ============================================================================
// 📡 STREAMING HANDLER
// ============================================================================
void handleStream() {
  WiFiClient client = server.available();
  if (!client) return;

  Serial.println("📱 App Dashboard Connected");
  streamActive = true;
  updateAppStatus();

  String request = client.readStringUntil('\r');
  client.flush();

  sensor_t *s = esp_camera_sensor_get();
  s->set_pixformat(s, PIXFORMAT_JPEG);
  s->set_framesize(s, FRAMESIZE_VGA);

  client.println("HTTP/1.1 200 OK");
  client.println("Content-Type: multipart/x-mixed-replace; boundary=frame");
  client.println("Access-Control-Allow-Origin: *");
  client.println();

  while (client.connected()) {
    camera_fb_t *fb = esp_camera_fb_get();
    if (!fb) break;

    client.print("--frame\r\n");
    client.print("Content-Type: image/jpeg\r\n");
    client.print("Content-Length: " + String(fb->len) + "\r\n\r\n");
    client.write(fb->buf, fb->len);
    client.print("\r\n");
    esp_camera_fb_return(fb);
  }

  streamActive = false;
  client.stop();
  updateAppStatus();
  Serial.println("📱 Stream Disconnected");
}

// ============================================================================
// 🧠 AI INFERENCE
// ============================================================================
void runAI() {
  sensor_t *s = esp_camera_sensor_get();
  s->set_pixformat(s, PIXFORMAT_RGB565);
  s->set_framesize(s, FRAMESIZE_96X96);
  
  camera_fb_t *fb = esp_camera_fb_get();
  if (!fb) return;

  int8_t *input_data = input_tensor->data.int8;
  uint16_t *pixels = (uint16_t *)fb->buf;
  for (int i = 0; i < kNumRows * kNumCols; i++) {
    uint16_t p = pixels[i];
    uint8_t r = ((p >> 11) & 0x1F) << 3;
    uint8_t g = ((p >> 5) & 0x3F) << 2;
    uint8_t b = (p & 0x1F) << 3;
    float gray = (0.2126 * r) + (0.7152 * g) + (0.0722 * b);
    input_data[i] = (int8_t)(gray - 128); 
  }

  if (interpreter->Invoke() == kTfLiteOk) {
    TfLiteTensor *output = interpreter->output(0);
    int bestIdx = 0;
    int8_t maxScore = output->data.int8[0];
    
    for (int i = 1; i < kCategoryCount; i++) {
      if (output->data.int8[i] > maxScore) {
        maxScore = output->data.int8[i];
        bestIdx = i;
      }
    }

    lastDetectedClass = String(kCategoryLabels[bestIdx]);
    lastConfidence = (maxScore + 128) / 255.0;
    
    // Only print if significant
    if (lastConfidence > 0.6) {
      Serial.printf("🔍 AI Result: %s (%.1f%%)\n", lastDetectedClass.c_str(), lastConfidence * 100);
    }
    
    sendDetection(lastDetectedClass, lastConfidence);
  }
  esp_camera_fb_return(fb);
}

// ============================================================================
// 💾 SD CARD HANDLER
// ============================================================================
void initSDCard() {
  if(!SD_MMC.begin("/sdcard", true)){
    Serial.println("❌ SD Card Mount Failed");
    sdReady = false;
    return;
  }
  
  uint8_t cardType = SD_MMC.cardType();
  if(cardType == CARD_NONE){
    Serial.println("❌ No SD Card attached");
    sdReady = false;
    return;
  }

  Serial.println("✅ SD Card Initialized");
  sdReady = true;
  
  if(!SD_MMC.exists("/recordings")){
    SD_MMC.mkdir("/recordings");
  }
}

void saveFrameToSD(camera_fb_t * fb) {
  if (!sdReady) return;
  
  String path = "/recordings/cap_" + String(millis()) + ".jpg";
  Serial.printf("💾 Saving frame to %s\n", path.c_str());
  
  File file = SD_MMC.open(path.c_str(), FILE_WRITE);
  if(!file){
    Serial.println("❌ Failed to open file for writing");
    return;
  }
  file.write(fb->buf, fb->len);
  file.close();
  Serial.println("✅ Frame Saved");
}

// ============================================================================
// 📡 FIREBASE & STATUS UPDATES
// ============================================================================
void updateAppStatus() {
  if (Firebase.ready()) {
    FirebaseJson json;
    json.set("stream_url", "http://" + localIP + ":80/stream");
    json.set("online", true);
    json.set("stream_active", streamActive);
    json.set("siren", manualSiren);
    json.set("servo_lock", manualLock);
    json.set("sd_ready", sdReady);
    Firebase.updateNode(fbdo, "robot/status", json);
  }
}

void sendDetection(String cls, float conf) {
  if (Firebase.ready()) {
    FirebaseJson json;
    json.set("class", cls);
    json.set("confidence", conf);
    json.set("timestamp", millis());
    Firebase.setJSON(fbdo, "robot/detection", json);
  }
}

void controlActuators(bool buzzer, bool relay) {
  digitalWrite(BUZZER_PIN, buzzer);
  digitalWrite(RELAY_PIN, relay);
}

// ============================================================================
// 🏗️ INITIALIZATION
// ============================================================================
void initSystem() {
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(RELAY_PIN, OUTPUT);
  
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;
  if(psramFound()) { config.frame_size = FRAMESIZE_VGA; config.jpeg_quality = 10; config.fb_count = 2; } 
  else { config.frame_size = FRAMESIZE_SVGA; config.jpeg_quality = 12; config.fb_count = 1; }
  esp_camera_init(&config);
  
  initSDCard();

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) { delay(500); Serial.print("."); }
  localIP = WiFi.localIP().toString();
  Serial.println("\n📶 WiFi: " + localIP);

  AUTH.user.email = USER_EMAIL;
  AUTH.user.password = USER_PASSWORD;
  CONFIG.api_key = API_KEY;
  CONFIG.database_url = DATABASE_URL;
  Firebase.begin(&CONFIG, &AUTH);
  
  server.begin();
  
  static tflite::MicroErrorReporter micro_err; error_reporter = &micro_err;
  model = tflite::GetModel(g_person_detect_model_data);
  static tflite::MicroMutableOpResolver<6> res;
  res.AddAveragePool2D(); res.AddConv2D(); res.AddDepthwiseConv2D();
  res.AddReshape(); res.AddSoftmax(); res.AddFullyConnected();
  static tflite::MicroInterpreter static_int(model, res, tensor_arena, kTensorArenaSize, error_reporter);
  interpreter = &static_int; interpreter->AllocateTensors();
  input_tensor = interpreter->input(0);
}
