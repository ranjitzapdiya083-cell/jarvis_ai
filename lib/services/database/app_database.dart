import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Single source of truth for the local SQLite database.
/// Tables:
///  - command_history: every recognized command + outcome (spec section 21)
///  - custom_commands: user-defined commands with ordered actions (section 20)
///  - custom_command_actions: normalized child rows (one command -> many actions)
///  - chat_messages: JARVIS AI Chat transcript (section 24)
class AppDatabase {
  static Database? _db;
  static const int _version = 1;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'jarvis_ai.db');
    return openDatabase(
      path,
      version: _version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE command_history (
            id TEXT PRIMARY KEY,
            raw_text TEXT NOT NULL,
            intent_type TEXT NOT NULL,
            success INTEGER NOT NULL,
            result_message TEXT,
            timestamp INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE custom_commands (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            trigger_phrase TEXT NOT NULL,
            icon_key TEXT NOT NULL,
            color_hex TEXT NOT NULL,
            group_name TEXT,
            created_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE custom_command_actions (
            id TEXT PRIMARY KEY,
            command_id TEXT NOT NULL,
            order_index INTEGER NOT NULL,
            action_type TEXT NOT NULL,
            action_params TEXT NOT NULL,
            FOREIGN KEY (command_id) REFERENCES custom_commands (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE chat_messages (
            id TEXT PRIMARY KEY,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
      },
    );
  }
}
