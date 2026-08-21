import '../../../core/utils/result.dart';

/// Contract for continuous wake-word detection. Implementations should
/// keep listening (restarting the recognizer after each utterance) and
/// call [onWake] with the full transcript once the configured wake phrase
/// is heard, so the caller can strip the wake phrase and execute whatever
/// follows as a normal command.
abstract class WakeWordService {
  Future<Result<void>> start({
    required String wakeWord,
    required void Function(String fullTranscript) onWake,
    required void Function(String error) onError,
  });

  Future<void> stop();
  bool get isRunning;
}
