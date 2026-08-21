import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/utils/result.dart';
import '../domain/ai_provider.dart';

/// Calls Google's Gemini API. The API key is supplied by the user via
/// Settings > AI & Conversation and stored locally (SharedPreferences) —
/// it is NEVER hardcoded or bundled with the app, per spec section 55
/// (no secrets in source).
class GeminiProvider implements AiProvider {
  final String apiKey;
  final String model;

  GeminiProvider({required this.apiKey, this.model = 'gemini-2.0-flash'});

  @override
  String get name => 'Gemini';

  @override
  Future<Result<String>> chat({
    required String userMessage,
    required List<Map<String, String>> history,
    String? systemPrompt,
  }) async {
    if (apiKey.trim().isEmpty) {
      return Result.failure(
        'AI API key set nahi hai. Settings > AI & Conversation mein apni Gemini key daalo.',
        code: 'NO_API_KEY',
      );
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final contents = [
      for (final turn in history)
        {
          'role': turn['role'] == 'assistant' ? 'model' : 'user',
          'parts': [
            {'text': turn['content'] ?? ''}
          ],
        },
      {
        'role': 'user',
        'parts': [
          {'text': userMessage}
        ],
      },
    ];

    final body = {
      'contents': contents,
      if (systemPrompt != null && systemPrompt.trim().isNotEmpty)
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt}
          ],
        },
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 512,
      },
    };

    try {
      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        final decoded = _safeDecode(response.body);
        final message = decoded?['error']?['message'] ?? 'AI service se response nahi mila.';
        return Result.failure('AI error (${response.statusCode}): $message', code: 'AI_HTTP_ERROR');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = decoded['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return Result.failure('AI ne koi response nahi diya. Dobara try karo.');
      }
      final parts = (candidates.first['content']?['parts'] as List<dynamic>?) ?? [];
      final text = parts.map((p) => p['text']?.toString() ?? '').join().trim();
      if (text.isEmpty) {
        return Result.failure('AI response khaali aaya.');
      }
      return Result.success(text);
    } catch (e) {
      return Result.failure(
        'AI se connect nahi ho paya. Internet connection check karo. (${e.toString()})',
        code: 'NETWORK_ERROR',
      );
    }
  }

  Map<String, dynamic>? _safeDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
