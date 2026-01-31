import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RobotProvider extends ChangeNotifier {
  // Connection Status
  bool _isOnline = false;
  String _esp32Ip = "192.168.4.1"; // Default AP IP
  String _motorIp = "192.168.4.1"; // Motor Unit

  void updateIp(String newIp) {
    _esp32Ip = newIp.trim();
    _isOnline = false; // Reset status when IP changes
    notifyListeners();
  }

  void updateMotorIp(String newIp) {
    _motorIp = newIp.trim();
    notifyListeners();
  }

  // AI Detection Results
  String _detectedClass = 'OTHERS';
  double _detectionConfidence = 0.0;
  double _humanScore = 0.0;
  double _animalScore = 0.0;
  double _otherScore = 0.0;
  int _inferenceTime = 0;
  int _uptime = 0;

  // Control States
  bool _isSirenOn = false;
  bool _flashOn = false;
  int _pan = 90;
  int _tilt = 90;

  // Hardware Status
  bool _sdReady = false;
  bool _aiReady = false;
  bool _isStreaming = false;
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
  int _connectionRetries = 0;
  static const int maxRetries = 3;

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
  double get humanScore => _humanScore;
  double get animalScore => _animalScore;
  double get otherScore => _otherScore;
  int get inferenceTime => _inferenceTime;
  int get uptime => _uptime;

  // Controls
  bool get isSirenOn => _isSirenOn;
  bool get flashOn => _flashOn;
  int get pan => _pan;
  int get tilt => _tilt;
  bool get sdReady => _sdReady;
  bool get aiReady => _aiReady;
  bool get isStreaming => _isStreaming;
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
    // Poll every 1 second for faster AI updates
    _localSyncTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      await _fetchStatus();
    });
  }

  Future<void> _fetchStatus() async {
    try {
      final response = await http
          .get(Uri.parse("http://$_esp32Ip/status"))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _isOnline = true;
        _connectionRetries = 0;
        
        // Parse AI scores
        _humanScore = (data['human'] ?? 0.0).toDouble();
        _animalScore = (data['animal'] ?? 0.0).toDouble();
        _otherScore = (data['other'] ?? 0.0).toDouble();
        
        // Class label from server
        _detectedClass = data['class'] ?? 'OTHERS';
        
        // Confidence as 0-1 value
        _detectionConfidence = (data['conf'] ?? 0.0).toDouble();
        
        // Inference time in ms
        _inferenceTime = data['time'] ?? 0;
        
        // Uptime in ms
        _uptime = data['uptime'] ?? 0;
        
        // Hardware status
        _aiReady = data['ai'] ?? false;
        _flashOn = data['flash'] ?? false;
        _isStreaming = data['streaming'] ?? false;
        _sdReady = data['sd'] ?? false;
        
        // Other fields (if available)
        _isSirenOn = data['siren'] ?? false;
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
      _connectionRetries++;
      if (_connectionRetries >= maxRetries) {
        _isOnline = false;
        notifyListeners();
      }
      debugPrint('Status fetch error: $e');
    }
  }

  // Force immediate status refresh
  Future<void> refreshStatus() async {
    await _fetchStatus();
  }

  String _computeFinalClassification() {
    // Determine highest confidence class
    if (_humanScore >= _animalScore && _humanScore >= _otherScore && _humanScore > 10) {
      return 'Human Detected';
    } else if (_animalScore >= _humanScore && _animalScore >= _otherScore && _animalScore > 10) {
      return 'Animal Detected';
    } else if (_otherScore > 10) {
      return 'Clear/Other';
    }
    return 'Scanning...';
  }

  // ============================================================================
  // FLASH CONTROL
  // ============================================================================

  Future<void> toggleFlash() async {
    try {
      final response = await http.get(
        Uri.parse("http://$_esp32Ip/flash"),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        _flashOn = response.body.trim() == 'on';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Flash toggle error: $e');
    }
  }

  Future<void> setFlash(bool on) async {
    try {
      await http.get(
        Uri.parse("http://$_esp32Ip/flash?state=${on ? '1' : '0'}"),
      ).timeout(const Duration(seconds: 5));
      _flashOn = on;
      notifyListeners();
    } catch (e) {
      debugPrint('Flash set error: $e');
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
    if (seconds < 3600) return '${seconds ~/ 60}m ${seconds % 60}s';
    return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';
  }
  
  String get formattedInferenceTime {
    return '${_inferenceTime}ms';
  }
}
