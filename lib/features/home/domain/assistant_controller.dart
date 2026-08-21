import 'package:flutter/foundation.dart';

import '../../chat/data/chat_history_repository.dart';
import '../../commands/domain/command_executor.dart';
import '../../history/data/history_repository.dart';
import '../../history/domain/history_entry.dart';
import '../../voice/domain/speech_service.dart';
import '../../voice/domain/tts_service.dart';
import 'assistant_state.dart';

/// Drives the Home screen: mic button -> STT -> intent -> execution -> TTS.
/// This is the real runtime loop, not a mock — every state transition
/// corresponds to an actual async operation completing.
class AssistantController extends ChangeNotifier {
  final SpeechService speechService;
  final TtsService ttsService;
  final CommandExecutor executor;
  final HistoryRepository historyRepository;
  final ChatHistoryRepository chatHistoryRepository;

  AssistantController({
    required this.speechService,
    required this.ttsService,
    required this.executor,
    required this.historyRepository,
    required this.chatHistoryRepository,
  }) {
    ttsService.isSpeakingStream.listen((speaking) {
      if (speaking) {
        _setState(AssistantState.speaking);
      } else if (_state == AssistantState.speaking) {
        _setState(AssistantState.idle);
      }
    });
  }

  AssistantState _state = AssistantState.idle;
  AssistantState get state => _state;

  String _liveTranscript = '';
  String get liveTranscript => _liveTranscript;

  String _lastResponse = '';
  String get lastResponse => _lastResponse;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<HistoryEntry> _recent = [];
  List<HistoryEntry> get recent => _recent;

  final List<Map<String, String>> _chatHistory = [];

  Future<void> initialize() async {
    await ttsService.initialize();
    final r = await speechService.initialize();
    r.when(
      success: (_) {},
      failure: (msg, _) {
        _errorMessage = msg;
        notifyListeners();
      },
    );
    await refreshHistory();

    // Seed this session's in-memory conversation context from persisted
    // chat memory, so JARVIS continues naturally instead of "forgetting"
    // everything every time the app restarts.
    final pastMessages = await chatHistoryRepository.recent(limit: 12);
    _chatHistory.addAll(pastMessages.map((m) => {'role': m.role, 'content': m.content}));
  }

  Future<void> refreshHistory() async {
    _recent = await historyRepository.recent(limit: 4);
    notifyListeners();
  }

  Future<void> startListening() async {
    if (!speechService.isAvailable) {
      _errorMessage = 'Microphone permission ya speech engine available nahi hai.';
      _setState(AssistantState.permissionRequired);
      return;
    }
    _liveTranscript = '';
    _errorMessage = null;
    _setState(AssistantState.listening);

    final r = await speechService.startListening(
      onResult: (text, isFinal) {
        _liveTranscript = text;
        notifyListeners();
        if (isFinal && text.trim().isNotEmpty) {
          _handleFinalTranscript(text);
        }
      },
      onListeningDone: () {
        if (_state == AssistantState.listening) {
          _setState(AssistantState.idle);
        }
      },
    );

    r.when(
      success: (_) {},
      failure: (msg, _) {
        _errorMessage = msg;
        _setState(AssistantState.error);
      },
    );
  }

  Future<void> stopListening() async {
    await speechService.stopListening();
    _setState(AssistantState.idle);
  }

  Future<void> submitTypedText(String text) => _handleFinalTranscript(text);

  Future<void> _handleFinalTranscript(String text) async {
    await speechService.stopListening();
    _setState(AssistantState.processing);

    _chatHistory.add({'role': 'user', 'content': text});

    final outcome = await executor.execute(text, chatHistory: _chatHistory);

    _chatHistory.add({'role': 'assistant', 'content': outcome.spokenResponse});
    _lastResponse = outcome.spokenResponse;
    _setState(outcome.success ? AssistantState.success : AssistantState.error);

    await ttsService.speak(outcome.spokenResponse);
    await refreshHistory();

    if (_state != AssistantState.speaking) {
      _setState(AssistantState.idle);
    }
  }

  void _setState(AssistantState s) {
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    speechService.stopListening();
    super.dispose();
  }
}
