import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app.dart';
import '../services/update_check_service.dart';

/// "Update available" dialog shown when the installed version is older than
/// the latest GitHub release. When [forceUpdate] is true the dialog cannot be
/// dismissed and the user must update to continue.
class UpdateAppDialog extends StatelessWidget {
  final UpdateInfo info;
  final bool forceUpdate;

  const UpdateAppDialog({
    super.key,
    required this.info,
    required this.forceUpdate,
  });

  static void show(
    BuildContext context,
    UpdateInfo info, {
    bool forceUpdate = UpdateCheckService.forceUpdate,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) =>
          UpdateAppDialog(info: info, forceUpdate: forceUpdate),
    );
  }

  Future<void> _update(BuildContext context) async {
    final launched = await launchUrl(
      Uri.parse(info.downloadUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the download link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showNotes =
        info.releaseNotes != null && info.releaseNotes!.trim().isNotEmpty;

    return PopScope(
      canPop: !forceUpdate,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.system_update_alt_rounded,
                color: AppTheme.indigoAccent,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Update Available')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version ${info.latestVersion} is now available '
                '(you have ${info.installedVersion}).',
                style: theme.textTheme.bodyLarge,
              ),
              if (showNotes) ...[
                const SizedBox(height: 12),
                Text("What's new", style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: MarkdownBody(data: info.releaseNotes!),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
          FilledButton(
            onPressed: () => _update(context),
            child: Text(forceUpdate ? 'Update Now' : 'Update'),
          ),
        ],
      ),
    );
  }
}
