import 'dart:ui' as ui;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../services/database_service.dart';

class StreakCardModal extends StatefulWidget {
  final int streakNumber;

  const StreakCardModal({super.key, required this.streakNumber});

  static void show(BuildContext context, int streakNumber) {
    showDialog(
      context: context,
      builder: (context) => StreakCardModal(streakNumber: streakNumber),
    );
  }

  @override
  State<StreakCardModal> createState() => _StreakCardModalState();
}

class _StreakCardModalState extends State<StreakCardModal> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isDownloading = false;
  double _percentage = 0.0;
  bool _loadingStats = true;
  late List<Color> _gradientColors;

  @override
  void initState() {
    super.initState();
    _generateRandomGradient();
    _fetchStats();
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

  Future<void> _fetchStats() async {
    final percent = await DatabaseService().getStreakPercentage(
      widget.streakNumber,
    );
    if (mounted) {
      setState(() {
        _percentage = percent;
        _loadingStats = false;
      });
    }
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
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 72,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${widget.streakNumber} Challenges Completed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
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
                    child: _loadingStats
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Top ${_percentage.toStringAsFixed(1)}% of players have this streak',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
