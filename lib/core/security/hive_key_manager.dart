import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HiveKeyManager {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'hive_aes_key_v1';

  static Future<List<int>> getOrCreateKey() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null) {
      return base64Url.decode(existing);
    }

    final rand = Random.secure();
    final key = List<int>.generate(32, (_) => rand.nextInt(256)); // 256-bit
    await _storage.write(key: _keyName, value: base64UrlEncode(key));
    return key;
  }
}
