import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/security/secure_storage_helper.dart';

class KeysState {
  final String gemini;
  final String deepseek;
  final String openrouter;
  final bool isLoading;

  KeysState({
    this.gemini = '',
    this.deepseek = '',
    this.openrouter = '',
    this.isLoading = true,
  });

  KeysState copyWith({
    String? gemini,
    String? deepseek,
    String? openrouter,
    bool? isLoading,
  }) {
    return KeysState(
      gemini: gemini ?? this.gemini,
      deepseek: deepseek ?? this.deepseek,
      openrouter: openrouter ?? this.openrouter,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class KeysNotifier extends StateNotifier<KeysState> {
  KeysNotifier() : super(KeysState()) {
    loadKeys();
  }

  Future<void> loadKeys() async {
    state = state.copyWith(isLoading: true);
    final keys = await SecureStorageHelper.instance.readAllKeys();
    state = KeysState(
      gemini: keys[SecureStorageHelper.geminiKey] ?? '',
      deepseek: keys[SecureStorageHelper.deepseekKey] ?? '',
      openrouter: keys[SecureStorageHelper.openrouterKey] ?? '',
      isLoading: false,
    );
  }

  Future<void> saveKey(String keyType, String value) async {
    if (keyType == SecureStorageHelper.geminiKey) {
      await SecureStorageHelper.instance.saveApiKey(SecureStorageHelper.geminiKey, value);
      state = state.copyWith(gemini: value);
    } else if (keyType == SecureStorageHelper.deepseekKey) {
      await SecureStorageHelper.instance.saveApiKey(SecureStorageHelper.deepseekKey, value);
      state = state.copyWith(deepseek: value);
    } else if (keyType == SecureStorageHelper.openrouterKey) {
      await SecureStorageHelper.instance.saveApiKey(SecureStorageHelper.openrouterKey, value);
      state = state.copyWith(openrouter: value);
    }
  }

  Future<void> clearAll() async {
    await SecureStorageHelper.instance.clearAll();
    state = KeysState(isLoading: false);
  }
}

final keysProvider = StateNotifierProvider<KeysNotifier, KeysState>((ref) {
  return KeysNotifier();
});
