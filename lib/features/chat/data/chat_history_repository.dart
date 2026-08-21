import 'package:uuid/uuid.dart';

import '../../../services/database/app_database.dart';
import '../domain/chat_message.dart';

/// Backs the assistant's conversational memory with real persistence.
/// Both the Home screen's voice flow AND the Chat screen read/write the
/// SAME table, so a "good morning" said via mic today and a typed message
/// tomorrow are part of one continuous memory — not two separate contexts.
class ChatHistoryRepository {
  final _uuid = const Uuid();

  Future<void> add({required String role, required String content}) async {
    final db = await AppDatabase.instance;
    final message = ChatMessage(
      id: _uuid.v4(),
      role: role,
      content: content,
      timestamp: DateTime.now(),
    );
    await db.insert('chat_messages', message.toMap());
  }

  /// Returns the most recent [limit] messages in chronological order
  /// (oldest first) — ready to hand straight to an AiProvider as context.
  Future<List<ChatMessage>> recent({int limit = 20}) async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'chat_messages',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map(ChatMessage.fromMap).toList().reversed.toList();
  }

  Future<void> clear() async {
    final db = await AppDatabase.instance;
    await db.delete('chat_messages');
  }
}
