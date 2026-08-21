import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/custom_command.dart';
import 'edit_command_screen.dart';

class CustomCommandsScreen extends StatefulWidget {
  const CustomCommandsScreen({super.key});

  @override
  State<CustomCommandsScreen> createState() => _CustomCommandsScreenState();
}

class _CustomCommandsScreenState extends State<CustomCommandsScreen> {
  final _repo = ServiceLocator.instance.customCommandRepository;
  List<CustomCommand> _commands = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await _repo.getAll();
    if (!mounted) return;
    setState(() {
      _commands = all;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Command'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditCommandScreen()),
              );
              _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _commands.isEmpty
              ? Center(
                  child: Text(
                    'Abhi koi custom command nahi hai.\n"+" dabao aur pehla command banao.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _commands.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final c = _commands[index];
                    return Card(
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.electricBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.bolt, color: AppColors.electricBlue),
                        ),
                        title: Text(c.name),
                        subtitle: Text('${c.actions.length} actions'),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _showMenu(c),
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EditCommandScreen(commandId: c.id)),
                          );
                          _load();
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditCommandScreen()));
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Create New Command'),
      ),
    );
  }

  void _showMenu(CustomCommand c) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditCommandScreen(commandId: c.id)),
                );
                _load();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                await _repo.delete(c.id);
                _load();
              },
            ),
          ],
        ),
      ),
    );
  }
}
