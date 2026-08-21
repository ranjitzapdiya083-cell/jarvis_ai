import '../../features/ai/data/gemini_provider.dart';
import '../../features/ai/data/local_fallback_provider.dart';
import '../../features/ai/domain/ai_provider.dart';
import '../../features/chat/data/chat_history_repository.dart';
import '../../features/contacts/data/contact_service_impl.dart';
import '../../features/contacts/domain/contact_service.dart';
import '../../features/custom_commands/data/custom_command_repository.dart';
import '../../features/device/data/app_launcher_service.dart';
import '../../features/device/data/device_control_service_impl.dart';
import '../../features/device/domain/device_control_service.dart';
import '../../features/commands/domain/command_executor.dart';
import '../../features/history/data/history_repository.dart';
import '../../features/home/domain/assistant_controller.dart';
import '../../features/permissions/data/permission_service.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/voice/data/speech_service_impl.dart';
import '../../features/voice/data/tts_service_impl.dart';
import '../../features/voice/domain/speech_service.dart';
import '../../features/voice/domain/tts_service.dart';

/// A hand-rolled, dependency-free service locator. For a project of this
/// size a full DI framework (get_it, riverpod) is optional overhead — this
/// keeps object graph construction explicit and easy to read/debug.
class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator instance = ServiceLocator._();

  late final SettingsRepository settingsRepository = SettingsRepository();
  late final PermissionService permissionService = PermissionService();
  late final HistoryRepository historyRepository = HistoryRepository();
  late final ChatHistoryRepository chatHistoryRepository = ChatHistoryRepository();
  late final CustomCommandRepository customCommandRepository = CustomCommandRepository();

  late final DeviceControlService deviceControlService = DeviceControlServiceImpl();
  late final AppLauncherService appLauncherService = AppLauncherService();
  late final SpeechService speechService = SpeechServiceImpl();
  late final TtsService ttsService = TtsServiceImpl();
  late final ContactService contactService = ContactServiceImpl();

  /// Resolves the active AI provider fresh each call so a just-saved API
  /// key / provider choice in Settings takes effect immediately.
  AiProvider resolveAiProvider({required String provider, required String apiKey}) {
    if (provider == 'gemini' && apiKey.trim().isNotEmpty) {
      return GeminiProvider(apiKey: apiKey);
    }
    return LocalFallbackProvider();
  }

  AssistantController? _controller;

  Future<AssistantController> buildAssistantController() async {
    if (_controller != null) return _controller!;

    final provider = await settingsRepository.getAiProvider();
    final apiKey = await settingsRepository.getAiApiKey();
    final assistantName = await settingsRepository.getAssistantName();
    final userAddress = await settingsRepository.getUserAddress();

    final executor = CommandExecutor(
      device: deviceControlService,
      launcher: appLauncherService,
      history: historyRepository,
      contacts: contactService,
      chatHistory: chatHistoryRepository,
      aiProviderResolver: () => resolveAiProvider(provider: provider, apiKey: apiKey),
      assistantName: assistantName,
      userAddress: userAddress,
    );

    _controller = AssistantController(
      speechService: speechService,
      ttsService: ttsService,
      executor: executor,
      historyRepository: historyRepository,
      chatHistoryRepository: chatHistoryRepository,
    );
    return _controller!;
  }
}
