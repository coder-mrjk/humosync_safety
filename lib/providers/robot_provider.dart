import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RobotProvider extends ChangeNotifier {
  // Connection Status
  bool _isOnline = false;
  String _esp32Ip = "10.118.36.123"; // Camera/AI Unit
  String _motorIp = "192.168.4.1"; // Motor Unit (Default to AP IP)

  void updateIp(String newIp) {
    _esp32Ip = newIp;
    notifyListeners();
  }

  void updateMotorIp(String newIp) {
    _motorIp = newIp;
    notifyListeners();
  }

  // AI Detection Results
  String _detectedClass = 'OTHERS';
  double _detectionConfidence = 0.0;
  int _uptime = 0;

  // Control States
  bool _isSirenOn = false;
  int _pan = 90;
  int _tilt = 90;

  // Hardware Status
  bool _sdReady = false;
  bool _aiReady = false;
  int _recordingCount = 0;

  // RFID Authorization
  bool _rfidRequested = false;
  String _rfidCardId = '';
  bool _rfidAuthorized = false;

  // GPS Data
  double _latitude = 0.0;
  double _longitude = 0.0;
  double _gpsAccuracy = 0.0;
  final int _gpsTimestamp = 0;

  // Final Classification (computed)
  String _finalClassification = 'Scanning...';

  // Local Sync
  Timer? _localSyncTimer;

  // ============================================================================
  // GETTERS
  // ============================================================================

  bool get isOnline => _isOnline;
  String get esp32Ip => _esp32Ip;
  String get motorIp => _motorIp;
  String get esp32StreamUrl => "http://$_esp32Ip/stream";
  String get networkMode => "Local WiFi";

  // AI Detection
  String get detectedClass => _detectedClass;
  double get detectionConfidence => _detectionConfidence;
  int get uptime => _uptime;

  // Controls
  bool get isSirenOn => _isSirenOn;
  int get pan => _pan;
  int get tilt => _tilt;
  bool get sdReady => _sdReady;
  bool get aiReady => _aiReady;
  int get recordingCount => _recordingCount;
  String get finalClassification => _finalClassification;

  // RFID
  bool get rfidRequested => _rfidRequested;
  String get rfidCardId => _rfidCardId;
  bool get rfidAuthorized => _rfidAuthorized;

  // GPS
  double get latitude => _latitude;
  double get longitude => _longitude;
  double get gpsAccuracy => _gpsAccuracy;
  int get gpsTimestamp => _gpsTimestamp;
  bool get hasGpsFix => _latitude != 0.0 && _longitude != 0.0;

  // Legacy for compatibility
  double get confidence => _detectionConfidence;
  String get confidencePercent =>
      '${(_detectionConfidence * 100).toStringAsFixed(0)}%';

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  RobotProvider() {
    _startLocalSync();
  }

  void _startLocalSync() {
    _localSyncTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final response = await http
            .get(Uri.parse("http://$_esp32Ip/status"))
            .timeout(const Duration(seconds: 1));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          _isOnline = true;
          _detectedClass = data['class'] ?? 'OTHERS';
          _detectionConfidence = (data['conf'] ?? 0.0).toDouble();
          _uptime = data['uptime'] ?? 0;
          _isSirenOn = data['siren'] ?? false;
          _sdReady = data['sd'] ?? false;
          _aiReady = data['ai'] ?? false;
          _recordingCount = data['rec_cnt'] ?? 0;
          _pan = data['pan'] ?? 90;
          _tilt = data['tilt'] ?? 90;
          _rfidRequested = data['rfid_req'] ?? false;
          _rfidCardId = data['rfid_id'] ?? '';
          _rfidAuthorized = data['rfid_auth'] ?? false;
          _latitude = (data['lat'] ?? 0.0).toDouble();
          _longitude = (data['lng'] ?? 0.0).toDouble();
          _gpsAccuracy = (data['gps_acc'] ?? 0.0).toDouble();

          _finalClassification = _computeFinalClassification();
          notifyListeners();
        }
      } catch (e) {
        _isOnline = false;
        notifyListeners();
      }
    });
  }

  String _computeFinalClassification() {
    // Match model labels: ANIMALS, HUMAN, OTHERS
    if (_detectedClass == 'HUMAN' || _detectedClass == 'HUMANS') {
      return 'Human Detected';
    } else if (_detectedClass == 'ANIMALS') {
      return 'Animal Detected';
    } else {
      return 'Scanning...';
    }
  }

  // ============================================================================
  // COMMAND METHODS
  // ============================================================================

  Future<void> sendControl(String command, dynamic value) async {
    try {
      await http.get(
        Uri.parse("http://$_esp32Ip/control?cmd=$command&val=$value"),
      );
      if (command == 'siren') _isSirenOn = (value == 1 || value == true);
      if (command == 'pan') _pan = value;
      if (command == 'tilt') _tilt = value;
      notifyListeners();
    } catch (e) {
      debugPrint('Control error: $e');
    }
  }

  Future<void> setSiren(bool value) async {
    await sendControl('siren', value ? 1 : 0);
  }

  Future<void> toggleSiren() async {
    await setSiren(!_isSirenOn);
  }

  // ============================================================================
  // MOVEMENT CONTROLS (v1 - CAR_MOVE Integration)
  // ============================================================================

  String _lastCommand = '';

  Future<void> moveForward() async {
    try {
      await http.get(Uri.parse("http://$_motorIp/forward"));
      notifyListeners();
    } catch (e) {
      debugPrint('Move Error: $e');
    }
  }

  Future<void> moveBackward() async {
    try {
      await http.get(Uri.parse("http://$_motorIp/backward"));
      notifyListeners();
    } catch (e) {
      debugPrint('Move Error: $e');
    }
  }

  Future<void> turnLeft() async {
    try {
      await http.get(Uri.parse("http://$_motorIp/left"));
      notifyListeners();
    } catch (e) {
      debugPrint('Move Error: $e');
    }
  }

  Future<void> turnRight() async {
    try {
      await http.get(Uri.parse("http://$_motorIp/right"));
      notifyListeners();
    } catch (e) {
      debugPrint('Move Error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await http.get(Uri.parse("http://$_motorIp/stop"));
      notifyListeners();
    } catch (e) {
      debugPrint('Move Error: $e');
    }
  }

  Future<void> setSpeed(int speed) async {
    try {
      await http.get(Uri.parse("http://$_motorIp/speed?value=$speed"));
      notifyListeners();
    } catch (e) {
      debugPrint('Speed Error: $e');
    }
  }

  // Joystick Input Handler
  // Maps X/Y (-1.0 to 1.0) to Discrete Commands
  void handleJoystick(double x, double y) {
    String command = 'stop';

    if (y < -0.5) {
      command = 'forward';
    } else if (y > 0.5) {
      command = 'backward';
    } else if (x < -0.5) {
      command = 'left';
    } else if (x > 0.5) {
      command = 'right';
    }

    if (command != _lastCommand) {
      _lastCommand = command;
      switch (command) {
        case 'forward':
          moveForward();
          break;
        case 'backward':
          moveBackward();
          break;
        case 'left':
          turnLeft();
          break;
        case 'right':
          turnRight();
          break;
        case 'stop':
          stop();
          break;
      }
    }
  }

  // Stubs for remaining UI controls
  Future<void> setPan(int val) async {}
  Future<void> setTilt(int val) async {}
  Future<void> triggerGesture(String g) async {}
  Future<void> triggerVoice(String v) async {}
  Future<void> emergencyShutdown() async {}

  @override
  void dispose() {
    _localSyncTimer?.cancel();
    super.dispose();
  }

  // ============================================================================
  // UI HELPERS
  // ============================================================================

  Color get detectionColor {
    switch (_detectedClass.toUpperCase()) {
      case 'HUMAN':
      case 'HUMANS':
        return const Color(0xFF3B82F6);
      case 'ANIMALS':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color get confidenceColor {
    if (_detectionConfidence > 0.7) return const Color(0xFF10B981);
    if (_detectionConfidence > 0.4) return const Color(0xFFF59E0B);
    return const Color(0xFF94A3B8);
  }

  String get formattedUptime {
    final seconds = _uptime ~/ 1000;
    if (seconds < 60) return '${seconds}s';
    return '${seconds ~/ 60}m ${seconds % 60}s';
  }
}
