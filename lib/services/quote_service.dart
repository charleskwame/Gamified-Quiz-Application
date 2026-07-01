import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

/// Loads a random motivational quote from the bundled quotes.json file.
class QuoteService {
  /// Returns (quoteText, author) or null if quotes cannot be loaded.
  static Future<(String, String)?> loadRandomQuote() async {
    try {
      final jsonString = await rootBundle.loadString('lib/assets/quotes.json');
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final List<dynamic> quotesList = data['quotes'];
      if (quotesList.isNotEmpty) {
        final random = Random();
        final randomQuote = quotesList[random.nextInt(quotesList.length)];
        final String text = randomQuote['quote'];
        final String author = randomQuote['author'];
        return (text, author);
      }
    } catch (_) {
      // Silently fail — quote display is optional
    }
    return null;
  }
}
