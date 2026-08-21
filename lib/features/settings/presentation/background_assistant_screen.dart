import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../background/domain/background_service_manager.dart';

class BackgroundAssistantScreen extends StatefulWidget {
  const BackgroundAssistantScreen({super.key});

  @override
  State<BackgroundAssistantScreen> createState() => _BackgroundAssistantScreenState();
}

class _BackgroundAssistantScreenState extends State<BackgroundAssistantScreen> {
  final _settings = ServiceLocator.instance.settingsRepository;
  final _serviceManager = BackgroundServiceManager();

  bool _backgroundEnabled = false;
  bool _wakeWordEnabled = true;
  bool _autoStart = false;
  double _sensitivity = 0.5;
  String _wakeWord = 'Hey JARVIS';
  bool _loading = true;
  bool _serviceRunning = false;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bg = await _settings.getBackgroundAssistantEnabled();
    final ww = await _settings.getWakeWordEnabled();
    final auto = await _settings.getAutoStartOnBoot();
    final sens = await _settings.getSensitivity();
    final word = await _settings.getWakeWord();
    final running = await _serviceManager.isRunning();
    if (!mounted) return;
    setState(() {
      _backgroundEnabled = bg;
      _wakeWordEnabled = ww;
      _autoStart = auto;
      _sensitivity = sens;
      _wakeWord = word;
      _serviceRunning = running;
      _loading = false;
    });
  }

  Future<void> _toggleBackground(bool enable) async {
    setState(() => _toggling = true);
    if (enable) {
      final result = await _serviceManager.start();
      // IMPORTANT: awaited so `_toggling` only clears AFTER the success/
      // failure branch has actually finished updating state — without this
      // `await`, the async success callback would run concurrently and
      // `_toggling` could flip back to false before `_backgroundEnabled`
      // actually updates, causing a brief incorrect UI flash.
      await result.when(
        success: (_) async {
          await _settings.setBackgroundAssistantEnabled(true);
          if (!mounted) return;
          setState(() {
            _backgroundEnabled = true;
            _serviceRunning = true;
          });
        },
        failure: (msg, _) async {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          }
        },
      );
    } else {
      await _serviceManager.stop();
      await _settings.setBackgroundAssistantEnabled(false);
      if (mounted) {
        setState(() {
          _backgroundEnabled = false;
          _serviceRunning = false;
        });
      }
    }
    if (mounted) setState(() => _toggling = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Background Assistant')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('Background Assistant'),
              subtitle: const Text('JARVIS will listen in the background'),
              value: _backgroundEnabled,
              onChanged: _toggling ? null : (v) => _toggleBackground(v),
            ),
          ),
          if (_toggling) const LinearProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text('Wake Word', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(_wakeWord),
                  subtitle: const Text('Change wake word'),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: _editWakeWord,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Wake Word'),
                  subtitle: const Text('Listen for wake word'),
                  value: _wakeWordEnabled,
                  onChanged: (v) async {
                    await _settings.setWakeWordEnabled(v);
                    if (!mounted) return;
                    setState(() => _wakeWordEnabled = v);
                  },
                ),
                ListTile(
                  title: const Text('Sensitivity'),
                  subtitle: Slider(
                    value: _sensitivity,
                    onChanged: (v) => setState(() => _sensitivity = v),
                    onChangeEnd: (v) => _settings.setSensitivity(v),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Auto Start on Boot'),
                  subtitle: const Text('Start assistant after device restart'),
                  value: _autoStart,
                  onChanged: (v) async {
                    await _settings.setAutoStartOnBoot(v);
                    if (!mounted) return;
                    setState(() => _autoStart = v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.circle, color: _serviceRunning ? AppColors.success : AppColors.darkTextTertiary, size: 12),
                  title: const Text('Service Status'),
                  trailing: Text(_serviceRunning ? 'Running' : 'Stopped'),
                ),
                ListTile(
                  leading: const Icon(Icons.hearing, size: 20),
                  title: const Text('Listening Status'),
                  trailing: Text(_wakeWordEnabled && _serviceRunning ? 'Active' : 'Inactive'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editWakeWord() async {
    final controller = TextEditingController(text: _wakeWord);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change wake word'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await _settings.setWakeWord(result.trim());
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _wakeWord = result.trim());
    }
    controller.dispose();
  }
}
