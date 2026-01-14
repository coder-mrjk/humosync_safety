import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
// import 'package:firebase_database/firebase_database.dart'; // Unused

class RobotProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  bool _isOnline = false;
  String _networkMode = 'WiFi';
  double _confidence = 0.0;
  String _detectionType = 'Scanning...';
  int _pan = 90;
  int _tilt = 90;
  bool _isSirenOn = false;
  bool _isServoLocked = true;
  String _esp32StreamUrl = '';

  // 3-Class Detection
  String _detectedClass = 'No Human';
  double _detectionConfidence = 0.0;

  // RFID Authorization
  bool _rfidRequested = false;
  String _rfidCardId = '';
  bool _rfidAuthorized = false;

  // GPS Data
  double _latitude = 0.0;
  double _longitude = 0.0;
  double _gpsAccuracy = 0.0;
  int _gpsTimestamp = 0;

  // Final Classification
  String _finalClassification = 'Scanning...';

  bool get isOnline => _isOnline;
  String get networkMode => _networkMode;
  double get confidence => _confidence;
  String get detectionType => _detectionType;
  int get pan => _pan;
  int get tilt => _tilt;
  bool get isSirenOn => _isSirenOn;
  bool get isServoLocked => _isServoLocked;
  String get esp32StreamUrl => _esp32StreamUrl;

  // 3-Class Detection
  String get detectedClass => _detectedClass;
  double get detectionConfidence => _detectionConfidence;

  // RFID Authorization
  bool get rfidRequested => _rfidRequested;
  String get rfidCardId => _rfidCardId;
  bool get rfidAuthorized => _rfidAuthorized;

  // GPS Data
  double get latitude => _latitude;
  double get longitude => _longitude;
  double get gpsAccuracy => _gpsAccuracy;
  int get gpsTimestamp => _gpsTimestamp;
  bool get hasGpsFix => _latitude != 0.0 && _longitude != 0.0;

  // Final Classification
  String get finalClassification => _finalClassification;

  RobotProvider() {
    _initStatusListener();
  }

  void _initStatusListener() {
    _firebaseService.robotStatusStream.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        _isOnline = data['online'] ?? false;
        _networkMode = data['mode'] ?? 'WiFi';
        _confidence = (data['confidence'] ?? 0.0).toDouble();
        _detectionType = data['detection'] ?? 'None';
        _isSirenOn = data['siren'] ?? false;
        _isServoLocked = data['servo_lock'] ?? true;
        _pan = data['pan'] ?? 90;
        _tilt = data['tilt'] ?? 90;
        _esp32StreamUrl = data['stream_url'] ?? '';

        // 3-Class Detection
        final detection = data['detection'] as Map?;
        if (detection != null) {
          _detectedClass = detection['class'] ?? 'No Human';
          _detectionConfidence = (detection['confidence'] ?? 0.0).toDouble();
        }

        // RFID Authorization
        final rfid = data['rfid'] as Map?;
        if (rfid != null) {
          _rfidRequested = rfid['requested'] ?? false;
          _rfidCardId = rfid['card_id'] ?? '';
          _rfidAuthorized = rfid['authorized'] ?? false;
        }

        // GPS Data
        final gps = data['gps'] as Map?;
        if (gps != null) {
          _latitude = (gps['lat'] ?? 0.0).toDouble();
          _longitude = (gps['lng'] ?? 0.0).toDouble();
          _gpsAccuracy = (gps['accuracy'] ?? 0.0).toDouble();
          _gpsTimestamp = gps['timestamp'] ?? 0;
        } else {
          // Fallback if flat structure or not present
          _latitude = (data['lat'] ?? 0.0).toDouble();
          _longitude = (data['lng'] ?? 0.0).toDouble();
        }

        // Final Classification
        _finalClassification = data['final_classification'] ?? 'Scanning...';

        notifyListeners();
      }
    });
  }

  Future<void> sendControl(String command, dynamic value) async {
    await _firebaseService.sendCommand(command, value);
    // Optimistic update for UI if needed, or wait for stream
  }

  Future<void> setPan(int value) async {
    _pan = value;
    notifyListeners();
    await sendControl('pan', value);
  }

  Future<void> setTilt(int value) async {
    _tilt = value;
    notifyListeners();
    await sendControl('tilt', value);
  }

  Future<void> toggleSiren() async {
    _isSirenOn = !_isSirenOn;
    notifyListeners();
    await sendControl('siren', _isSirenOn);
  }

  Future<void> toggleServoLock() async {
    _isServoLocked = !_isServoLocked;
    notifyListeners();
    await sendControl('servo_lock', _isServoLocked);
  }

  Future<void> triggerGesture(String gesture) async {
    await sendControl('gesture', gesture);
  }

  Future<void> triggerVoice(String voice) async {
    await sendControl('voice', voice);
  }

  Future<void> emergencyShutdown() async {
    await sendControl('emergency', true);
    // Force some local state changes for immediate feedback
    _isServoLocked = true;
    _isSirenOn = false;
    notifyListeners();
  }
}
