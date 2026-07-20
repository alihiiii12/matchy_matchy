import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  static const _storageKey = 'theme_mode';

  final themeMode = ThemeMode.light.obs;
  final _storage = const FlutterSecureStorage();

  Future<void> loadTheme() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      themeMode.value = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Theme secure storage read failed: $e');
      }
      try {
        await _storage.delete(key: _storageKey);
      } catch (_) {}
      themeMode.value = ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    try {
      await _storage.write(
        key: _storageKey,
        value: mode == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (_) {
      try {
        await _storage.delete(key: _storageKey);
        await _storage.write(
          key: _storageKey,
          value: mode == ThemeMode.dark ? 'dark' : 'light',
        );
      } catch (_) {}
    }
  }

  bool get isDarkMode => themeMode.value == ThemeMode.dark;
}

class ThemeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ThemeController());
  }
}
