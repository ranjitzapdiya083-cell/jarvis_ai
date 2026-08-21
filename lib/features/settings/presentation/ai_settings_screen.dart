import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_theme.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final _settings = ServiceLocator.instance.settingsRepository;
  final _keyController = TextEditingController();
  String _provider = 'none';
  bool _loading = true;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = await _settings.getAiProvider();
    final key = await _settings.getAiApiKey();
    if (!mounted) return;
    setState(() {
      _provider = provider;
      _keyController.text = key;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _settings.setAiProvider(_provider);
    await _settings.setAiApiKey(_keyController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI settings saved.')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI & Conversation'),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'JARVIS ki free-form conversation ke liye AI provider connect karo. '
            'Aapki API key sirf is device par local store hoti hai — kahin bhejne se pehle '
            'sirf seedha us provider ke API ko jaati hai.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            initialValue: _provider,
            decoration: const InputDecoration(labelText: 'Provider'),
            items: const [
              DropdownMenuItem(value: 'none', child: Text('None (local commands only)')),
              DropdownMenuItem(value: 'gemini', child: Text('Google Gemini')),
            ],
            onChanged: (v) => setState(() => _provider = v ?? 'none'),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_provider != 'none')
            TextField(
              controller: _keyController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'API Key',
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
