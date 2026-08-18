import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app.dart';
import '../services/update_check_service.dart';
import '../services/update_download_service.dart';

enum _UpdatePhase { prompt, downloading, ready }

/// "Update available" dialog shown when the installed version is older than
/// the latest GitHub release. On Android the release APK is downloaded in-app
/// (with progress + cancel) and handed to the system package installer; on
/// other platforms the download link is opened externally instead.
class UpdateAppDialog extends StatefulWidget {
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

  @override
  State<UpdateAppDialog> createState() => _UpdateAppDialogState();
}

class _UpdateAppDialogState extends State<UpdateAppDialog> {
  _UpdatePhase _phase = _UpdatePhase.prompt;
  int _downloadedBytes = 0;
  int _totalBytes = 0;
  String? _apkPath;
  UpdateDownloader? _downloader;

  bool get _isAndroid => Platform.isAndroid;

  @override
  void dispose() {
    _downloader?.close();
    super.dispose();
  }

  Future<void> _startDownload() async {
    // Non-Android platforms cannot install APKs; fall back to the browser.
    if (!_isAndroid) {
      final launched = await launchUrl(
        Uri.parse(widget.info.downloadUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showMessage('Could not open the download link.');
      }
      return;
    }

    setState(() {
      _phase = _UpdatePhase.downloading;
      _downloadedBytes = 0;
      _totalBytes = 0;
    });

    final downloader = _downloader ??= UpdateDownloader();
    try {
      final path = await downloader.resolveApkPath();
      _apkPath = path;

      await downloader.download(
        url: Uri.parse(widget.info.downloadUrl),
        savePath: path,
        onProgress: (downloaded, total) {
          if (!mounted) return;
          setState(() {
            _downloadedBytes = downloaded;
            _totalBytes = total;
          });
        },
      );

      if (!mounted) return;
      setState(() => _phase = _UpdatePhase.ready);
    } on UpdateDownloadCancelledException {
      if (mounted) {
        setState(() => _phase = _UpdatePhase.prompt);
        _showMessage('Download cancelled.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _phase = _UpdatePhase.prompt);
        _showMessage('Download failed: $error');
      }
    }
  }

  void _cancelDownload() {
    _downloader?.cancel();
  }

  Future<void> _install() async {
    final path = _apkPath;
    if (path == null) return;

    final result = await OpenFilex.open(
      path,
      type: 'application/vnd.android.package-archive',
    );
    if (!mounted) return;
    if (result.type != ResultType.done) {
      _showMessage('Could not open the installer (${result.message}).');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const int kb = 1024;
    const int mb = kb * 1024;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  Widget _buildTitle() {
    return Row(
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
        Expanded(
          child: Text(switch (_phase) {
            _UpdatePhase.prompt => 'Update Available',
            _UpdatePhase.downloading => 'Downloading Update',
            _UpdatePhase.ready => 'Ready to Install',
          }),
        ),
      ],
    );
  }

  Widget _buildWhatsNew(ThemeData theme) {
    final notes = widget.info.releaseNotes ?? '';
    final showNotes = _hasMeaningfulReleaseNotes(notes);
    final commits = widget.info.commitMessages;

    if (!showNotes && commits.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text("What's new", style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        // Git commit messages are the primary "what was implemented" content.
        if (commits.isNotEmpty)
          ...commits
              .take(30)
              .map(
                (message) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Icon(
                          Icons.circle,
                          size: 6,
                          color: AppTheme.indigoAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(message, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
        if (showNotes) ...[
          if (commits.isNotEmpty) const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 160),
            child: MarkdownBody(data: notes),
          ),
        ],
      ],
    );
  }

  /// GitHub's release automation appends an auto-generated
  /// "**Full Changelog**" link to every release body. A body made up only of
  /// that link adds no value, so it is hidden in favour of the commit messages.
  bool _hasMeaningfulReleaseNotes(String notes) {
    final trimmed = notes.trim();
    if (trimmed.isEmpty) return false;
    final lower = trimmed.toLowerCase();
    final changelogIndex = lower.indexOf('full changelog');
    if (changelogIndex < 0) return true;
    // Keep only text that appears before the auto-generated changelog link.
    // If that is just markdown markers or whitespace, the body has no real
    // content, so hide it.
    final before = trimmed.substring(0, changelogIndex);
    final meaningful = before
        .replaceAll(RegExp(r'[\s*_`#>\-:]'), '')
        .isNotEmpty;
    return meaningful;
  }

  Widget _buildPromptContent(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Version ${widget.info.latestVersion} is now available '
          '(you have ${widget.info.installedVersion}).',
          style: theme.textTheme.bodyLarge,
        ),
        _buildWhatsNew(theme),
      ],
    );
  }

  Widget _buildDownloadingContent(ThemeData theme) {
    final double? progress = _totalBytes > 0
        ? (_downloadedBytes / _totalBytes).clamp(0.0, 1.0)
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Downloading version ${widget.info.latestVersion}…',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.indigoAccent,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          progress != null
              ? '${(progress * 100).round()}% · '
                    '${_formatBytes(_downloadedBytes)} / ${_formatBytes(_totalBytes)}'
              : '${_formatBytes(_downloadedBytes)} downloaded',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildReadyContent(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Version ${widget.info.latestVersion} has been downloaded '
          '(${_formatBytes(_totalBytes)}).',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap Install to open the package installer and update the app.',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = !widget.forceUpdate && _phase != _UpdatePhase.downloading;

    final List<Widget> actions = switch (_phase) {
      _UpdatePhase.prompt => [
        if (!widget.forceUpdate)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
        FilledButton(
          onPressed: _startDownload,
          child: Text(widget.forceUpdate ? 'Update Now' : 'Update'),
        ),
      ],
      _UpdatePhase.downloading => [
        TextButton(onPressed: _cancelDownload, child: const Text('Cancel')),
      ],
      _UpdatePhase.ready => [
        if (!widget.forceUpdate)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        FilledButton(onPressed: _install, child: const Text('Install')),
      ],
    };

    return PopScope(
      canPop: canPop,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: _buildTitle(),
        content: SingleChildScrollView(
          child: switch (_phase) {
            _UpdatePhase.prompt => _buildPromptContent(theme),
            _UpdatePhase.downloading => _buildDownloadingContent(theme),
            _UpdatePhase.ready => _buildReadyContent(theme),
          },
        ),
        actions: actions,
      ),
    );
  }
}
