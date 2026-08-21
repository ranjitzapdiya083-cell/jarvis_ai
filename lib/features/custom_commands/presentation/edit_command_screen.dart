import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/custom_command.dart';

/// Supported action types a custom command can chain — each maps 1:1 to a
/// real branch in CommandExecutor / DeviceControlService / AppLauncherService.
const _actionTypes = <String, String>{
  'open_app': 'Open App',
  'set_volume': 'Set Volume',
  'torch_on': 'Torch On',
  'torch_off': 'Torch Off',
  'web_search': 'Web Search',
};

class EditCommandScreen extends StatefulWidget {
  final String? commandId;
  const EditCommandScreen({super.key, this.commandId});

  @override
  State<EditCommandScreen> createState() => _EditCommandScreenState();
}

class _EditCommandScreenState extends State<EditCommandScreen> {
  final _repo = ServiceLocator.instance.customCommandRepository;
  final _nameController = TextEditingController();
  final _triggerController = TextEditingController();
  final List<CustomCommandAction> _actions = [];
  bool _loading = true;

  bool get _isEditing => widget.commandId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_isEditing) {
      final cmd = await _repo.getById(widget.commandId!);
      if (cmd != null) {
        _nameController.text = cmd.name;
        _triggerController.text = cmd.triggerPhrase;
        _actions.addAll(cmd.actions);
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _triggerController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty || _triggerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Command name aur trigger phrase dono zaroori hain.')));
      return;
    }
    if (_isEditing) {
      await _repo.update(
        id: widget.commandId!,
        name: _nameController.text.trim(),
        triggerPhrase: _triggerController.text.trim(),
        actions: _actions,
      );
    } else {
      await _repo.create(
        name: _nameController.text.trim(),
        triggerPhrase: _triggerController.text.trim(),
        iconKey: 'bolt',
        colorHex: '#3D8BFF',
        actions: _actions,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (!_isEditing) return;
    await _repo.delete(widget.commandId!);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _addAction() async {
    String? selectedType = _actionTypes.keys.first;
    final paramController = TextEditingController();

    final result = await showDialog<CustomCommandAction>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Action'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                items: _actionTypes.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedType = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: paramController,
                decoration: const InputDecoration(labelText: 'Parameter (e.g. app name / volume %)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                CustomCommandAction(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  orderIndex: _actions.length,
                  actionType: selectedType!,
                  params: {'value': paramController.text.trim()},
                ),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() => _actions.add(result));
    }
    paramController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Command' : 'New Command'),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Command Name'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _triggerController,
            decoration: const InputDecoration(labelText: 'When I say', hintText: 'e.g. study mode start karo'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Actions (${_actions.length})', style: Theme.of(context).textTheme.titleMedium),
              IconButton(icon: const Icon(Icons.add), onPressed: _addAction),
            ],
          ),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _actions.removeAt(oldIndex);
                _actions.insert(newIndex, item);
              });
            },
            children: [
              for (int i = 0; i < _actions.length; i++)
                Card(
                  key: ValueKey(_actions[i].id),
                  child: ListTile(
                    leading: const Icon(Icons.drag_indicator),
                    title: Text(_actionTypes[_actions[i].actionType] ?? _actions[i].actionType),
                    subtitle: Text(_actions[i].params['value'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _actions.removeAt(i)),
                    ),
                  ),
                ),
            ],
          ),
          if (_isEditing) ...[
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              onPressed: _delete,
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
              child: const Text('Delete Command'),
            ),
          ],
        ],
      ),
    );
  }
}
