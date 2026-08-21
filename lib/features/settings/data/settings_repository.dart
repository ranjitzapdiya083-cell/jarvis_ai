import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

/// Thin, typed wrapper around SharedPreferences so no other file touches
/// raw string keys directly.
class SettingsRepository {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async => _prefs ??= await SharedPreferences.getInstance();

  Future<String> getAssistantName() async =>
      (await _p).getString(AppConstants.prefAssistantName) ?? AppConstants.defaultAssistantName;
  Future<void> setAssistantName(String v) async => (await _p).setString(AppConstants.prefAssistantName, v);

  Future<String> getUserAddress() async =>
      (await _p).getString(AppConstants.prefUserAddress) ?? AppConstants.defaultAddress;
  Future<void> setUserAddress(String v) async => (await _p).setString(AppConstants.prefUserAddress, v);

  Future<String> getWakeWord() async =>
      (await _p).getString(AppConstants.prefWakeWord) ?? AppConstants.defaultWakeWord;
  Future<void> setWakeWord(String v) async => (await _p).setString(AppConstants.prefWakeWord, v);

  Future<bool> getWakeWordEnabled() async => (await _p).getBool(AppConstants.prefWakeWordEnabled) ?? true;
  Future<void> setWakeWordEnabled(bool v) async => (await _p).setBool(AppConstants.prefWakeWordEnabled, v);

  Future<bool> getBackgroundAssistantEnabled() async =>
      (await _p).getBool(AppConstants.prefBackgroundAssistantEnabled) ?? false;
  Future<void> setBackgroundAssistantEnabled(bool v) async =>
      (await _p).setBool(AppConstants.prefBackgroundAssistantEnabled, v);

  Future<double> getSensitivity() async => (await _p).getDouble(AppConstants.prefSensitivity) ?? 0.5;
  Future<void> setSensitivity(double v) async => (await _p).setDouble(AppConstants.prefSensitivity, v);

  Future<bool> getAutoStartOnBoot() async => (await _p).getBool(AppConstants.prefAutoStartOnBoot) ?? false;
  Future<void> setAutoStartOnBoot(bool v) async => (await _p).setBool(AppConstants.prefAutoStartOnBoot, v);

  Future<String> getThemeMode() async => (await _p).getString(AppConstants.prefThemeMode) ?? 'system';
  Future<void> setThemeMode(String v) async => (await _p).setString(AppConstants.prefThemeMode, v);

  Future<bool> getHistoryEnabled() async => (await _p).getBool(AppConstants.prefHistoryEnabled) ?? true;
  Future<void> setHistoryEnabled(bool v) async => (await _p).setBool(AppConstants.prefHistoryEnabled, v);

  Future<String> getAiApiKey() async => (await _p).getString(AppConstants.prefAiApiKey) ?? '';
  Future<void> setAiApiKey(String v) async => (await _p).setString(AppConstants.prefAiApiKey, v);

  Future<String> getAiProvider() async => (await _p).getString(AppConstants.prefAiProvider) ?? 'none';
  Future<void> setAiProvider(String v) async => (await _p).setString(AppConstants.prefAiProvider, v);

  Future<bool> getRequireConfirmationSensitive() async =>
      (await _p).getBool(AppConstants.prefRequireConfirmationSensitive) ?? true;
  Future<void> setRequireConfirmationSensitive(bool v) async =>
      (await _p).setBool(AppConstants.prefRequireConfirmationSensitive, v);
}
