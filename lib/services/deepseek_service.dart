import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for interacting with DeepSeek via the Supabase Edge Function.
///
/// The API key is stored securely in the Supabase edge function environment
/// and is never exposed to the client.
///
/// Non-streaming calls use `Supabase.instance.client.functions.invoke()`.
/// Streaming calls use a direct HTTP connection to the edge function URL
/// to support real-time SSE chunk delivery (the Supabase Functions client
/// does not natively support streaming).
class DeepseekService {
  static const String _functionName = 'deepseek-proxy';
  static const String _functionUrl =
      'https://sjvkriacpjhakxvnsypj.supabase.co/functions/v1/deepseek-proxy';

  /// Builds the request body for the edge function.
  static Map<String, dynamic> _buildRequestBody({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    bool stream = true,
  }) {
    return {
      'systemPrompt': systemPrompt,
      'messages': messages,
      'stream': stream,
    };
  }

  /// Returns the HTTP headers for calling the edge function.
  ///
  /// Includes the Supabase publishable key so the edge function accepts
  /// the request.
  static const String _publishableKey =
      'sb_publishable_tANIawXiusflqGzO53cjKg_j5plgJIC';

  /// Returns the HTTP headers for calling the edge function.
  ///
  /// Includes the Supabase publishable key so the edge function accepts
  /// the request.
  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_publishableKey',
    };
  }

  /// Sends a chat prompt to DeepSeek (via edge function) and returns the
  /// full response as a string.
  ///
  /// [systemPrompt] sets the assistant's behavior.
  /// [messages] is a list of `{'role': 'user'/'assistant', 'content': '...'}`
  /// representing the conversation history (excluding the system prompt).
  static Future<String> sendMessage({
    required String systemPrompt,
    required List<Map<String, String>> messages,
  }) async {
    final body = _buildRequestBody(
      systemPrompt: systemPrompt,
      messages: messages,
      stream: false,
    );

    final response = await Supabase.instance.client.functions.invoke(
      _functionName,
      body: body,
    );

    if (response.data != null) {
      final Map<String, dynamic> data;
      if (response.data is String) {
        data = jsonDecode(response.data as String) as Map<String, dynamic>;
      } else {
        data = response.data as Map<String, dynamic>;
      }

      // Check for edge-function-level errors
      if (data.containsKey('error')) {
        throw Exception('DeepSeek error: ${data['error']}');
      }

      final choices = data['choices'] as List<dynamic>?;
      if (choices != null && choices.isNotEmpty) {
        return choices[0]['message']['content'] as String? ?? '';
      }
      return '';
    } else {
      throw Exception('DeepSeek edge function returned empty response');
    }
  }

  /// Sends a chat prompt to DeepSeek (via edge function) and returns a
  /// stream of text chunks.
  ///
  /// Uses a direct HTTP streaming connection to the edge function URL
  /// because the Supabase Functions client does not support real-time
  /// SSE streaming.
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
    final headers = _getHeaders();
    final body = _buildRequestBody(
      systemPrompt: systemPrompt,
      messages: messages,
      stream: true,
    );

    final request = http.Request('POST', Uri.parse(_functionUrl));
    request.headers.addAll(headers);
    request.body = jsonEncode(body);

    final http.StreamedResponse response;
    try {
      response = await request.send();
    } catch (e) {
      throw Exception('Network error connecting to DeepSeek edge function: $e');
    }

    // Check if the response is JSON (error) rather than SSE (stream)
    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('application/json') ||
        response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      throw Exception(
        'DeepSeek edge function error (${response.statusCode}): $errorBody',
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
            return; // End of stream
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
