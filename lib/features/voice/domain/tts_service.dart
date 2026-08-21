import '../../../core/utils/result.dart';

abstract class TtsService {
  Future<void> initialize();
  Future<Result<void>> speak(String text);
  Future<void> stop();
  Future<void> setRate(double rate);
  Future<void> setPitch(double pitch);
  Future<void> setLanguage(String languageCode);
  Stream<bool> get isSpeakingStream;
}
