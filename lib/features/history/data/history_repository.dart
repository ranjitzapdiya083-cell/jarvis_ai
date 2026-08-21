import 'package:uuid/uuid.dart';

import '../../../services/database/app_database.dart';
import '../domain/history_entry.dart';

class HistoryRepository {
  final _uuid = const Uuid();

  Future<void> add({
    required String rawText,
    required String intentType,
    required bool success,
    String? resultMessage,
  }) async {
    final db = await AppDatabase.instance;
    final entry = HistoryEntry(
      id: _uuid.v4(),
      rawText: rawText,
      intentType: intentType,
      success: success,
      resultMessage: resultMessage,
      timestamp: DateTime.now(),
    );
    await db.insert('command_history', entry.toMap());
  }

  Future<List<HistoryEntry>> recent({int limit = 20}) async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'command_history',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map(HistoryEntry.fromMap).toList();
  }

  Future<void> clear() async {
    final db = await AppDatabase.instance;
    await db.delete('command_history');
  }

  Future<void> deleteOlderThan(Duration age) async {
    final db = await AppDatabase.instance;
    final cutoff = DateTime.now().subtract(age).millisecondsSinceEpoch;
    await db.delete('command_history', where: 'timestamp < ?', whereArgs: [cutoff]);
  }
}
