import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class _CommandCategoryItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _CommandCategoryItem(this.icon, this.title, this.subtitle, this.color);
}

class CommandsScreen extends StatefulWidget {
  const CommandsScreen({super.key});

  @override
  State<CommandsScreen> createState() => _CommandsScreenState();
}

class _CommandsScreenState extends State<CommandsScreen> {
  String _query = '';
  int _tabIndex = 0;
  final _tabs = ['All', 'Apps', 'Device', 'System', 'AI'];

  static const _items = [
    _CommandCategoryItem(Icons.apps, 'Open App', 'Open any application', AppColors.electricBlue),
    _CommandCategoryItem(Icons.call, 'Make Call', 'Call any contact', AppColors.success),
    _CommandCategoryItem(Icons.message, 'Send Message', 'Send SMS or WhatsApp', Color(0xFF25D366)),
    _CommandCategoryItem(Icons.settings, 'Device Control', 'Control phone settings', AppColors.purple),
    _CommandCategoryItem(Icons.music_note, 'Music & Video', 'Play music or video', Color(0xFFFF0000)),
    _CommandCategoryItem(Icons.navigation, 'Navigation', 'Open Maps & locations', Color(0xFF34A853)),
    _CommandCategoryItem(Icons.alarm, 'Alarm & Reminder', 'Set alarm or reminder', AppColors.warning),
    _CommandCategoryItem(Icons.info_outline, 'Information', 'Get device information', AppColors.electricBlue),
    _CommandCategoryItem(Icons.brightness_6, 'Screen Control', 'Control screen & display', AppColors.purple),
    _CommandCategoryItem(Icons.auto_awesome, 'Automation', 'Custom commands', AppColors.electricBlue),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _items
        .where((i) => i.title.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Commands')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search commands...',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, index) {
                final selected = index == _tabIndex;
                return ChoiceChip(
                  label: Text(_tabs[index]),
                  selected: selected,
                  onSelected: (_) => setState(() => _tabIndex = index),
                  selectedColor: AppColors.electricBlue,
                  labelStyle: TextStyle(color: selected ? Colors.white : null),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: item.color),
                    ),
                    title: Text(item.title),
                    subtitle: Text(item.subtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
