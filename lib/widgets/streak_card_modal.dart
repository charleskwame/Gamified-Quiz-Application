import 'dart:ui' as ui;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/database_service.dart';

class StreakCardModal extends StatefulWidget {
  final int streakNumber;
  final String? avatarUrl;

  const StreakCardModal({
    super.key,
    required this.streakNumber,
    this.avatarUrl,
  });

  static void show(
    BuildContext context,
    int streakNumber, {
    String? avatarUrl,
  }) {
    showDialog(
      context: context,
      builder: (context) =>
          StreakCardModal(streakNumber: streakNumber, avatarUrl: avatarUrl),
    );
  }

  @override
  State<StreakCardModal> createState() => _StreakCardModalState();
}

class _StreakCardModalState extends State<StreakCardModal> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isDownloading = false;
  late List<Color> _gradientColors;

  @override
  void initState() {
    super.initState();
    _generateRandomGradient();
  }

  void _generateRandomGradient() {
    final random = Random();
    // Generate two random vibrant colors for the gradient
    final color1 = Color.fromARGB(
      255,
      100 + random.nextInt(155),
      50 + random.nextInt(150),
      150 + random.nextInt(105),
    );
    final color2 = Color.fromARGB(
      255,
      150 + random.nextInt(105),
      100 + random.nextInt(155),
      50 + random.nextInt(150),
    );
    _gradientColors = [color1, color2];
  }

  Future<void> _downloadCard() async {
    setState(() => _isDownloading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final RenderRepaintBoundary? boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Could not capture streak layout.');
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception('Failed to generate PNG data.');
      }

      final buffer = byteData.buffer;

      // Handle Permissions and Directory
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
          '${directory.path}/streak_${widget.streakNumber}_days.png';
      final File imgFile = File(path);

      await imgFile.writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🔥 Streak Card Saved successfully!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Saved to: $path',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF09262A),
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: const Color(0xFF931716),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40),
              const Text(
                'Daily Streak',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111C4A),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RepaintBoundary(
            key: _repaintKey,
            child: AspectRatio(
              aspectRatio: 1 / 1.4,
              child: Container(
                width: 280,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  // Avatar with flame badge overlay
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: ClipOval(
                          child:
                              widget.avatarUrl != null &&
                                  widget.avatarUrl!.isNotEmpty
                              ? SvgPicture.network(
                                  widget.avatarUrl!,
                                  fit: BoxFit.cover,
                                  placeholderBuilder: (context) => const Center(
                                    child: Icon(
                                      Icons.person_rounded,
                                      size: 50,
                                      color: Colors.white70,
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 50,
                                    color: Colors.white70,
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade600,
                                Colors.deepOrange,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.streakNumber > 0) ...[
                    const SizedBox(height: 24),
                    Text(
                      '${widget.streakNumber} Challenges Completed',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Keep the fire burning!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 24),
                    const Text(
                      'No streak yet!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Complete a session and answer at least half of the questions correctly to start your streak.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Streak stats unavailable',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isDownloading ? null : _downloadCard,
              icon: _isDownloading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.download_rounded, size: 16),
              label: Text(_isDownloading ? 'Saving...' : 'Save Card'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF111C4A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
