import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LogEntry {
  final String id;
  final String title;
  final String description;
  final String type;
  final DateTime timestamp;
  final String? imageUrl;

  LogEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.timestamp,
    this.imageUrl,
  });

  factory LogEntry.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return LogEntry(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'system',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['image_url'],
    );
  }
}

class LogsProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<LogEntry> _logs = [];

  List<LogEntry> get logs => _logs;
  List<LogEntry> get recentLogs => _logs.take(5).toList();

  LogsProvider() {
    _initLogsListener();
  }

  void _initLogsListener() {
    _firebaseService.securityLogsStream.listen((snapshot) {
      _logs = snapshot.docs.map((doc) => LogEntry.fromFirestore(doc)).toList();
      notifyListeners();
    });
  }

  List<LogEntry> getLogsByType(String type) {
    if (type == 'All') return _logs;
    return _logs.where((log) => log.type == type.toLowerCase()).toList();
  }
}
