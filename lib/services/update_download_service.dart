import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Thrown when an in-app update download is cancelled by the user.
class UpdateDownloadCancelledException implements Exception {
  const UpdateDownloadCancelledException();

  @override
  String toString() => 'Update download cancelled';
}

/// Downloads the release APK to local storage with progress reporting and
/// support for cancellation. Each instance should be used for a single
/// download.
class UpdateDownloader {
  final http.Client _client;
  StreamSubscription<List<int>>? _subscription;
  Completer<void>? _completer;
  bool _cancelled = false;

  UpdateDownloader({http.Client? client}) : _client = client ?? http.Client();

  /// Resolves a stable path for the downloaded APK. Uses the app's support
  /// directory (Android: internal `files` dir), which the FileProvider exposes
  /// to the system package installer.
  Future<String> resolveApkPath({
    String fileName = 'gamified_quiz_update.apk',
  }) async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}${Platform.pathSeparator}$fileName';
  }

  /// Downloads [url] to [savePath], invoking [onProgress] with
  /// `(downloadedBytes, totalBytes)`. Throws [UpdateDownloadCancelledException]
  /// if [cancel] is called, and cleans up the partial file on any failure.
  Future<void> download({
    required Uri url,
    required String savePath,
    required void Function(int downloaded, int total) onProgress,
  }) async {
    final response = await _client.send(http.Request('GET', url));
    if (response.statusCode != 200) {
      throw HttpException('Download failed with HTTP ${response.statusCode}');
    }

    final total = response.contentLength ?? 0;
    final file = File(savePath);
    final sink = file.openWrite();
    var downloaded = 0;
    _completer = Completer<void>();

    _subscription = response.stream.listen(
      (chunk) {
        if (_cancelled) {
          _completer?.completeError(const UpdateDownloadCancelledException());
          return;
        }
        downloaded += chunk.length;
        sink.add(chunk);
        onProgress(downloaded, total);
      },
      onDone: () async {
        await sink.close();
        if (!_completer!.isCompleted) _completer!.complete();
      },
      onError: (Object error, StackTrace stackTrace) async {
        await sink.close();
        if (!_completer!.isCompleted) {
          _completer!.completeError(error, stackTrace);
        }
      },
      cancelOnError: true,
    );

    try {
      await _completer!.future;
    } catch (_) {
      await sink.close();
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {
          // Best-effort cleanup; ignore failures.
        }
      }
      rethrow;
    }
  }

  /// Cancels an in-flight download (no-op if none is running).
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _subscription?.cancel();
    _completer?.completeError(const UpdateDownloadCancelledException());
  }

  void close() {
    _client.close();
  }
}
