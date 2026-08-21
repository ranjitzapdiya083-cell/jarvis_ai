import '../../../core/utils/result.dart';
import '../domain/ai_provider.dart';

/// Used when the user hasn't configured any AI provider. Gives an honest,
/// clearly-scripted reply instead of pretending to "understand" free-form
/// conversation (spec section 9: never fake AI capability).
class LocalFallbackProvider implements AiProvider {
  @override
  String get name => 'Local (no AI configured)';

  @override
  Future<Result<String>> chat({
    required String userMessage,
    required List<Map<String, String>> history,
    String? systemPrompt,
  }) async {
    return const Result.success(
      'Boss, ye command mujhe samajh nahi aayi aur abhi koi AI model connect nahi hai. '
      'Settings > AI & Conversation mein apni Gemini/OpenAI API key add karo taaki main '
      'free-form baatein bhi samajh sakoon. Tab tak aap Commands list se koi action try karo.',
    );
  }
}
