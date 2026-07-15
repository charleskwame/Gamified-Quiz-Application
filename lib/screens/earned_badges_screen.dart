import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/badge.dart';
import '../services/database_service.dart';
import '../widgets/home/particle_background.dart';

class EarnedBadgesScreen extends StatefulWidget {
  final List<String> unlockedBadgeIds;
  final List<String> initialSelectedBadges;

  const EarnedBadgesScreen({
    super.key,
    required this.unlockedBadgeIds,
    required this.initialSelectedBadges,
  });

  @override
  State<EarnedBadgesScreen> createState() => _EarnedBadgesScreenState();
}

class _EarnedBadgesScreenState extends State<EarnedBadgesScreen> {
  final DatabaseService _db = DatabaseService();
  late List<String> _selectedBadges;
  final GlobalKey _repaintKey = GlobalKey();
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _selectedBadges = List<String>.from(widget.initialSelectedBadges);
  }

  Future<void> _toggleBadgeSelection(String badgeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      if (_selectedBadges.contains(badgeId)) {
        _selectedBadges.remove(badgeId);
      } else {
        if (_selectedBadges.length >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You can select a maximum of 3 badges to display in rankings.',
              ),
              backgroundColor: Color(0xFF931716),
            ),
          );
          return;
        }
        _selectedBadges.add(badgeId);
      }
    });

    try {
      await _db.updateSelectedBadges(user.uid, _selectedBadges);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update selections: $e'),
            backgroundColor: const Color(0xFF931716),
          ),
        );
      }
    }
  }

  Future<void> _downloadBadgeCard(BadgeDefinition badge) async {
    setState(() => _isDownloading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final RenderRepaintBoundary? boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Could not capture badge layout.');
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception('Failed to generate PNG data.');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      Directory? directory;
      if (Platform.isAndroid) {
        await Permission.storage.request();
        await Permission.photos.request();

        directory = Directory(
          '/storage/emulated/0/Pictures/Gamified Quiz App Badges',
        );
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final String path =
          '${directory.path}/${badge.name.replaceAll(' ', '_')}_achievement.png';
      final File imgFile = File(path);
      await imgFile.writeAsBytes(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🎉 Badge Card Saved successfully!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Saved to: $path',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF09262A),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: const Color(0xFF931716),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  void _showDownloadCardModal(BadgeDefinition badge) {
    double percentage = 0.0;
    bool loadingStats = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (loadingStats) {
              DatabaseService().getBadgeOwnershipPercentage(badge.id).then((
                val,
              ) {
                if (context.mounted) {
                  setModalState(() {
                    percentage = val;
                    loadingStats = false;
                  });
                }
              });
            }
            return AlertDialog(
              backgroundColor: const Color(0xFF1E2246),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RepaintBoundary(
                    key: _repaintKey,
                    child: Container(
                      width: 280,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: badge.color.withValues(alpha: 0.5),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: badge.color.withValues(alpha: 0.06),
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'GAMIFIED QUIZ APP',
                            style: TextStyle(
                              color: Colors.white30,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: badge.color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              badge.icon,
                              color: badge.color,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            badge.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            badge.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          loadingStats
                              ? const SizedBox(
                                  height: 14,
                                  width: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white70,
                                  ),
                                )
                              : Text(
                                  'Top ${percentage.toStringAsFixed(1)}% of players have this badge',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.greenAccent,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'OFFICIAL ACHIEVEMENT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Close',
                            style: TextStyle(color: Colors.white60),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isDownloading
                              ? null
                              : () async {
                                  setModalState(() => _isDownloading = true);
                                  await _downloadBadgeCard(badge);
                                  if (context.mounted) {
                                    setModalState(() => _isDownloading = false);
                                    Navigator.pop(context);
                                  }
                                },
                          icon: _isDownloading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.download_rounded, size: 16),
                          label: Text(
                            _isDownloading ? 'Saving...' : 'Save Card',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount = allBadges
        .where((b) => widget.unlockedBadgeIds.contains(b.id))
        .length;
    final progress = unlockedCount / allBadges.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ParticleBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                _StaggeredFadeSlide(index: 0, child: _buildHeader()),

                const SizedBox(height: 20),

                // ── Progress Card ──
                _StaggeredFadeSlide(
                  index: 1,
                  child: _buildProgressCard(unlockedCount, progress),
                ),

                const SizedBox(height: 32),

                // ── Section Title ──
                _StaggeredFadeSlide(
                  index: 2,
                  child: Text(
                    'All Achievements (${allBadges.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Badge Grid ──
                _StaggeredFadeSlide(
                  index: 3,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.76,
                        ),
                    itemCount: allBadges.length,
                    itemBuilder: (context, index) {
                      final badge = allBadges[index];
                      final isUnlocked = widget.unlockedBadgeIds.contains(
                        badge.id,
                      );
                      final isSelected = _selectedBadges.contains(badge.id);

                      return _buildBadgeGridItem(
                        badge: badge,
                        isUnlocked: isUnlocked,
                        isSelected: isSelected,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),
              ],
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
        const SizedBox(width: 16),
        const Text(
          'Badges & Achievements',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  //  Progress Card
  // ──────────────────────────────────────────────

  Widget _buildProgressCard(int unlockedCount, double progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR PROGRESS',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$unlockedCount of ${allBadges.length} Unlocked',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFFFD700),
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF6366F1),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tapping unlocked badges displays them in your rank profile (max 3).',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Badge Grid Item
  // ──────────────────────────────────────────────

  Widget _buildBadgeGridItem({
    required BadgeDefinition badge,
    required bool isUnlocked,
    required bool isSelected,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF6366F1)
              : (isUnlocked
                    ? badge.color.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.06)),
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.06),
              blurRadius: 3,
            ),
          if (isUnlocked && !isSelected)
            BoxShadow(
              color: badge.color.withValues(alpha: 0.03),
              blurRadius: 2,
            ),
        ],
      ),
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isUnlocked ? () => _toggleBadgeSelection(badge.id) : null,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Opacity(
                  opacity: isUnlocked ? 1.0 : 0.5,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? badge.color.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isUnlocked ? badge.icon : Icons.lock_rounded,
                          color: isUnlocked ? badge.color : Colors.white38,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        badge.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isUnlocked ? Colors.white : Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          badge.description,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(
                              alpha: isUnlocked ? 0.5 : 0.3,
                            ),
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (isUnlocked)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showDownloadCardModal(badge),
                            icon: const Icon(Icons.share_rounded, size: 12),
                            label: const Text(
                              'Export Card',
                              style: TextStyle(fontSize: 11),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              foregroundColor: Colors.white70,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
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
          if (isSelected)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Staggered Fade-Slide — matching app-wide entrance animation
// ═══════════════════════════════════════════════════════════════

class _StaggeredFadeSlide extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredFadeSlide({required this.index, required this.child});

  @override
  State<_StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<_StaggeredFadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final startDelay = Duration(milliseconds: 100 * widget.index);
    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
          ),
        );

    Future.delayed(startDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnim,
      child: SlideTransition(position: _slideAnim, child: widget.child),
    );
  }
}
