import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import '../widgets/home/particle_background.dart';
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
      backgroundColor: Colors.transparent,
      body: ParticleBackground(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  _buildHeader(),

                  const SizedBox(height: 24),

                  // ── Title ──
                  const Text(
                    'Report a Bug',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Help us improve the app by reporting any issues you encounter.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Email (read-only) ──
                  _buildReadOnlyField(
                    label: 'Your Email',
                    value: email,
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 20),

                  // ── Bug Description ──
                  _buildLabel('Bug Description *'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    maxLength: 2000,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      hintText: 'Describe the bug in detail...',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Expected Behavior ──
                  _buildLabel('Expected Behavior (optional)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _expectedBehaviorController,
                    maxLines: 3,
                    maxLength: 1000,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      hintText: 'What did you expect to happen?',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── App Version (read-only) ──
                  _buildReadOnlyField(
                    label: 'App Version',
                    value: appVersion,
                    icon: Icons.info_outline_rounded,
                  ),
                  const SizedBox(height: 32),

                  // ── Submit Button ──
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8C52FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _submitBugReport,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          disabledBackgroundColor: Colors.white.withValues(
                            alpha: 0.06,
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
                                  Icon(Icons.bug_report_rounded, size: 20),
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
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Header with back button
  // ──────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.white,
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ),
      ],
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
        _buildLabel(label),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.4)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
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
  //  Label widget
  // ──────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Input decoration for text fields
  // ──────────────────────────────────────────────

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
