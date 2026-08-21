import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/utils/result.dart';
import '../domain/wake_word_service.dart';

/// HONEST IMPLEMENTATION NOTE:
/// Android's on-device speech recognizer (used by `speech_to_text`) is NOT
/// a true low-power, always-on hotword engine like Porcupine/Snowboy — it
/// needs an active microphone session and stops after a few seconds of
/// silence or once it returns a result. What this class does, and what it
/// genuinely achieves, is a **continuous restart-loop**: as soon as one
/// listening session ends, it immediately starts another, so from the
/// user's perspective the app is always listening for the wake word while
/// this service is running (i.e. while the JARVIS foreground-service
/// notification is showing). This is the same practical approach used by
/// several production "always-listening" Flutter assistants that don't
/// license a dedicated hotword SDK.
///
/// Trade-offs (documented here, not hidden):
///  - Higher battery use than a real DSP-based hotword engine.
///  - A ~0.5–1s gap between recognizer restarts where audio isn't captured.
///  - Works only while the app/foreground-service is alive — Android can
///    still kill it under aggressive battery optimization on some OEM
///    skins unless the user whitelists the app.
///  - For production-grade, true low-power offline hotword detection,
///    integrate Picovoice Porcupine (or similar) — swap this class out for
///    a new WakeWordService implementation; nothing else in the app needs
///    to change since callers only depend on the interface.
class WakeWordServiceImpl implements WakeWordService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _running = false;
  bool _initialized = false;
  String _wakeWord = 'hey jarvis';
  void Function(String)? _onWake;
  void Function(String)? _onError;
  Timer? _restartDebounce;

  @override
  bool get isRunning => _running;

  @override
  Future<Result<void>> start({
    required String wakeWord,
    required void Function(String fullTranscript) onWake,
    required void Function(String error) onError,
  }) async {
    _wakeWord = wakeWord.trim().toLowerCase();
    _onWake = onWake;
    _onError = onError;

    if (!_initialized) {
      final available = await _speech.initialize(
        onError: (error) {
          _onError?.call(error.errorMsg);
          // Auto-recover: most errors here are transient (timeout, no
          // match) — restart the loop instead of giving up permanently.
          if (_running) _scheduleRestart();
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (_running) _scheduleRestart();
          }
        },
      );
      _initialized = available;
      if (!available) {
        return Result.failure(
          'Speech recognizer initialize nahi ho paya — is device par wake-word background listening supported nahi hai.',
          code: 'STT_UNAVAILABLE',
        );
      }
    }

    _running = true;
    _listenOnce();
    return const Result.success(null);
  }

  void _scheduleRestart() {
    _restartDebounce?.cancel();
    _restartDebounce = Timer(const Duration(milliseconds: 400), () {
      if (_running) _listenOnce();
    });
  }

  void _listenOnce() {
    if (!_running) return;
    _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords.toLowerCase();
        if (text.contains(_wakeWord)) {
          _onWake?.call(result.recognizedWords);
        }
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 30),
    );
  }

  @override
  Future<void> stop() async {
    _running = false;
    _restartDebounce?.cancel();
    await _speech.stop();
  }
}
