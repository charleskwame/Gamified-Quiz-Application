import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'api_key_service.dart';

/// Service for interacting with the DeepSeek API.
///
/// DeepSeek uses an OpenAI-compatible API. The API key is retrieved
/// from secure storage (via [ApiKeyService]) and never hardcoded.
class DeepseekService {
  static const String _baseUrl = 'https://api.deepseek.com';
  static const String _chatEndpoint = '/v1/chat/completions';
  static const String _model = 'deepseek-chat';

  /// Returns the HTTP headers required for DeepSeek API authentication.
  ///
  /// Throws [Exception] if the API key is not configured.
  static Future<Map<String, String>> _getHeaders() async {
    final apiKey = await ApiKeyService.getKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'DeepSeek API key not found. '
        'Provide it via --dart-define=DEEPSEEK_API_KEY=your-key '
        'when building or running the app.',
      );
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
  }

  /// Builds the request body for a chat completion request.
  static Map<String, dynamic> _buildRequestBody({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    bool stream = true,
  }) {
    return {
      'model': _model,
      'stream': stream,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        ...messages,
      ],
    };
  }

  /// Sends a chat prompt to DeepSeek and returns the full response as a string.
  ///
  /// [systemPrompt] sets the assistant's behavior.
  /// [messages] is a list of `{'role': 'user'/'assistant', 'content': '...'}`
  /// representing the conversation history (excluding the system prompt).
  static Future<String> sendMessage({
    required String systemPrompt,
    required List<Map<String, String>> messages,
  }) async {
    final headers = await _getHeaders();
    final body = _buildRequestBody(
      systemPrompt: systemPrompt,
      messages: messages,
      stream: false,
    );

    final response = await http.post(
      Uri.parse('$_baseUrl$_chatEndpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>;
      if (choices.isNotEmpty) {
        return choices[0]['message']['content'] as String? ?? '';
      }
      return '';
    } else {
      throw Exception(
        'DeepSeek API error (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Sends a chat prompt to DeepSeek and returns a stream of text chunks.
  ///
  /// [systemPrompt] sets the assistant's behavior.
  /// [messages] is a list of `{'role': 'user'/'assistant', 'content': '...'}`
  /// representing the conversation history (excluding the system prompt).
  ///
  /// Yields text chunks as they arrive via SSE streaming.
  static Stream<String> sendMessageStream({
    required String systemPrompt,
    required List<Map<String, String>> messages,
  }) async* {
    final headers = await _getHeaders();
    final body = _buildRequestBody(
      systemPrompt: systemPrompt,
      messages: messages,
      stream: true,
    );

    final request = http.Request('POST', Uri.parse('$_baseUrl$_chatEndpoint'));
    request.headers.addAll(headers);
    request.body = jsonEncode(body);

    final http.StreamedResponse response;
    try {
      response = await request.send();
    } catch (e) {
      throw Exception('Network error connecting to DeepSeek: $e');
    }

    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      throw Exception(
        'DeepSeek API error (${response.statusCode}): $errorBody',
      );
    }

    // Parse SSE (Server-Sent Events) stream
    // Format: data: {"choices":[{"delta":{"content":"text"}}]}\n\n
    String buffer = '';
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      buffer += chunk;

      while (buffer.contains('\n')) {
        final newlineIndex = buffer.indexOf('\n');
        final line = buffer.substring(0, newlineIndex).trim();
        buffer = buffer.substring(newlineIndex + 1);

        if (line.startsWith('data: ')) {
          final dataStr = line.substring(6).trim();
          if (dataStr == '[DONE]') {
            break;
          }
          try {
            final data = jsonDecode(dataStr) as Map<String, dynamic>;
            final choices = data['choices'] as List<dynamic>?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map<String, dynamic>?;
              final content = delta?['content'] as String?;
              if (content != null && content.isNotEmpty) {
                yield content;
              }
            }
          } catch (_) {
            // Ignore malformed JSON chunks
          }
        }
      }
    }
  }
}
