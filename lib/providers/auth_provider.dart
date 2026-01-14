import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  User? _user;
  String? _userName;
  String? _userRole;
  String? _bio;
  String? _avatarUrl;
  bool _isLoading = false;

  User? get user => _user;
  String? get userName => _userName;
  String? get userRole => _userRole;
  String? get bio => _bio;
  String? get avatarUrl => _avatarUrl;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _firebaseService.authStateChanges.listen((User? user) async {
      _user = user;
      if (user != null) {
        await _fetchProfile(user.uid);
      } else {
        _userName = null;
        _userRole = null;
        _bio = null;
        _avatarUrl = null;
      }
      notifyListeners();
    });
  }

  Future<void> _fetchProfile(String uid) async {
    try {
      final doc = await _firebaseService.getUserProfile(uid);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _userName = data['name'];
        _userRole = data['role'];
        _bio = data['bio'];
        _avatarUrl = data['avatarUrl'];
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    String? avatarUrl,
  }) async {
    if (_user == null) return;
    _setLoading(true);
    try {
      final updates = <String, dynamic>{};
      if (name != null) {
        updates['name'] = name;
        _userName = name;
      }
      if (bio != null) {
        updates['bio'] = bio;
        _bio = bio;
      }
      if (avatarUrl != null) {
        updates['avatarUrl'] = avatarUrl;
        _avatarUrl = avatarUrl;
      }

      if (updates.isNotEmpty) {
        await _firebaseService.saveUserProfile(_user!.uid, updates);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      await _firebaseService.signIn(email, password);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  Future<void> register(String email, String password, String name) async {
    _setLoading(true);
    try {
      await _firebaseService.signUp(email, password, name);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  Future<void> logout() async {
    await _firebaseService.signOut();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
