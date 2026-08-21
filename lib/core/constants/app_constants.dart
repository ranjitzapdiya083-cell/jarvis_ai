class AppConstants {
  AppConstants._();

  static const String appName = 'JARVIS AI';
  static const String tagline = 'Your Voice. Your Phone. Your Assistant.';
  static const String defaultAssistantName = 'JARVIS';
  static const String defaultWakeWord = 'hey jarvis';
  static const String defaultAddress = 'Boss';

  // SharedPreferences keys
  static const String prefAssistantName = 'assistant_name';
  static const String prefUserAddress = 'user_address';
  static const String prefPersonality = 'personality';
  static const String prefResponseLength = 'response_length';
  static const String prefWakeWord = 'wake_word';
  static const String prefWakeWordEnabled = 'wake_word_enabled';
  static const String prefBackgroundAssistantEnabled = 'background_assistant_enabled';
  static const String prefSensitivity = 'sensitivity';
  static const String prefAutoStartOnBoot = 'auto_start_on_boot';
  static const String prefVoiceResponseEnabled = 'voice_response_enabled';
  static const String prefShowAssistantText = 'show_assistant_text';
  static const String prefShowUserText = 'show_user_text';
  static const String prefThemeMode = 'theme_mode'; // system | light | dark
  static const String prefTtsRate = 'tts_rate';
  static const String prefTtsPitch = 'tts_pitch';
  static const String prefTtsVoice = 'tts_voice';
  static const String prefTtsLanguage = 'tts_language';
  static const String prefHistoryEnabled = 'history_enabled';
  static const String prefRequireConfirmationSensitive = 'require_confirmation_sensitive';
  static const String prefAiApiKey = 'ai_api_key';
  static const String prefAiProvider = 'ai_provider'; // gemini | openai | none

  static const int minAndroidSdk = 24; // Android 7.0
}

enum Personality { friendly, professional, funny, energetic, minimal, custom }

enum ResponseLength { veryShort, short, normal, detailed }

enum RiskLevel { low, medium, high }
