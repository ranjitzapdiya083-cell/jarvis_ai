import '../../../core/utils/result.dart';

abstract class SpeechService {
  Future<Result<void>> initialize();
  bool get isAvailable;

  /// Starts listening. [onResult] fires with interim + final transcripts.
  /// [onListeningDone] fires once the recognizer stops (silence timeout,
  /// manual stop, or error).
  Future<Result<void>> startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function() onListeningDone,
    String localeId = 'hi_IN',
  });

  Future<void> stopListening();
  bool get isListening;
}
