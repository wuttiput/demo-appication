import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageHelper {
  static final SecureStorageHelper instance = SecureStorageHelper._init();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  SecureStorageHelper._init();

  // Keys Constants
  static const String geminiKey = 'GEMINI_API_KEY';
  static const String deepseekKey = 'DEEPSEEK_API_KEY';
  static const String openrouterKey = 'OPENROUTER_API_KEY';

  // Save Key
  Future<void> saveApiKey(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // Read Key
  Future<String?> readApiKey(String key) async {
    return await _storage.read(key: key);
  }

  // Delete Key
  Future<void> deleteApiKey(String key) async {
    await _storage.delete(key: key);
  }

  // Read all keys
  Future<Map<String, String>> readAllKeys() async {
    return await _storage.readAll();
  }

  // Clear all
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
