import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where credentials live on a native device: the platform keystore (Android
/// Keystore / iOS Keychain) rather than a plain file in the app's documents.
///
/// An interface so tests can swap in memory.
abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// [SecretStore] over `flutter_secure_storage`.
class PlatformSecretStore implements SecretStore {
  PlatformSecretStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
