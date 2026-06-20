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
    // Copy initial selection list
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
          // Show error toast/message using warning color
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
      // Small delay to ensure widget is fully rendered in dialog/screen
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

      // Find path to documents/external directory
      Directory? directory;
      if (Platform.isAndroid) {
        // Request storage permissions
        await Permission.storage.request();
        // Also request photos permission for Android 13+
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
        // Show success toast in deep teal #09262A
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
              DatabaseService().getBadgeOwnershipPercentage(badge.id).then((val) {
                if (context.mounted) {
                  setModalState(() {
                    percentage = val;
                    loadingStats = false;
                  });
                }
              });
            }
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // RepaintBoundary wrapping the premium card widget
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
                            color: badge.color.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
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
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
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
                          child: const Text('Close'),
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
                            backgroundColor: const Color(0xFF111C4A),
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
      appBar: AppBar(
        title: const Text(
          'Badges & Achievements',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF121826),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Progress Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF111C4A), Color(0xFF283A8C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF111C4A).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'YOUR PROGRESS',
                              style: TextStyle(
                                color: Colors.white70,
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
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.white,
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
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tapping unlocked badges displays them in your rank profile (max 3).',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'All Achievements (${allBadges.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF121826),
                ),
              ),
              const SizedBox(height: 16),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.76,
                ),
                itemCount: allBadges.length,
                itemBuilder: (context, index) {
                  final badge = allBadges[index];
                  final isUnlocked = widget.unlockedBadgeIds.contains(badge.id);
                  final isSelected = _selectedBadges.contains(badge.id);

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF111C4A)
                            : (isUnlocked
                                  ? badge.color.withValues(alpha: 0.25)
                                  : const Color(0xFFE6EAF2)),
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? const Color(0xFF111C4A).withValues(alpha: 0.08)
                              : const Color(0x05121826),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isUnlocked
                                ? () => _toggleBadgeSelection(badge.id)
                                : null,
                            borderRadius: BorderRadius.circular(24),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                20,
                                16,
                                12,
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isUnlocked
                                          ? badge.color.withValues(alpha: 0.1)
                                          : const Color(0xFFF4F6FB),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isUnlocked
                                          ? badge.icon
                                          : Icons.lock_rounded,
                                      color: isUnlocked
                                          ? badge.color
                                          : const Color(0xFF9CA3AF),
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    badge.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF121826),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Expanded(
                                    child: Text(
                                      badge.description,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF6B7280),
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (isUnlocked)
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _showDownloadCardModal(badge),
                                        icon: const Icon(
                                          Icons.share_rounded,
                                          size: 12,
                                        ),
                                        label: const Text(
                                          'Export Card',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
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
                                color: Color(0xFF111C4A),
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
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
