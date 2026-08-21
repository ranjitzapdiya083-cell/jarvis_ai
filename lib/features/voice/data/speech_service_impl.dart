import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/utils/result.dart';
import '../domain/speech_service.dart';

class SpeechServiceImpl implements SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;

  @override
  bool get isAvailable => _available;

  @override
  bool get isListening => _speech.isListening;

  @override
  Future<Result<void>> initialize() async {
    try {
      _available = await _speech.initialize(
        onError: (error) => _available = !error.permanent ? _available : false,
        onStatus: (_) {},
      );
      if (!_available) {
        return Result.failure(
          'Speech recognition initialize nahi ho paya. Microphone permission ya device support check karo.',
          code: 'STT_UNAVAILABLE',
        );
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure('Speech engine start nahi ho paya: ${e.toString()}');
    }
  }

  @override
  Future<Result<void>> startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function() onListeningDone,
    String localeId = 'hi_IN',
  }) async {
    if (!_available) {
      return Result.failure('Speech recognition available nahi hai.');
    }
    try {
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
          if (result.finalResult) onListeningDone();
        },
        localeId: localeId,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        ),
        onSoundLevelChange: (_) {},
      );
      return const Result.success(null);
    } catch (e) {
      return Result.failure('Listening start nahi ho payi: ${e.toString()}');
    }
  }

  @override
  Future<void> stopListening() async {
    await _speech.stop();
  }
}
