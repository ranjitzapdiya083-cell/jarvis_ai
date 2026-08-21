import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../services/database/app_database.dart';
import '../domain/custom_command.dart';

class CustomCommandRepository {
  final _uuid = const Uuid();

  Future<String> create({
    required String name,
    required String triggerPhrase,
    required String iconKey,
    required String colorHex,
    String? groupName,
    required List<CustomCommandAction> actions,
  }) async {
    final db = await AppDatabase.instance;
    final id = _uuid.v4();

    await db.transaction((txn) async {
      await txn.insert('custom_commands', {
        'id': id,
        'name': name,
        'trigger_phrase': triggerPhrase,
        'icon_key': iconKey,
        'color_hex': colorHex,
        'group_name': groupName,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

      for (var i = 0; i < actions.length; i++) {
        final action = actions[i];
        await txn.insert('custom_command_actions', {
          'id': _uuid.v4(),
          'command_id': id,
          'order_index': i,
          'action_type': action.actionType,
          'action_params': jsonEncode(action.params),
        });
      }
    });

    return id;
  }

  Future<List<CustomCommand>> getAll() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('custom_commands', orderBy: 'created_at DESC');

    final result = <CustomCommand>[];
    for (final row in rows) {
      final actions = await _loadActions(db, row['id'] as String);
      result.add(_fromRow(row, actions));
    }
    return result;
  }

  Future<CustomCommand?> getById(String id) async {
    final db = await AppDatabase.instance;
    final rows = await db.query('custom_commands', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final actions = await _loadActions(db, id);
    return _fromRow(rows.first, actions);
  }

  Future<void> update({
    required String id,
    required String name,
    required String triggerPhrase,
    required List<CustomCommandAction> actions,
  }) async {
    final db = await AppDatabase.instance;
    await db.transaction((txn) async {
      await txn.update(
        'custom_commands',
        {'name': name, 'trigger_phrase': triggerPhrase},
        where: 'id = ?',
        whereArgs: [id],
      );
      await txn.delete('custom_command_actions', where: 'command_id = ?', whereArgs: [id]);
      for (var i = 0; i < actions.length; i++) {
        final action = actions[i];
        await txn.insert('custom_command_actions', {
          'id': _uuid.v4(),
          'command_id': id,
          'order_index': i,
          'action_type': action.actionType,
          'action_params': jsonEncode(action.params),
        });
      }
    });
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance;
    await db.transaction((txn) async {
      await txn.delete('custom_command_actions', where: 'command_id = ?', whereArgs: [id]);
      await txn.delete('custom_commands', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<CustomCommandAction>> _loadActions(Database db, String commandId) async {
    final rows = await db.query(
      'custom_command_actions',
      where: 'command_id = ?',
      whereArgs: [commandId],
      orderBy: 'order_index ASC',
    );
    return rows
        .map((r) => CustomCommandAction(
              id: r['id'] as String,
              orderIndex: r['order_index'] as int,
              actionType: r['action_type'] as String,
              params: Map<String, String>.from(jsonDecode(r['action_params'] as String) as Map),
            ))
        .toList();
  }

  CustomCommand _fromRow(Map<String, dynamic> row, List<CustomCommandAction> actions) {
    return CustomCommand(
      id: row['id'] as String,
      name: row['name'] as String,
      triggerPhrase: row['trigger_phrase'] as String,
      iconKey: row['icon_key'] as String,
      colorHex: row['color_hex'] as String,
      groupName: row['group_name'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      actions: actions,
    );
  }
}
