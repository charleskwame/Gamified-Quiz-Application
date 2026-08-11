import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Describes a newer release that the installed app should be updated to.
class UpdateInfo {
  /// Version of the latest GitHub release (normalized, e.g. "1.2.0").
  final String latestVersion;

  /// Installed app version (normalized).
  final String installedVersion;

  /// Direct `.apk` asset URL, falling back to the release page.
  final String downloadUrl;

  /// Optional release notes (GitHub release body, may be markdown).
  final String? releaseNotes;

  const UpdateInfo({
    required this.latestVersion,
    required this.installedVersion,
    required this.downloadUrl,
    this.releaseNotes,
  });
}

/// Fetches the latest release from GitHub and compares it to the installed
/// version. Any failure (offline, rate limit, malformed response) silently
/// returns null so the app startup is never blocked.
class UpdateCheckService {
  static const String _repoOwner = 'charleskwame';
  static const String _repoName = 'Gamified-Quiz-Application';

  /// When true the update dialog cannot be dismissed (force update).
  /// Compile-time flag - flip to true for releases users MUST install.
  static const bool forceUpdate = true;

  static const String _releasesUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  static const Duration _timeout = Duration(seconds: 8);

  final http.Client _client;

  UpdateCheckService({http.Client? client}) : _client = client ?? http.Client();

  /// Returns [UpdateInfo] when a newer release exists, otherwise null.
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final installedVersion = normalizeVersion(packageInfo.version);

      final response = await _client
          .get(
            Uri.parse(_releasesUrl),
            headers: const {
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'Gamified-Quiz-App',
            },
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return null;

      final latestVersion = normalizeVersion(data['tag_name'] as String? ?? '');
      if (latestVersion.isEmpty) return null;

      if (compareVersions(installedVersion, latestVersion) >= 0) return null;

      final downloadUrl =
          _findApkUrl(data['assets']) ?? (data['html_url'] as String?);
      if (downloadUrl == null || downloadUrl.isEmpty) return null;

      return UpdateInfo(
        latestVersion: latestVersion,
        installedVersion: installedVersion,
        downloadUrl: downloadUrl,
        releaseNotes: data['body'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  String? _findApkUrl(Object? assets) {
    if (assets is! List) return null;
    for (final asset in assets) {
      if (asset is! Map<String, dynamic>) continue;
      final name = asset['name'] as String? ?? '';
      final url = asset['browser_download_url'] as String?;
      if (url != null && name.toLowerCase().endsWith('.apk')) return url;
    }
    return null;
  }
}

/// Strips a leading "v", surrounding whitespace, and any "+build" suffix from
/// a version string (e.g. "v1.2.0+3" -> "1.2.0").
String normalizeVersion(String version) {
  var v = version.trim();
  if (v.toLowerCase().startsWith('v')) v = v.substring(1);
  final plus = v.indexOf('+');
  if (plus >= 0) v = v.substring(0, plus);
  return v;
}

/// Compares two (pre-normalized) semantic versions.
/// Returns <0 if [a] < [b], 0 if equal, >0 if [a] > [b].
int compareVersions(String a, String b) {
  final aParts = _versionParts(a);
  final bParts = _versionParts(b);
  final length = aParts.length > bParts.length ? aParts.length : bParts.length;
  for (var i = 0; i < length; i++) {
    final aValue = i < aParts.length ? aParts[i] : 0;
    final bValue = i < bParts.length ? bParts[i] : 0;
    if (aValue != bValue) return aValue - bValue;
  }
  return 0;
}

List<int> _versionParts(String version) {
  // Pre-release/build suffixes (e.g. "-rc1") are ignored for comparison.
  final core = version.split('-').first;
  return core
      .split('.')
      .map((segment) => int.tryParse(segment.trim()) ?? 0)
      .toList();
}
