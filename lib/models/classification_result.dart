class ClassificationResult {
  final String label;
  final double confidence;
  final DateTime timestamp;

  ClassificationResult({
    required this.label,
    required this.confidence,
    required this.timestamp,
  });

  factory ClassificationResult.fromMap(Map<String, dynamic> map) {
    return ClassificationResult(
      label: map['label'] ?? 'Unknown',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'confidence': confidence,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
