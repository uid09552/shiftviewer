// Tokens belong in the platform keystore, not in a plain file.

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftviewer/services/auth_browser.dart';
import 'package:shiftviewer/services/secret_store.dart';
import 'package:shiftviewer/services/token_store.dart';

class _MemorySecrets implements SecretStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  test('tokens are written to and read back from the secret store', () async {
    final secrets = _MemorySecrets();
    final store = TokenStore(AuthBrowser(), secrets: secrets);

    await store.write({'refresh_token': 'r1', 'access_token': 'a1'});

    expect(secrets.values, hasLength(1));
    expect(secrets.values.values.single, contains('r1'));
    expect(await store.read(), {'refresh_token': 'r1', 'access_token': 'a1'});
  });

  test('clearing removes them from the secret store', () async {
    final secrets = _MemorySecrets();
    final store = TokenStore(AuthBrowser(), secrets: secrets);
    await store.write({'refresh_token': 'r1'});

    await store.clear();

    expect(secrets.values, isEmpty);
    expect(await store.read(), isEmpty);
  });
}
