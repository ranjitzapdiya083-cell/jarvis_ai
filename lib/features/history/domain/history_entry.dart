class HistoryEntry {
  final String id;
  final String rawText;
  final String intentType;
  final bool success;
  final String? resultMessage;
  final DateTime timestamp;

  const HistoryEntry({
    required this.id,
    required this.rawText,
    required this.intentType,
    required this.success,
    required this.timestamp,
    this.resultMessage,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'raw_text': rawText,
        'intent_type': intentType,
        'success': success ? 1 : 0,
        'result_message': resultMessage,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory HistoryEntry.fromMap(Map<String, dynamic> map) => HistoryEntry(
        id: map['id'] as String,
        rawText: map['raw_text'] as String,
        intentType: map['intent_type'] as String,
        success: (map['success'] as int) == 1,
        resultMessage: map['result_message'] as String?,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      );
}
