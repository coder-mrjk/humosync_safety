import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _realtime = FirebaseDatabase.instance;

  // --- Auth Methods ---
  Stream<User?> get authStateChanges => _auth.authStateChanges();

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

  // --- Firestore (User Profiles) ---
  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  Future<DocumentSnapshot> getUserProfile(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  // --- Realtime DB (Robot Status & Commands) ---
  Stream<DatabaseEvent> get robotStatusStream =>
      _realtime.ref('robot/status').onValue;

  Future<void> sendCommand(String command, dynamic value) async {
    await _realtime.ref('robot/commands/$command').set(value);
  }

  // --- Firestore (Logs) ---
  Stream<QuerySnapshot> get securityLogsStream => _firestore
      .collection('logs')
      .orderBy('timestamp', descending: true)
      .snapshots();

  Future<void> addLog(Map<String, dynamic> logData) async {
    await _firestore.collection('logs').add({
      ...logData,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
