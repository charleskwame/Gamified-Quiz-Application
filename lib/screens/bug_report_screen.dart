import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import 'package:flutter/services.dart';

/// Google Apps Script Web App URL for bug report submissions.
/// Deployed script appends rows to a Google Sheet with columns:
/// Timestamp, Email, Bug Report, Expected Behavior, App Version, Status
const String _bugReportUrl =
    'https://script.google.com/macros/s/AKfycbxyRT4kl53fNkvXQTLp4inBBcbfBOSsWfa5UOX0RlUAygZbyBSkabuJAq6o6sucpHbb/exec';

class BugReportScreen extends StatefulWidget {
  const BugReportScreen({super.key});

  @override
  State<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends State<BugReportScreen> {
  final AuthService _authService = AuthService();
  final _descriptionController = TextEditingController();
  final _expectedBehaviorController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _expectedBehaviorController.dispose();
    super.dispose();
  }

  String _getAppVersion() {
    // Matches the version in pubspec.yaml: 1.1.0+3
    return '1.1.0+3';
  }

  Future<void> _submitBugReport() async {
    final description = _descriptionController.text.trim();

    if (description.isEmpty) {
      _showSnackBar('Please describe the bug.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = _authService.currentUser;
      final email = user?.email ?? 'unknown@guest';
      final expectedBehavior = _expectedBehaviorController.text.trim();
      final appVersion = _getAppVersion();

      final payload = {
        'email': email,
        'bugReport': description,
        'expectedBehavior': expectedBehavior,
        'appVersion': appVersion,
      };

      // Using http.post directly. It automatically follows 302 redirects by converting
      // POST to GET on redirect. Since Google Apps Script processes doPost on the
      // initial POST and returns the result at the redirect target via GET, this is
      // the correct behavior to read the JSON response.
      final response = await http.post(
        Uri.parse(_bugReportUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (!mounted) return;

      // Google Apps Script returns 302 on redirect, or 200 when followed.
      // Any 2xx or 3xx status code indicates the server successfully received the request.
      if (response.statusCode >= 200 && response.statusCode < 400) {
        _showSnackBar('Bug report submitted successfully! Thank you.');
        Navigator.pop(context);
      } else {
        _showSnackBar(
          'Failed to submit report. Please try again later.',
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
    final user = _authService.currentUser;
    final email = user?.email ?? '';
    final appVersion = _getAppVersion();

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
                    'Report a Bug',
                    style: TextStyle(
                      color: Color(0xFF011627),
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Help us improve the app by reporting any issues you encounter.',
                    style: TextStyle(
                      color: const Color(0xFF011627).withValues(alpha: 0.6),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Form Card ──
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF003F91,
                          ).withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Email (read-only) ──
                        _buildReadOnlyField(
                          label: 'Your Email',
                          value: email,
                          icon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 20),

                        // ── Bug Description ──
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Bug Description *',
                          hint: 'Describe the bug in detail...',
                          icon: Icons.bug_report_outlined,
                          maxLines: 5,
                          maxLength: 2000,
                        ),
                        const SizedBox(height: 20),

                        // ── Expected Behavior ──
                        _buildTextField(
                          controller: _expectedBehaviorController,
                          label: 'Expected Behavior (optional)',
                          hint: 'What did you expect to happen?',
                          icon: Icons.lightbulb_outline,
                          maxLines: 3,
                          maxLength: 1000,
                        ),
                        const SizedBox(height: 20),

                        // ── App Version (read-only) ──
                        _buildReadOnlyField(
                          label: 'App Version',
                          value: appVersion,
                          icon: Icons.info_outline_rounded,
                        ),
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
                              onPressed: _isSubmitting
                                  ? null
                                  : _submitBugReport,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.bug_report_rounded,
                                          size: 20,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Submit Bug Report',
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
          color: Color(0xFF011627),
          size: 22,
        ),
      ),
      onPressed: () => Navigator.pop(context),
    );
  }

  // ──────────────────────────────────────────────
  //  Read-only field (email, app version)
  // ──────────────────────────────────────────────

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF011627),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFECF8F8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFB0C4DE)),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: const Color(0xFF011627).withValues(alpha: 0.35),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value.isNotEmpty ? value : 'Not signed in',
                  style: TextStyle(
                    color: value.isNotEmpty
                        ? const Color(0xFF011627).withValues(alpha: 0.7)
                        : const Color(0xFF011627).withValues(alpha: 0.35),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  //  Text field with label, icon (matching auth_screen)
  // ──────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int maxLength = 1000,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF011627),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          style: const TextStyle(color: Color(0xFF011627), fontSize: 15),
          cursorColor: const Color(0xFF003F91),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: const Color(0xFF011627).withValues(alpha: 0.3),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF011627).withValues(alpha: 0.35),
              size: 20,
            ),
            filled: true,
            fillColor: const Color(0xFFECF8F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFB0C4DE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFB0C4DE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF003F91),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            counterStyle: TextStyle(
              color: const Color(0xFF011627).withValues(alpha: 0.35),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
