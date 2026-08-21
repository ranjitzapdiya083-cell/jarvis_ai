import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/utils/result.dart';
import '../domain/tts_service.dart';

class TtsServiceImpl implements TtsService {
  final FlutterTts _tts = FlutterTts();
  final StreamController<bool> _speakingController = StreamController.broadcast();

  @override
  Future<void> initialize() async {
    await _tts.setLanguage('hi-IN');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);

    _tts.setStartHandler(() => _speakingController.add(true));
    _tts.setCompletionHandler(() => _speakingController.add(false));
    _tts.setCancelHandler(() => _speakingController.add(false));
    _tts.setErrorHandler((_) => _speakingController.add(false));
  }

  @override
  Future<Result<void>> speak(String text) async {
    if (text.trim().isEmpty) {
      return Result.failure('Bolne ke liye kuch text nahi mila.');
    }
    try {
      final code = await _tts.speak(text);
      if (code == 1) {
        return const Result.success(null);
      }
      return Result.failure('TTS engine speak nahi kar paya.');
    } catch (e) {
      return Result.failure('Text-to-speech mein error aaya: ${e.toString()}');
    }
  }

  @override
  Future<void> stop() => _tts.stop();

  @override
  Future<void> setRate(double rate) => _tts.setSpeechRate(rate);

  @override
  Future<void> setPitch(double pitch) => _tts.setPitch(pitch);

  @override
  Future<void> setLanguage(String languageCode) => _tts.setLanguage(languageCode);

  @override
  Stream<bool> get isSpeakingStream => _speakingController.stream;

  void dispose() => _speakingController.close();
}
