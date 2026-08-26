import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/auth_service.dart';

/// Google Form web app URL used for the post-play evaluation questionnaire.
/// Email is pre-filled via the `entry.<FIELD_ID>` query param when a user is
/// signed in (see [_loadForm]).
const String _formUrl =
    'https://docs.google.com/forms/d/e/1FAIpQLSfa-edApd3ZeIY9pWE8I-xKbsxpKkaROt4BaQX1_qq_i6AK2A/viewform';

/// Internal Google Forms field ID for the "email" question. Pre-fill requires
/// this ID from the form's "Get pre-filled link" (cannot be derived from the
/// form URL alone).
const String _emailFieldId = 'entry.1340184307';

class EvaluationScreen extends StatefulWidget {
  const EvaluationScreen({super.key});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF0F8F8))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      );
    _loadForm();
  }

  /// Builds the evaluation form URL, pre-filling the email field with the
  /// signed-in user's Firebase email via the `entry.<FIELD_ID>` query param.
  ///
  /// - Signed-in user: loads `<formUrl>?entry.1340184307=<encoded email>`.
  /// - Guest / not signed in: loads the plain form URL, leaving email empty.
  ///
  /// `waitForSessionRestore()` is used instead of the raw `currentUser` so the
  /// email is still picked up on cold start, where Firebase Auth may take a
  /// moment to restore the persisted session and `currentUser` is briefly null.
  Future<void> _loadForm() async {
    String url = _formUrl;
    try {
      final user = await AuthService().waitForSessionRestore();
      final email = user?.email;
      if (email != null && email.isNotEmpty) {
        url = Uri.parse(_formUrl)
            .replace(queryParameters: {_emailFieldId: email})
            .toString();
      }
    } catch (_) {
      // Fall back to the plain form URL if auth isn't available.
    }
    if (!mounted) return;
    _controller.loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8F8),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: IconButton(
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
                ),
              ),
              
              // WebView area
              Expanded(
                child: Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF003F91),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
