import 'package:flutter/material.dart';

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
}

class LogsProvider extends ChangeNotifier {
  final List<LogEntry> _logs = [];

  List<LogEntry> get logs => [..._logs];
  List<LogEntry> get recentLogs => _logs.take(5).toList();

  void addLocalLog(String detectedClass, double confidence) {
    String title = 'Detection Event';
    String type = 'human';

    if (detectedClass == 'HUMANS') {
      type = 'human';
      title = 'Human Detected';
    } else if (detectedClass == 'ANIMALS') {
      type = 'animal';
      title = 'Animal Detected';
    } else {
      type = 'system';
      title = 'Scanning...';
    }

    final newLog = LogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description:
          'Local sync: ${(confidence * 100).toStringAsFixed(0)}% accuracy',
      type: type,
      timestamp: DateTime.now(),
    );

    _logs.insert(0, newLog);
    if (_logs.length > 50) _logs.removeLast();

    notifyListeners();
  }

  List<LogEntry> getLogsByType(String type) {
    if (type == 'All') return _logs;
    return _logs.where((log) => log.type == type.toLowerCase()).toList();
  }
}
