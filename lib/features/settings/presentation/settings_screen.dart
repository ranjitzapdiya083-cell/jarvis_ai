import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class _SettingsItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  const _SettingsItem(this.icon, this.title, this.subtitle, this.route);
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _items = [
    _SettingsItem(Icons.person_outline, 'Assistant', 'Name, personality, address', '/settings/assistant'),
    _SettingsItem(Icons.record_voice_over, 'Voice & Language', 'Voice, speed, language', '/settings/voice'),
    _SettingsItem(Icons.mic_none, 'Background Assistant', 'Wake word, sensitivity, service',
        '/settings/background-assistant'),
    _SettingsItem(Icons.smart_toy_outlined, 'AI & Conversation', 'AI model, responses, memory', '/settings/ai'),
    _SettingsItem(Icons.list_alt, 'Commands', 'Command behavior, confirmation', '/commands'),
    _SettingsItem(Icons.auto_awesome, 'Automation', 'Custom commands, workflows', '/custom-commands'),
    _SettingsItem(Icons.phonelink_setup, 'Device Control', 'Screen, volume, torch, settings',
        '/settings/device-control'),
    _SettingsItem(Icons.shield_outlined, 'Privacy & Security', 'History, data, permissions', '/permissions'),
    _SettingsItem(Icons.palette_outlined, 'Appearance', 'Theme, color, animations', '/settings/appearance'),
    _SettingsItem(Icons.info_outline, 'About JARVIS', 'Version, help, support', '/settings/about'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (context, index) {
          final item = _items[index];
          return Card(
            child: ListTile(
              leading: Icon(item.icon),
              title: Text(item.title),
              subtitle: Text(item.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                const navigable = {
                  '/commands',
                  '/custom-commands',
                  '/permissions',
                  '/settings/background-assistant',
                  '/settings/ai',
                };
                if (navigable.contains(item.route)) {
                  Navigator.pushNamed(context, item.route);
                } else {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('${item.title} — coming soon')));
                }
              },
            ),
          );
        },
      ),
    );
  }
}
