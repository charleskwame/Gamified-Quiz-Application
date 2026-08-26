import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/evaluation_question.dart';
import '../services/auth_service.dart';

/// Google Apps Script Web App URL for evaluation submissions.
/// Deployed script appends rows to a Google Sheet with columns:
/// Timestamp, Email, Q1..Q20, App Version
/// When empty, submissions are only acknowledged locally (no network call).
const String _evaluationUrl =
    'https://script.google.com/macros/s/AKfycbz6NGKpCkrPIFAwWHy4vQ22AbTSd-RsDYU83gUwL9sD8x8NWeR30NwrttOSlxexJ4fr/exec';

class EvaluationScreen extends StatefulWidget {
  const EvaluationScreen({super.key});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  final AuthService _authService = AuthService();

  /// Maps question number → selected rating (1–5).
  final Map<int, int> _ratings = {};
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  String _getAppVersion() {
    return '1.2.11+10211';
  }

  Future<void> _submitEvaluation() async {
    if (_ratings.length < evaluationQuestions.length) {
      _showSnackBar(
        'Please answer all questions before submitting. '
        '(${_ratings.length}/${evaluationQuestions.length} answered)',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // If the Google Form endpoint is not configured yet, acknowledge locally.
      if (_evaluationUrl.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        setState(() => _isSubmitted = true);
        return;
      }

      final user = _authService.currentUser;
      final email = user?.email ?? 'unknown@guest';
      final appVersion = _getAppVersion();

      final answers = <String, dynamic>{};
      for (final entry in _ratings.entries) {
        answers['Q${entry.key}'] = entry.value;
      }

      final payload = {'email': email, 'appVersion': appVersion, ...answers};

      // Using http.post directly. It automatically follows 302 redirects by
      // converting POST to GET on redirect. Since Google Apps Script processes
      // doPost on the initial POST and returns the result at the redirect
      // target via GET, this is the correct behavior to read the JSON response.
      final response = await http.post(
        Uri.parse(_evaluationUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (!mounted) return;

      // Google Apps Script returns 302 on redirect, or 200 when followed.
      // Any 2xx or 3xx status code indicates the server successfully received
      // the request.
      if (response.statusCode >= 200 && response.statusCode < 400) {
        setState(() => _isSubmitted = true);
      } else {
        _showSnackBar(
          'Failed to submit evaluation. Please try again later.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        'Network error. Please check your connection and try again.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF4ADE80),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return _buildThankYouScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8F8),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0F8F8),
              Color(0xFFE8F4F4),
              Color(0xFFE0F0F0),
              Color(0xFFD8ECEC),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  _buildHeader(),

                  const SizedBox(height: 32),

                  // ── Title ──
                  const Text(
                    'App Evaluation',
                    style: TextStyle(
                      color: Color(0xFF003F91),
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rate each question on a scale of 1 to 5. '
                    '1 means the lowest / most negative rating. '
                    '5 means the highest / most positive rating.',
                    style: TextStyle(
                      color: const Color(0xFF003F91).withValues(alpha: 0.6),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Questions ──
                  ...evaluationQuestions.map((q) {
                    return _RatingQuestionCard(
                      evaluationQuestion: q,
                      selectedRating: _ratings[q.number],
                      onRatingSelected: (rating) {
                        setState(() {
                          _ratings[q.number] = rating;
                        });
                      },
                    );
                  }),

                  const SizedBox(height: 28),

                  // ── Submit Button ──
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xFF003F91),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF003F91,
                            ).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _submitEvaluation,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.rate_review_rounded, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'Submit Evaluation',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Header with back button
  // ──────────────────────────────────────────────

  Widget _buildHeader() {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF003F91).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: Color(0xFF003F91),
          size: 22,
        ),
      ),
      onPressed: () => Navigator.pop(context),
    );
  }

  // ──────────────────────────────────────────────
  //  Thank-you screen after submission
  // ──────────────────────────────────────────────

  Widget _buildThankYouScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8F8),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0F8F8),
              Color(0xFFE8F4F4),
              Color(0xFFE0F0F0),
              Color(0xFFD8ECEC),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF003F91).withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF4ADE80),
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Thank You!',
                  style: TextStyle(
                    color: Color(0xFF003F91),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your evaluation has been submitted successfully. '
                  'We appreciate your feedback!',
                  style: TextStyle(
                    color: const Color(0xFF003F91).withValues(alpha: 0.6),
                    fontSize: 15,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF003F91),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Back to Profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A custom rating question card that renders a 1–5 rating scale.
class _RatingQuestionCard extends StatelessWidget {
  final EvaluationQuestion evaluationQuestion;
  final int? selectedRating;
  final void Function(int rating) onRatingSelected;

  const _RatingQuestionCard({
    required this.evaluationQuestion,
    required this.selectedRating,
    required this.onRatingSelected,
  });

  @override
  Widget build(BuildContext context) {
    final category = evaluationQuestion.category;
    final number = evaluationQuestion.number;
    final minLabel = evaluationQuestion.minLabel;
    final maxLabel = evaluationQuestion.maxLabel;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category + number badge
            Padding(
              padding: const EdgeInsets.only(top: 20, right: 20, left: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003F91).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: const Color(0xFF003F91),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Q$number',
                    style: TextStyle(
                      color: const Color(0xFF003F91).withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Question text
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 20, left: 20),
              child: Text(
                evaluationQuestion.question,
                style: const TextStyle(
                  color: Color(0xFF003F91),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            // Rating scale
            Padding(
              padding: const EdgeInsets.only(top: 12, right: 20, left: 20),
              child: _RatingScale(
                selectedRating: selectedRating,
                onRatingSelected: onRatingSelected,
              ),
            ),
            // Min/max labels
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 20, left: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '1 = $minLabel',
                      style: TextStyle(
                        color: const Color(0xFF003F91).withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '5 = $maxLabel',
                      style: TextStyle(
                        color: const Color(0xFF003F91).withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// A 1–5 rating scale with selectable buttons.
class _RatingScale extends StatelessWidget {
  final int? selectedRating;
  final void Function(int rating) onRatingSelected;

  const _RatingScale({
    required this.selectedRating,
    required this.onRatingSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (index) {
        final value = index + 1;
        final isSelected = selectedRating == value;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: InkWell(
            onTap: () => onRatingSelected(value),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF003F91)
                    : const Color(0xFF003F91).withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: isSelected
                    ? null
                    : Border.all(
                        color: const Color(0xFF003F91).withValues(alpha: 0.2),
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF003F91).withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                '$value',
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF003F91),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
