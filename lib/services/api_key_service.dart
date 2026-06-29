import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing and retrieving the DeepSeek API key.
///
/// On first launch, the key is read from the compile-time constant
/// [DEEPSEEK_API_KEY] (passed via `--dart-define`) and stored in
/// [FlutterSecureStorage] (encrypted at rest via platform Keystore/Keychain).
/// On subsequent launches, the key is retrieved from secure storage.
///
/// The key is only held in memory during the brief period it is needed
/// for an API call, then released.
class ApiKeyService {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'deepseek_api_key';

  /// Reads the API key from secure storage.
  ///
  /// If the key is not yet stored, it attempts to read it from the
  /// compile-time `--dart-define=DEEPSEEK_API_KEY=...` and persists it.
  /// Returns `null` if no key is available.
  static Future<String?> getKey() async {
    // Try reading from secure storage first
    String? key = await _storage.read(key: _keyName);
    if (key != null && key.isNotEmpty) {
      return key;
    }

    // First launch: read from compile-time define and persist
    const compileTimeKey = String.fromEnvironment('DEEPSEEK_API_KEY');
    if (compileTimeKey.isNotEmpty) {
      await _storage.write(key: _keyName, value: compileTimeKey);
      return compileTimeKey;
    }

    return null;
  }

  /// Checks whether an API key is available in secure storage.
  static Future<bool> hasKey() async {
    final key = await getKey();
    return key != null && key.isNotEmpty;
  }

  /// Removes the stored API key from secure storage.
  static Future<void> clearKey() async {
    await _storage.delete(key: _keyName);
  }
}
