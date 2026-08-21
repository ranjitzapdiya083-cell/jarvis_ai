class CustomCommandAction {
  final String id;
  final int orderIndex;
  final String actionType; // e.g. "open_app", "set_volume", "start_timer"
  final Map<String, String> params;

  const CustomCommandAction({
    required this.id,
    required this.orderIndex,
    required this.actionType,
    required this.params,
  });
}

class CustomCommand {
  final String id;
  final String name;
  final String triggerPhrase;
  final String iconKey;
  final String colorHex;
  final String? groupName;
  final DateTime createdAt;
  final List<CustomCommandAction> actions;

  const CustomCommand({
    required this.id,
    required this.name,
    required this.triggerPhrase,
    required this.iconKey,
    required this.colorHex,
    required this.createdAt,
    this.groupName,
    this.actions = const [],
  });
}
