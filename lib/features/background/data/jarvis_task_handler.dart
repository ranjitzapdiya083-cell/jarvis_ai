import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../commands/domain/command_executor.dart';
import '../../contacts/data/contact_service_impl.dart';
import '../../chat/data/chat_history_repository.dart';
import '../../device/data/app_launcher_service.dart';
import '../../device/data/device_control_service_impl.dart';
import '../../history/data/history_repository.dart';
import '../../settings/data/settings_repository.dart';
import '../../ai/data/gemini_provider.dart';
import '../../ai/data/local_fallback_provider.dart';
import '../../voice/data/tts_service_impl.dart';
import '../../voice/data/wake_word_service_impl.dart';

/// Runs inside the background isolate spawned by flutter_foreground_task.
/// This is what actually keeps "Hey JARVIS" listening alive even when the
/// app UI is closed/minimized — backed by a REAL Android foreground
/// service + persistent notification (required by Android since API 26,
/// spec section 7). It re-builds its own small dependency graph because a
/// background isolate cannot share objects/state with the UI isolate.
@pragma('vm:entry-point')
void startBackgroundTaskHandler() {
  FlutterForegroundTask.setTaskHandler(JarvisTaskHandler());
}

class JarvisTaskHandler extends TaskHandler {
  final _settings = SettingsRepository();
  final _wakeWordService = WakeWordServiceImpl();
  final _tts = TtsServiceImpl();
  late final CommandExecutor _executor;
  bool _busy = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _tts.initialize();

    final provider = await _settings.getAiProvider();
    final apiKey = await _settings.getAiApiKey();
    final assistantName = await _settings.getAssistantName();
    final userAddress = await _settings.getUserAddress();
    final wakeWord = await _settings.getWakeWord();

    _executor = CommandExecutor(
      device: DeviceControlServiceImpl(),
      launcher: AppLauncherService(),
      history: HistoryRepository(),
      contacts: ContactServiceImpl(),
      chatHistory: ChatHistoryRepository(),
      aiProviderResolver: () => (provider == 'gemini' && apiKey.trim().isNotEmpty)
          ? GeminiProvider(apiKey: apiKey)
          : LocalFallbackProvider(),
      assistantName: assistantName,
      userAddress: userAddress,
    );

    final result = await _wakeWordService.start(
      wakeWord: wakeWord,
      onWake: _handleWake,
      onError: (err) => FlutterForegroundTask.updateService(
        notificationTitle: 'JARVIS AI',
        notificationText: 'Listening error: $err — retrying...',
      ),
    );

    result.when(
      success: (_) => FlutterForegroundTask.updateService(
        notificationTitle: 'JARVIS AI — Active',
        notificationText: 'Listening for "$wakeWord"...',
      ),
      failure: (msg, _) => FlutterForegroundTask.updateService(
        notificationTitle: 'JARVIS AI — Error',
        notificationText: msg,
      ),
    );
  }

  Future<void> _handleWake(String fullTranscript) async {
    if (_busy) return;
    _busy = true;

    // Turn the screen on immediately (see WakeScreenReceiver.kt) so saying
    // "Hey JARVIS" feels like it wakes the phone, not just the assistant.
    try {
      const intent = AndroidIntent(action: 'com.jarvis.ai.ACTION_WAKE_SCREEN');
      await intent.sendBroadcast();
    } catch (_) {
      // Non-fatal: if this fails (e.g. OEM restriction), JARVIS still
      // processes the command and speaks the response normally.
    }

    await FlutterForegroundTask.updateService(
      notificationTitle: 'JARVIS AI',
      notificationText: 'Processing: "$fullTranscript"',
    );

    // Strip the wake word itself so only the actual command is executed —
    // e.g. "hey jarvis torch on karo" -> "torch on karo".
    final wakeWord = await _settings.getWakeWord();
    final command = fullTranscript.toLowerCase().replaceFirst(wakeWord.toLowerCase(), '').trim();

    if (command.isNotEmpty) {
      final outcome = await _executor.execute(command);
      await _tts.speak(outcome.spokenResponse);
      await FlutterForegroundTask.updateService(
        notificationTitle: 'JARVIS AI — Active',
        notificationText: outcome.spokenResponse,
      );
    }

    _busy = false;
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // No periodic polling needed — the wake-word restart-loop drives
    // itself via speech_to_text callbacks.
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _wakeWordService.stop();
  }

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }

  @override
  void onNotificationDismissed() {}
}
