import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/question.dart';
import '../../services/deepseek_service.dart';

/// A modal bottom sheet that provides AI-powered study assistance via DeepSeek.
class QuizAiChatSheet extends StatelessWidget {
  final String category;
  final List<Question> incorrectQuestions;

  const QuizAiChatSheet({
    super.key,
    required this.category,
    required this.incorrectQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return _AiChatContent(
      category: category,
      incorrectQuestions: incorrectQuestions,
    );
  }

  /// Show this sheet as a modal bottom sheet.
  static void show(
    BuildContext context, {
    required String category,
    required List<Question> incorrectQuestions,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuizAiChatSheet(
        category: category,
        incorrectQuestions: incorrectQuestions,
      ),
    );
  }
}

// ─── Internal stateful chat content ──────────────────────────────────────────

class _ChatMessage {
  String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

class _AiChatContent extends StatefulWidget {
  final String category;
  final List<Question> incorrectQuestions;

  const _AiChatContent({
    required this.category,
    required this.incorrectQuestions,
  });

  @override
  State<_AiChatContent> createState() => _AiChatContentState();
}

class _AiChatContentState extends State<_AiChatContent> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatMessage(
        text:
            "🤖 **Welcome to DeepSeek AI Study Assistant!**\n\nI am analyzing your quiz performance to prepare tailored study tips. Please wait for my response before asking any questions.",
        isUser: false,
      ),
    );
    _fetchInitialStudyGuide();
  }

  Future<void> _fetchInitialStudyGuide() async {
    if (!mounted) return;
    setState(() {
      _isTyping = true;
    });

    final category = widget.category;
    final wrongQuestionsDetails = widget.incorrectQuestions.isEmpty
        ? "No wrong questions yet. General assistance."
        : widget.incorrectQuestions
              .map(
                (q) =>
                    "- Question: ${q.questionText}\n  Correct Answer: ${q.correctAnswer}",
              )
              .join("\n\n");

    final prompt =
        """
You are an expert AI study tutor inside a gamified quiz application.
The user is currently taking a quiz on "$category".
${widget.incorrectQuestions.isNotEmpty ? "Here are the questions they got wrong so far:\n$wrongQuestionsDetails\n" : ""}
CRITICAL INSTRUCTION: Be extremely direct and straight to the point. Give 1-2 concise bullet points or sentences with study tips. No intros, greetings, or fluff.
""";

    final aiMessage = _ChatMessage(text: "", isUser: false);
    bool addedMessage = false;

    try {
      final stream = DeepseekService.sendMessageStream(
        systemPrompt: prompt,
        messages: [],
      );

      await for (final chunk in stream) {
        if (!mounted) break;
        if (chunk.isNotEmpty) {
          if (!addedMessage) {
            _messages.add(aiMessage);
            addedMessage = true;
            _isTyping = false;
          }
          setState(() {
            aiMessage.text += chunk;
          });
          _scrollToBottom();
        }
      }

      if (mounted && !addedMessage) {
        setState(() {
          _messages.add(
            _ChatMessage(
              text: "Welcome! How can I help you with $category today?",
              isUser: false,
            ),
          );
        });
      }
    } catch (e) {
      debugPrint("DeepSeek Initial Guide Error: $e");
      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessage(
              text:
                  "Welcome to your AI Study Tutor! How can I help you with $category today?",
              isUser: false,
            ),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty || _isTyping) return;

    final text = userMessage.trim();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _textController.clear();
    _scrollToBottom();

    final category = widget.category;
    final wrongQuestionsDetails = widget.incorrectQuestions
        .map(
          (q) =>
              "- Question: ${q.questionText}\n  Correct Option: ${q.correctAnswer}",
        )
        .join("\n\n");

    final systemPrompt =
        """
You are an expert AI study tutor inside a gamified quiz application.
The user is currently taking a quiz on "$category".
${widget.incorrectQuestions.isNotEmpty ? "Questions answered incorrectly so far:\n$wrongQuestionsDetails\n" : ""}
CRITICAL INSTRUCTION: Be extremely direct and straight to the point. Answer immediately without conversational filler or intros like 'Hello!' or 'Sure!'. Use concise sentences or short bullet points.
""";

    final List<Map<String, String>> conversationMessages = [];
    for (var msg in _messages) {
      conversationMessages.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text,
      });
    }

    final aiMessage = _ChatMessage(text: "", isUser: false);
    bool addedMessage = false;

    try {
      final stream = DeepseekService.sendMessageStream(
        systemPrompt: systemPrompt,
        messages: conversationMessages,
      );

      await for (final chunk in stream) {
        if (!mounted) break;
        if (chunk.isNotEmpty) {
          if (!addedMessage) {
            _messages.add(aiMessage);
            addedMessage = true;
            _isTyping = false;
          }
          setState(() {
            aiMessage.text += chunk;
          });
          _scrollToBottom();
        }
      }

      if (mounted && !addedMessage) {
        setState(() {
          _messages.add(
            _ChatMessage(
              text:
                  "I read your message but couldn't formulate a response. Let me know if you have another question!",
              isUser: false,
            ),
          );
        });
      }
    } catch (e) {
      debugPrint("DeepSeek Chat Exception: $e");
      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessage(
              text:
                  "Sorry, an issue occurred with the AI assistant service. Please check your network or try again later.",
              isUser: false,
            ),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle and header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF141053),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'DeepSeek AI Study Guide',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                Color(0xFF141053),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'DeepSeek is thinking...',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final message = _messages[index];
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      gradient: message.isUser
                          ? const LinearGradient(
                              colors: [Color(0xFF141053), Color(0xFF141053)],
                            )
                          : null,
                      color: message.isUser ? null : Colors.grey.shade100,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                        bottomRight: Radius.circular(message.isUser ? 4 : 16),
                      ),
                    ),
                    child: message.isUser
                        ? Text(
                            message.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          )
                        : MarkdownBody(
                            data: message.text,
                            selectable: true,
                            styleSheet:
                                MarkdownStyleSheet.fromTheme(
                                  Theme.of(context),
                                ).copyWith(
                                  p: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                  listBullet: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontSize: 14,
                                  ),
                                  strong: TextStyle(
                                    color: Colors.grey.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          ),
                  ),
                );
              },
            ),
          ),

          // Input field
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 12,
            ),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    enabled: !_isTyping,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                    decoration: InputDecoration(
                      hintText: _isTyping
                          ? 'Please wait for DeepSeek to respond...'
                          : 'Ask DeepSeek a follow-up question...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _isTyping
                        ? Colors.grey.shade400
                        : const Color(0xFF141053),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: _isTyping
                        ? null
                        : () => _sendMessage(_textController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
