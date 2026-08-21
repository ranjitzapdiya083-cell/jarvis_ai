import '../../../core/utils/result.dart';

/// Abstraction over any conversational AI backend. JARVIS core logic never
/// talks to Gemini/OpenAI directly — only through this interface, so the
/// provider can be swapped or fully disabled without touching UI code.
abstract class AiProvider {
  String get name;

  /// [history] is a simple list of {role, content} maps in chronological
  /// order so multi-turn context/memory works (spec section 9/24).
  Future<Result<String>> chat({
    required String userMessage,
    required List<Map<String, String>> history,
    String? systemPrompt,
  });
}
