import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import 'quiz_play_screen.dart';

class ChallengeSelectScreen extends StatefulWidget {
  final String category;
  final IconData icon;

  const ChallengeSelectScreen({
    super.key,
    required this.category,
    required this.icon,
  });

  @override
  State<ChallengeSelectScreen> createState() => _ChallengeSelectScreenState();
}

class _ChallengeSelectScreenState extends State<ChallengeSelectScreen> {
  final DatabaseService _db = DatabaseService();
  bool _isDownloading = false;
  bool _hasOffline = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _checkOfflineStatus();
  }

  Future<void> _checkOfflineStatus() async {
    final status = await _db.hasOfflineQuestions(widget.category);
    if (mounted) {
      setState(() {
        _hasOffline = status;
      });
    }
  }

  Future<void> _downloadOffline() async {
    setState(() {
      _isDownloading = true;
      _message = null;
    });

    try {
      await _db.downloadQuestionsForOffline(widget.category);
      if (!mounted) return;
      setState(() {
        _hasOffline = true;
        _message = 'Successfully downloaded 50 questions for offline use!';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'Failed to download: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  void _startQuiz({required bool isTimed, required bool isOffline}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizPlayScreen(
          category: widget.category,
          isTimed: isTimed,
          isOffline: isOffline,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  widget.icon,
                  size: 50,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Select Challenge Mode',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose how you want to test your skills today.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
              ),
              const SizedBox(height: 36),

              if (_message != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.green.shade800, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Normal Mode Card
              _ModeCard(
                title: 'Normal Challenge',
                description: 'Answer quiz questions with no timer limits. Recommended for learning.',
                icon: Icons.hourglass_disabled_rounded,
                color: const Color(0xFF5B5FEF),
                onTap: () => _startQuiz(isTimed: false, isOffline: false),
              ),
              const SizedBox(height: 16),

              // Timed Mode Card
              _ModeCard(
                title: 'Timed Challenge',
                description: '15 seconds per question. Think fast, test your reflexes under pressure!',
                icon: Icons.timer_rounded,
                color: const Color(0xFFFF5722),
                onTap: () => _startQuiz(isTimed: true, isOffline: false),
              ),
              const SizedBox(height: 16),

              // Offline Mode Card (only if downloaded)
              if (_hasOffline) ...[
                _ModeCard(
                  title: 'Play Offline',
                  description: 'Play with locally saved questions. No internet connection required.',
                  icon: Icons.wifi_off_rounded,
                  color: const Color(0xFF4CAF50),
                  onTap: () => _startQuiz(isTimed: false, isOffline: true),
                ),
                const SizedBox(height: 24),
              ],

              const Divider(height: 32, color: Color(0xFFE6EAF2)),

              // Download Button
              if (user != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isDownloading ? null : _downloadOffline,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _hasOffline
                                ? Icons.cloud_done_rounded
                                : Icons.cloud_download_rounded,
                          ),
                    label: Text(
                      _isDownloading
                          ? 'Downloading...'
                          : _hasOffline
                              ? 'Update Offline Questions (50 Saved)'
                              : 'Download 50 Questions for Offline Use',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(
                        color: _hasOffline
                            ? const Color(0xFF4CAF50)
                            : Theme.of(context).colorScheme.primary,
                      ),
                      foregroundColor: _hasOffline
                          ? const Color(0xFF4CAF50)
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EAF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05121826),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF121826),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF9AA2AF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
