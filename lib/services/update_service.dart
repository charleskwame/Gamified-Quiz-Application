import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Result of checking for an update.
class UpdateInfo {
  final bool available;
  final String latestVersion;
  final String currentVersion;
  final String? downloadUrl;
  final String? releaseNotes;

  UpdateInfo({
    required this.available,
    required this.latestVersion,
    required this.currentVersion,
    this.downloadUrl,
    this.releaseNotes,
  });
}

/// Service that checks GitHub Releases for a newer APK version
/// and provides an in-app notification to the user.
class UpdateService {
  static const String _repoOwner = 'charleskwame';
  static const String _repoName = 'Gamified-Quiz-Application';

  // Cache so we don't hit the API repeatedly
  UpdateInfo? _cachedInfo;
  DateTime? _lastCheck;

  /// Check if a newer version is available on GitHub Releases.
  /// Results are cached for 10 minutes to avoid rate limiting.
  Future<UpdateInfo> checkForUpdate({bool force = false}) async {
    // Use cache if within 10 minutes
    if (!force &&
        _cachedInfo != null &&
        _lastCheck != null &&
        DateTime.now().difference(_lastCheck!).inMinutes < 10) {
      return _cachedInfo!;
    }

    _lastCheck = DateTime.now();

    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Fetch latest release from GitHub API
      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest',
        ),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          // Add a user agent as required by GitHub API
          'User-Agent': 'Gamified-Quiz-App/$currentVersion',
        },
      );

      if (response.statusCode != 200) {
        // No release found or rate limited — not available
        _cachedInfo = UpdateInfo(
          available: false,
          latestVersion: currentVersion,
          currentVersion: currentVersion,
        );
        return _cachedInfo!;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final latestVersion = tagName.replaceAll(RegExp(r'^v'), '');
      final releaseBody = data['body'] as String?;
      final assets = data['assets'] as List<dynamic>? ?? [];

      // Find the arm64-v8a APK (most common for modern Android)
      // Fallback to any release APK
      String? downloadUrl;
      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        final browserUrl = asset['browser_download_url'] as String?;
        if (browserUrl != null && name.endsWith('.apk')) {
          // Prefer arm64-v8a
          if (name.contains('arm64-v8a') || name.contains('arm64')) {
            downloadUrl = browserUrl;
            break;
          }
          // Otherwise use any APK as fallback
          downloadUrl ??= browserUrl;
        }
      }

      // Compare versions using semantic versioning
      final available = _isNewerVersion(latestVersion, currentVersion);

      _cachedInfo = UpdateInfo(
        available: available,
        latestVersion: latestVersion,
        currentVersion: currentVersion,
        downloadUrl: downloadUrl,
        releaseNotes: releaseBody,
      );
      return _cachedInfo!;
    } catch (e) {
      debugPrint('UpdateService check failed: $e');
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      return UpdateInfo(
        available: false,
        latestVersion: currentVersion,
        currentVersion: currentVersion,
      );
    }
  }

  /// Simple semver comparison: returns true if [latest] > [current].
  bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();
      final currentParts = current
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();

      // Pad to equal length
      while (latestParts.length < 3) {
        latestParts.add(0);
      }
      while (currentParts.length < 3) {
        currentParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false; // Equal versions
    } catch (_) {
      return false;
    }
  }

  /// Launch the download URL in the browser so the user can download and
  /// install the APK manually.
  Future<bool> downloadUpdate(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      debugPrint('UpdateService download failed: $e');
      return false;
    }
  }
}
