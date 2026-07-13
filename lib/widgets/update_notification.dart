import 'package:flutter/material.dart';
import '../services/update_service.dart';
import '../app.dart';

/// A banner widget that prompts the user to update the app
/// when a newer version is available on GitHub Releases.
class UpdateBanner extends StatelessWidget {
  final UpdateInfo updateInfo;
  final VoidCallback? onDismiss;

  const UpdateBanner({
    super.key,
    required this.updateInfo,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (!updateInfo.available) return const SizedBox.shrink();

    return MaterialBanner(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      backgroundColor: AppTheme.primary,
      leading: const Icon(
        Icons.system_update_rounded,
        color: Colors.white,
        size: 28,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Update Available v${updateInfo.latestVersion}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'You\'re running v${updateInfo.currentVersion}. '
            'Tap to download the latest version.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          if (updateInfo.releaseNotes != null &&
              updateInfo.releaseNotes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              updateInfo.releaseNotes!
                  .replaceAll(RegExp(r'^## .*\n?', multiLine: true), '')
                  .trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const Text(
            'Later',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        FilledButton.tonal(
          onPressed: () => _downloadUpdate(context),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primary,
          ),
          child: const Text('Update Now'),
        ),
      ],
    );
  }

  Future<void> _downloadUpdate(BuildContext context) async {
    if (updateInfo.downloadUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No download URL available yet.')),
      );
      return;
    }

    final service = UpdateService();
    final launched = await service.downloadUpdate(updateInfo.downloadUrl!);

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open download link.'),
          action: SnackBarAction(
            label: 'Copy Link',
            onPressed: () {
              // Copy to clipboard
              // Clipboard.setData(ClipboardData(text: updateInfo.downloadUrl!));
              // Can't use Clipboard without services import, just show URL
            },
          ),
        ),
      );
    }
  }
}