import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _realtime = FirebaseDatabase.instance;

  // ============================================================================
  // AUTH METHODS
  // ============================================================================

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signUp(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await saveUserProfile(credential.user!.uid, {
          'name': name,
          'email': email,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ============================================================================
  // USER PROFILES (FIRESTORE)
  // ============================================================================

  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  Future<DocumentSnapshot> getUserProfile(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  // ============================================================================
  // ROBOT STATUS & COMMANDS (REALTIME DATABASE)
  // ============================================================================

  /// Stream robot status updates
  Stream<DatabaseEvent> get robotStatusStream =>
      _realtime.ref('robot/status').onValue;

  /// Stream robot detection updates
  Stream<DatabaseEvent> get robotDetectionStream =>
      _realtime.ref('robot/detection').onValue;

  /// Stream robot detection history (last 20)
  Stream<DatabaseEvent> get robotDetectionHistoryStream => _realtime
      .ref('robot/detection_history')
      .orderByKey()
      .limitToLast(20)
      .onValue;

  /// Send a command to the robot
  Future<void> sendCommand(String command, dynamic value) async {
    await _realtime.ref('robot/commands/$command').set(value);
  }

  /// Get current robot status once
  Future<Map<String, dynamic>?> getRobotStatus() async {
    final snapshot = await _realtime.ref('robot/status').get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }

  /// Get current detection result once
  Future<Map<String, dynamic>?> getCurrentDetection() async {
    final snapshot = await _realtime.ref('robot/detection').get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }

  /// Get stream URL
  Future<String?> getStreamUrl() async {
    final snapshot = await _realtime.ref('robot/status/stream_url').get();
    if (snapshot.exists) {
      return snapshot.value as String?;
    }
    return null;
  }

  /// Set siren state
  Future<void> setSiren(bool enabled) async {
    await sendCommand('siren', enabled);
  }

  /// Trigger emergency restart
  Future<void> emergencyRestart() async {
    await sendCommand('emergency', true);
  }

  // ============================================================================
  // SECURITY LOGS (FIRESTORE)
  // ============================================================================

  Stream<QuerySnapshot> get securityLogsStream => _firestore
      .collection('logs')
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots();

  Future<void> addLog(Map<String, dynamic> logData) async {
    await _firestore.collection('logs').add({
      ...logData,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Add detection log with classification
  Future<void> addDetectionLog({
    required String detectedClass,
    required double confidence,
    String? classification,
    String? rfidCardId,
    bool? rfidAuthorized,
  }) async {
    String type = 'detection';
    String title = 'Detection Event';
    String description = '$detectedClass detected';

    if (detectedClass == 'HUMANS') {
      if (rfidAuthorized == true) {
        type = 'rfid-success';
        title = 'Authorized Access';
        description = 'RFID Card $rfidCardId verified';
      } else if (rfidAuthorized == false && rfidCardId != null) {
        type = 'rfid-fail';
        title = 'Access Denied';
        description = 'RFID Card $rfidCardId rejected';
      } else if (classification == 'Intruder') {
        type = 'intrusion';
        title = 'INTRUDER DETECTED';
        description =
            'Unauthorized human presence - ${(confidence * 100).toStringAsFixed(0)}% confidence';
      } else {
        type = 'human';
        title = 'Human Detected';
        description = 'Confidence: ${(confidence * 100).toStringAsFixed(0)}%';
      }
    } else if (detectedClass == 'ANIMALS') {
      type = 'animal';
      title = 'Animal Detected';
      description = 'Confidence: ${(confidence * 100).toStringAsFixed(0)}%';
    }

    await addLog({
      'type': type,
      'title': title,
      'description': description,
      'detectedClass': detectedClass,
      'confidence': confidence,
      'classification': classification,
    });
  }
}
