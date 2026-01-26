#include <WebServer.h>
#include <WiFi.h>
#include "esp_camera.h"
#include "img_converters.h"

// TensorFlow Lite for Microcontrollers
#include <TensorFlowLite_ESP32.h>
#include "tensorflow/lite/micro/all_ops_resolver.h"
#include "tensorflow/lite/micro/micro_error_reporter.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/schema/schema_generated.h"
// #include "tensorflow/lite/version.h" 

#include "model_settings.h"
#include "person_detect_model_data.h"
#include "index_html.h"

// Select camera model
#define CAMERA_MODEL_AI_THINKER
#include "camera_pins.h"

// Network Credentials - CHANGE THESE IF NEEDED OR USE AP
const char* ssid = "Your_SSID";
const char* password = "Your_PASSWORD";

// Web Server
WebServer server(80);

// Global Variables for Inference
tflite::ErrorReporter* error_reporter = nullptr;
const tflite::Model* model = nullptr;
tflite::MicroInterpreter* interpreter = nullptr;
TfLiteTensor* input = nullptr;
TfLiteTensor* output = nullptr;

// Tensor Arena (Memory for TFLite)
// Allocated in PSRAM if available, otherwise strict limits apply
constexpr int kTensorArenaSize = 60 * 1024; 
uint8_t *tensor_arena;

// Inference Results
float score_human = 0;
float score_animal = 0;
float score_other = 0;
unsigned long inference_time = 0;

// Camera Config
void configCamera() {
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
  
  if (psramFound()) {
    config.frame_size = FRAMESIZE_QVGA; // 320x240
    config.jpeg_quality = 10;
    config.fb_count = 2;
    config.grab_mode = CAMERA_GRAB_LATEST;
  } else {
    config.frame_size = FRAMESIZE_QVGA;
    config.jpeg_quality = 12;
    config.fb_count = 1;
  }

  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Camera init failed with error 0x%x", err);
    return;
  }
}

// Helper to Resize and convert to input tensor
void processImage(camera_fb_t *fb) {
  unsigned long start_time = millis();
  
  // We need to decode JPEG to RGB888
  // Use built-in jpg2rgb converter
  uint8_t *rgb_buf = (uint8_t *)heap_caps_malloc(320 * 240 * 3, MALLOC_CAP_SPIRAM);
  if (!rgb_buf) {
    Serial.println("Malloc failed for RGB buffer");
    return;
  }

  bool converted = fmt2rgb888(fb->buf, fb->len, PIXFORMAT_JPEG, rgb_buf);
  if (!converted) {
    Serial.println("JPEG decode failed");
    free(rgb_buf);
    return;
  }

  // Resize 320x240 -> 96x96 and convert to signed 8-bit
  // Simple nearest neighbor or bilinear. Nearest is faster.
  // We can also crop to center to avoid distortion if aspect ratio differs.
  // 320/240 = 1.33, 96/96 = 1.0. 
  // Let's crop central 240x240 then resize to 96x96? 
  // Or just resize whole image (squash). Squashing 320x240 to 96x96 might distort a bit but is easiest.
  
  int src_w = 320;
  int src_h = 240;
  int dst_w = kNumCols; // 96
  int dst_h = kNumRows; // 96
  
  // Naive resize
  for (int y = 0; y < dst_h; y++) {
    for (int x = 0; x < dst_w; x++) {
      int src_x = x * src_w / dst_w;
      int src_y = y * src_h / dst_h;
      
      int src_idx = (src_y * src_w + src_x) * 3;
      
      uint8_t r = rgb_buf[src_idx];
      uint8_t g = rgb_buf[src_idx + 1];
      uint8_t b = rgb_buf[src_idx + 2];

      // Grayscale conversion
      float gray = (0.2126 * r) + (0.7152 * g) + (0.0722 * b);
      
      // Quantize to int8 (-128 to 127)
      int8_t val = (int8_t)(gray - 128);
      
      input->data.int8[y * dst_w + x] = val;
    }
  }
  
  free(rgb_buf);

  // Run Inference
  TfLiteStatus invoke_status = interpreter->Invoke();
  if (invoke_status != kTfLiteOk) {
    Serial.println("Invoke failed");
    return;
  }

  // Parse Output
  // Assuming output order matches kCategoryLabels: ANIMALS, HUMANS, OTHERS
  // But wait, kPersonIndex=1.
  // Let's assume the model outputs probabilities (Softmax) or raw scores.
  // Usually int8 outputs are -128 to 127.
  // The 'tm_template_script.ino' treated them as uint8?
  // "int8_t person_score = output->data.uint8[kPersonIndex];" -> Accessing union as uint8? 
  // In TFLite Micro, tensor->data.int8 is the standard for quantized.
  // However, TM (Teachable Machine) models often export as uint8 (0-255) OR int8 (-128-127).
  // The provided code used: `output->data.uint8[i]`
  
  int8_t out_0 = output->data.int8[0]; 
  int8_t out_1 = output->data.int8[1]; 
  int8_t out_2 = output->data.int8[2];
  
  // Unquantize roughly to 0-100%
  // Usually (val - zero_point) * scale. 
  // For simplicity relative comparison, we can treat them as raw scores.
  // If uint8, 0..255. If int8, -128..127.
  // Let's treat as uint8 to be safe given the previous code snippet?
  // Previous code: `output->data.uint8`. 
  // Let's interpret as 0-255 (add 128 if it was int8).
  
  int score0 = (output->type == kTfLiteInt8) ? (output->data.int8[0] + 128) : output->data.uint8[0];
  int score1 = (output->type == kTfLiteInt8) ? (output->data.int8[1] + 128) : output->data.uint8[1];
  int score2 = (output->type == kTfLiteInt8) ? (output->data.int8[2] + 128) : output->data.uint8[2];

  int total = score0 + score1 + score2;
  if (total == 0) total = 1;

  // ANIMALS (0), HUMANS (1), OTHERS (2) - Based on model_settings.cpp
  score_animal = (score0 * 100.0) / total;
  score_human  = (score1 * 100.0) / total;
  score_other  = (score2 * 100.0) / total;

  inference_time = millis() - start_time;
  Serial.printf("Humans: %.1f%%, Animals: %.1f%%, Others: %.1f%% (%lums)\n", score_human, score_animal, score_other, inference_time);
}


void setup() {
  Serial.begin(115200);
  
  // 1. Init Camera
  configCamera();

  // 2. Init WiFi
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  int tries = 0;
  while (WiFi.status() != WL_CONNECTED && tries < 20) {
    delay(500);
    Serial.print(".");
    tries++;
  }
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("\nStarting AP Mode...");
    WiFi.softAP("ESP32-CAM-SAFE", "12345678");
    Serial.println(WiFi.softAPIP());
  } else {
    Serial.println("");
    Serial.println(WiFi.localIP());
  }

  // 3. Init TFLite
  tensor_arena = (uint8_t *)heap_caps_malloc(kTensorArenaSize, MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT);
  if (!tensor_arena) {
    tensor_arena = (uint8_t *)malloc(kTensorArenaSize); // Fallback to internal RAM
  }
  
  static tflite::MicroErrorReporter micro_error_reporter;
  error_reporter = &micro_error_reporter;

  model = tflite::GetModel(g_person_detect_model_data);
  if (model->version() != TFLITE_SCHEMA_VERSION) {
    Serial.println("Model schema version mismatch!");
    return;
  }

  // Pull in all ops
  static tflite::AllOpsResolver resolver; // Use AllOps for compatibility

  static tflite::MicroInterpreter static_interpreter(
      model, resolver, tensor_arena, kTensorArenaSize, error_reporter);
  interpreter = &static_interpreter;

  if (interpreter->AllocateTensors() != kTfLiteOk) {
    Serial.println("AllocateTensors failed!");
    return;
  }

  input = interpreter->input(0);
  output = interpreter->output(0);
  
  Serial.println("TFLite initialized.");

  // 4. Init Web Server
  server.on("/", HTTP_GET, []() {
    server.send_P(200, "text/html", index_html);
  });

  server.on("/status", HTTP_GET, []() {
    String json = "{";
    json += "\"human\":" + String(score_human) + ",";
    json += "\"animal\":" + String(score_animal) + ",";
    json += "\"other\":" + String(score_other) + ",";
    json += "\"time\":" + String(inference_time);
    json += "}";
    server.send(200, "application/json", json);
  });

  server.on("/stream", HTTP_GET, []() {
    WiFiClient client = server.client();
    String response = "HTTP/1.1 200 OK\r\n";
    response += "Content-Type: multipart/x-mixed-replace; boundary=frame\r\n\r\n";
    server.sendContent(response);

    while (client.connected()) {
      camera_fb_t *fb = esp_camera_fb_get();
      if (!fb) {
        Serial.println("Frame buffer could not be acquired");
        continue;
      }
      
      // Run inference on this frame occasionally? 
      // Running on every frame kills framerate. 
      // Let's run every 3rd frame or based on time.
      static unsigned long last_inf = 0;
      if (millis() - last_inf > 200) { // Max 5 fps inference
        processImage(fb);
        last_inf = millis();
      }

      String head = "--frame\r\nContent-Type: image/jpeg\r\n\r\n";
      server.sendContent(head);
      client.write(fb->buf, fb->len);
      server.sendContent("\r\n");
      
      esp_camera_fb_return(fb);
      delay(1); // Give others a chance
    }
  });

  server.begin();
  Serial.println("Web server started");
}

void loop() {
  server.handleClient();
}
