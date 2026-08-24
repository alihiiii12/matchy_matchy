import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Language selection + GetX locale updates (ar / en).
class LanguageController extends GetxController {
  static LanguageController get instance => Get.find<LanguageController>();

  static const _prefsKey = 'rozetaj_locale';
  static const options = ['ar', 'en'];

  final code = 'ar'.obs;

  bool get isEnglish => code.value == 'en';
  bool get isArabic => code.value == 'ar';
  Locale get locale => Locale(code.value);

  /// Display label for current language row.
  String get currentLabel => isEnglish ? 'English' : 'العربية';

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved == 'en' || saved == 'ar') {
        if (code.value == saved) return;
        code.value = saved!;
        Get.updateLocale(Locale(saved));
      }
    } catch (_) {}
  }

  Future<void> setLocaleCode(String next) async {
    if (next != 'ar' && next != 'en') return;
    if (code.value == next) return;
    code.value = next;
    Get.updateLocale(Locale(next));
    try {
      Get.forceAppUpdate();
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, next);
    } catch (_) {}
    update();
  }

  Future<void> toggle() => setLocaleCode(isEnglish ? 'ar' : 'en');
}

class LanguageBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LanguageController>()) {
      Get.put(LanguageController(), permanent: true);
    }
  }
}
