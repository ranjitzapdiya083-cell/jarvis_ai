import '../../ai/domain/ai_provider.dart';
import '../../chat/data/chat_history_repository.dart';
import '../../contacts/domain/contact_service.dart';
import '../../device/data/app_launcher_service.dart';
import '../../device/domain/device_control_service.dart';
import '../../history/data/history_repository.dart';
import 'command_intent.dart';
import 'intent_engine.dart';

class ExecutionOutcome {
  final bool success;
  final String spokenResponse;
  final CommandIntent intent;

  const ExecutionOutcome({
    required this.success,
    required this.spokenResponse,
    required this.intent,
  });
}

/// The single orchestration point: text in -> real action out.
/// Every branch either performs a genuine device/app/network call or
/// returns an honest failure message — nothing here is simulated.
class CommandExecutor {
  final IntentEngine _intentEngine;
  final DeviceControlService _device;
  final AppLauncherService _launcher;
  final HistoryRepository _history;
  final ContactService _contacts;
  final ChatHistoryRepository _chatHistory;
  final AiProvider Function() _aiProviderResolver;
  final String assistantName;
  final String userAddress;

  CommandExecutor({
    required DeviceControlService device,
    required AppLauncherService launcher,
    required HistoryRepository history,
    required ContactService contacts,
    required ChatHistoryRepository chatHistory,
    required AiProvider Function() aiProviderResolver,
    IntentEngine? intentEngine,
    this.assistantName = 'JARVIS',
    this.userAddress = 'Boss',
  })  : _device = device,
        _launcher = launcher,
        _history = history,
        _contacts = contacts,
        _chatHistory = chatHistory,
        _aiProviderResolver = aiProviderResolver,
        _intentEngine = intentEngine ?? IntentEngine();

  /// Executes [rawText]. [chatHistory] is optional in-memory context for
  /// the current session — but conversational replies also always draw on
  /// the PERSISTENT chat memory (SQLite), so context survives app restarts
  /// too. This is what lets JARVIS remember what you talked about
  /// yesterday, not just five minutes ago.
  Future<ExecutionOutcome> execute(String rawText, {List<Map<String, String>> chatHistory = const []}) async {
    final intent = _intentEngine.recognize(rawText);
    final outcome = await _run(intent, chatHistory: chatHistory);
    await _history.add(
      rawText: rawText,
      intentType: intent.type.name,
      success: outcome.success,
      resultMessage: outcome.spokenResponse,
    );
    // Every conversational turn (small talk + AI chat) is remembered
    // persistently so JARVIS can refer back to it later, in this session
    // or a future one.
    if (intent.type == IntentType.conversation ||
        intent.type == IntentType.unknown ||
        intent.type == IntentType.smallTalk) {
      await _chatHistory.add(role: 'user', content: rawText);
      await _chatHistory.add(role: 'assistant', content: outcome.spokenResponse);
    }
    return outcome;
  }

  Future<ExecutionOutcome> _run(CommandIntent intent, {List<Map<String, String>> chatHistory = const []}) async {
    switch (intent.type) {
      case IntentType.torchOn:
        final r = await _device.torchOn();
        return r.when(
          success: (_) => _ok(intent, '$userAddress, torch on kar di.'),
          failure: (msg, _) => _fail(intent, msg),
        );

      case IntentType.torchOff:
        final r = await _device.torchOff();
        return r.when(
          success: (_) => _ok(intent, '$userAddress, torch off kar di.'),
          failure: (msg, _) => _fail(intent, msg),
        );

      case IntentType.getBattery:
        final r = await _device.getBatteryLevel();
        return r.when(
          success: (level) => _ok(intent, '$userAddress, aapki battery $level percent hai.'),
          failure: (msg, _) => _fail(intent, msg),
        );

      case IntentType.getDeviceInfo:
        final r = await _device.getDeviceInfo();
        return r.when(
          success: (info) => _ok(
            intent,
            '$userAddress, aapka device ${info.model} hai, Android ${info.androidVersion} par chal raha hai.',
          ),
          failure: (msg, _) => _fail(intent, msg),
        );

      case IntentType.setVolume:
        if (intent.slots.containsKey('level')) {
          final level = int.parse(intent.slots['level']!);
          final r = await _device.setVolume(level);
          return r.when(
            success: (_) => _ok(intent, 'Volume $level percent set kar diya.'),
            failure: (msg, _) => _fail(intent, msg),
          );
        }
        final up = intent.slots['relative'] == 'up';
        final r = await _device.adjustVolume(up: up);
        return r.when(
          success: (_) => _ok(intent, up ? 'Volume badha diya.' : 'Volume kam kar diya.'),
          failure: (msg, _) => _fail(intent, msg),
        );

      case IntentType.setBrightness:
        final up = intent.slots['relative'] == 'up';
        final r = await _device.adjustBrightness(up: up);
        return r.when(
          success: (_) => _ok(intent, up ? 'Brightness badha di.' : 'Brightness kam kar di.'),
          failure: (msg, _) => _fail(intent, msg),
        );

      case IntentType.screenOff:
        final r = await _device.screenOff();
        return r.when(
          success: (_) => _ok(intent, 'Theek hai $userAddress, screen off kar raha hoon.'),
          failure: (msg, _) => _fail(intent, msg),
        );

      case IntentType.openApp:
        final app = intent.slots['app'] ?? '';
        final r = await _launcher.openApp(app);
        return r.when(
          success: (_) => _ok(intent, 'Yes $userAddress, $app open kar raha hoon.'),
          failure: (msg, _) => _fail(intent, msg),
        );

      case IntentType.call:
        final number = intent.slots['number'];
        if (number != null) {
          final r = await _launcher.dialNumberNoPermission(number);
          return r.when(
            success: (_) => _ok(intent, '$number ko call kar raha hoon.'),
            failure: (msg, _) => _fail(intent, msg),
          );
        }
        final contactName = intent.slots['contact'];
        if (contactName != null) {
          final resolved = await _contacts.findByName(contactName);
          return resolved.when(
            success: (contact) => _dialResolvedContact(intent, contact),
            failure: (msg, _) async => _fail(intent, msg),
          );
        }
        return _fail(intent, 'Contact ka naam ya number nahi mila. Poora number bolo ya contact ka naam bolo.');

      case IntentType.sendMessage:
        final body = intent.slots['body'] ?? '';
        if (body.isEmpty) {
          return _fail(intent, 'Message ka text nahi mila. "<naam> ko message bhejo: <text>" format use karo.');
        }
        final contactName = intent.slots['contact'];
        if (contactName == null || contactName.isEmpty) {
          return _fail(intent, 'Kisko message bhejna hai — contact ka naam bolo.');
        }
        final resolved = await _contacts.findByName(contactName);
        final useWhatsapp = intent.slots['app'] == 'whatsapp';
        return resolved.when(
          success: (contact) => _sendResolvedMessage(intent, contact, body, useWhatsapp: useWhatsapp),
          failure: (msg, _) async => _fail(intent, msg),
        );

      case IntentType.webSearch:
        final query = intent.slots['query'] ?? '';
        final r = await _launcher.openUrl('https://www.google.com/search?q=${Uri.encodeComponent(query)}');
        return r.when(
          success: (_) => _ok(intent, '"$query" Google par search kar raha hoon.'),
          failure: (msg, _) => _fail(intent, msg),
        );

      case IntentType.youtubeSearch:
        final query = intent.slots['query'] ?? '';
        final r = await _launcher
            .openUrl('https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}');
        return r.when(
          success: (_) => _ok(intent, '"$query" YouTube par search kar raha hoon.'),
          failure: (msg, _) => _fail(intent, msg),
        );

      case IntentType.navigation:
        final dest = intent.slots['destination'] ?? '';
        final r = await _launcher.openMapsSearch(dest);
        return r.when(
          success: (_) => _ok(intent, '$dest ka route Maps mein khol raha hoon.'),
          failure: (msg, _) => _fail(intent, msg),
        );

      case IntentType.setReminder:
      case IntentType.runCustomCommand:
        return _fail(intent, 'Ye feature abhi implement ho raha hai.');

      case IntentType.smallTalk:
        return _ok(intent, await _smallTalkResponse(intent.slots['topic'] ?? ''));

      case IntentType.conversation:
      case IntentType.unknown:
        final provider = _aiProviderResolver();

        // Pull real persisted memory so the AI can reference earlier
        // conversations, not just what's happened since the app opened.
        final persistedMessages = await _chatHistory.recent(limit: 12);
        final persistedTurns = persistedMessages
            .map((m) => {'role': m.role, 'content': m.content})
            .toList();

        // Give the AI a short summary of recent real commands too, so it
        // can give genuinely context-aware answers — e.g. if you always
        // open YouTube in the evening, or just asked about your battery.
        final recentCommands = await _history.recent(limit: 5);
        final activitySummary = recentCommands.isEmpty
            ? ''
            : 'Recent things the user asked JARVIS to do: '
                '${recentCommands.map((h) => '"${h.rawText}"').join(', ')}.';

        final r = await provider.chat(
          userMessage: intent.rawText,
          history: [...persistedTurns, ...chatHistory],
          systemPrompt:
              'Tum $assistantName ho, ek helpful Hinglish-speaking Android voice assistant. '
              'User ko "$userAddress" bolke address karo. Jawab chhote aur natural rakho. '
              'Pichli conversation aur user ki recent activity yaad rakhke, jab relevant ho '
              'tabhi uska reference do — har baar zabardasti mat lao. $activitySummary',
        );
        return r.when(
          success: (text) => _ok(intent, text),
          failure: (msg, _) => _fail(intent, msg),
        );
    }
  }

  /// Warm, varied, locally-generated replies for common pleasantries —
  /// these work even with zero AI configured, and reference the time of
  /// day / assistant identity honestly (no invented capabilities).
  Future<String> _smallTalkResponse(String topic) async {
    switch (topic) {
      case 'morning':
        return 'Good morning $userAddress! Aaj ka din shandar ho. Kuch help chahiye?';
      case 'afternoon':
        return 'Good afternoon $userAddress! Batao, kya karu aapke liye?';
      case 'evening':
        return 'Good evening $userAddress! Din kaisa raha?';
      case 'night':
        return 'Good night $userAddress! Aaram se sona, main yahin hoon.';
      case 'how_are_you':
        return 'Main bilkul theek hoon $userAddress, aapki service ke liye ready! Aap kaise ho?';
      case 'thanks':
        return 'Koi baat nahi $userAddress, hamesha yahin hoon!';
      case 'bye':
        return 'Theek hai $userAddress, jab bhi zaroorat ho bas "Hey JARVIS" bolna.';
      case 'identity':
        return 'Main $assistantName hoon — aapka personal voice assistant.';
      default:
        return 'Ji $userAddress?';
    }
  }

  Future<ExecutionOutcome> _dialResolvedContact(CommandIntent intent, ResolvedContact contact) async {
    final r = await _launcher.dialNumberNoPermission(contact.phoneNumber);
    return r.when(
      success: (_) => _ok(intent, '${contact.displayName} ko call kar raha hoon.'),
      failure: (msg, _) => _fail(intent, msg),
    );
  }

  Future<ExecutionOutcome> _sendResolvedMessage(
    CommandIntent intent,
    ResolvedContact contact,
    String body, {
    bool useWhatsapp = false,
  }) async {
    if (useWhatsapp) {
      final r = await _launcher.openWhatsAppMessage(contact.phoneNumber, body);
      return r.when(
        success: (_) => _ok(
          intent,
          '${contact.displayName} ke liye WhatsApp mein message type kar diya — Send button aapko khud dabana hoga, ye WhatsApp ka security rule hai.',
        ),
        failure: (msg, _) => _fail(intent, msg),
      );
    }
    final r = await _launcher.sendSms(contact.phoneNumber, body);
    return r.when(
      success: (_) => _ok(intent, '${contact.displayName} ko SMS bhej raha hoon.'),
      failure: (msg, _) => _fail(intent, msg),
    );
  }

  ExecutionOutcome _ok(CommandIntent intent, String message) =>
      ExecutionOutcome(success: true, spokenResponse: message, intent: intent);

  ExecutionOutcome _fail(CommandIntent intent, String message) =>
      ExecutionOutcome(success: false, spokenResponse: message, intent: intent);
}
