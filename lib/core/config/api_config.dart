import 'dart:io';

import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  /// Override: --dart-define=API_BASE_URL=http://...
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// سيرفر Hostinger (الإنتاج)
  static const String productionBaseUrl = 'http://72.60.32.52:8094/api';

  /// محلي — فقط عند التطوير على Windows مع XAMPP
  static const String localWindowsUrl = 'http://127.0.0.1/matchy_matchy/public/api';

  /// للتطوير على الهاتف عبر Wi‑Fi المحلي (اختياري):
  /// --dart-define=API_BASE_URL=http://192.168.1.110/matchy_matchy/public/api
  static const String lanHost = '192.168.1.110';
  static const String apacheApiPath = '/matchy_matchy/public/api';

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;

    // الافتراضي: السيرفر — حتى يعمل flutter run على الهاتف
    if (!kIsWeb && Platform.isWindows && !kReleaseMode) {
      return localWindowsUrl;
    }

    return productionBaseUrl;
  }

  static bool get isLocalDev =>
      baseUrl.contains('127.0.0.1') || baseUrl.contains('192.168.');

  static const connectTimeout = Duration(seconds: 25);
  static const receiveTimeout = Duration(seconds: 30);
}
