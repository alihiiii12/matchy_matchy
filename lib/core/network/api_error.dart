import 'package:dio/dio.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/connectivity_interceptor.dart';

bool isSellerPasswordResetDenied(DioException error) {
  if (error.response?.statusCode != 403) return false;

  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    final message = data['message'];
    if (message is String && message.contains('مراجعة الإدارة')) {
      return true;
    }
  }

  return false;
}

String sellerPasswordResetDeniedMessage(DioException error) {
  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    final message = data['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }
  }

  return AppStrings.sellerPasswordResetDenied;
}

String apiFriendlyError(DioException error, {String fallback = 'تعذر الاتصال بالخادم'}) {
  if (error.message == AppStrings.noInternetConnection ||
      (wasOfflineAlertShown(error) &&
          (error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout))) {
    return AppStrings.noInternetConnection;
  }

  final status = error.response?.statusCode;
  final data = error.response?.data;

  if (status == 429) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty && !_isEnglishThrottleMessage(message)) {
        return message;
      }
    }
    return 'محاولات كثيرة. انتظر دقيقة ثم أعد المحاولة.';
  }

  if (data is Map<String, dynamic>) {
    final errors = data['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          final msg = value.first.toString();
          if (msg.toLowerCase().contains('failed to upload') ||
              msg.toLowerCase().contains('upload')) {
            return 'فشل رفع الصورة. جرّب صورة JPG/PNG أصغر من 5 ميجابايت.';
          }
          if (msg.toLowerCase().contains('seller governorate')) {
            return 'المحافظة غير متوفرة على السيرفر. تواصل مع الإدارة لتشغيل migrate.';
          }
          if (msg.contains('المدينة') || msg.contains('المنطقة') || msg.contains('موقع التوصيل')) {
            return msg;
          }
          return msg;
        }
      }
    }

    final message = data['message'];
    if (message is String &&
        message.isNotEmpty &&
        message != 'The given data was invalid.') {
      if (_isEnglishThrottleMessage(message)) {
        return 'محاولات كثيرة. انتظر دقيقة ثم أعد المحاولة.';
      }
      if (message == 'Server Error') {
        return 'خطأ في السيرفر: نفّذ migrate على السيرفر (php artisan migrate --force) أو ارفع آخر ملفات الباك.';
      }
      if (message.contains('انتهت صلاحية الكوبون') || message.contains('الكوبون غير صالح')) {
        return AppStrings.couponInvalidExpired;
      }
      if (message.contains('استنفدت مرات استخدام') || message.contains('استهلكت عدد مرات')) {
        return AppStrings.couponUsageLimitExceeded;
      }
      return message;
    }
  }

  if (status != null && status >= 500) {
    return 'خطأ في السيرفر ($status). جرّب لاحقاً أو راجع إعدادات السيرفر.';
  }

  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.connectionError) {
    if (error.message == AppStrings.noInternetConnection || wasOfflineAlertShown(error)) {
      return AppStrings.noInternetConnection;
    }
    // رسالة أوضح أثناء التطوير المحلي
    try {
      // ignore: avoid_dynamic_calls
      final base = error.requestOptions.baseUrl;
      if (base.contains('127.0.0.1') ||
          base.contains('192.168.') ||
          base.contains('10.0.2.2')) {
        return 'تعذر الاتصال بالخادم المحلي ($base). '
            'تأكد أن php artisan serve --host=0.0.0.0 يعمل، والجوال على نفس الواي فاي.';
      }
    } catch (_) {}
    return 'تعذر الاتصال بالخادم. تحقق من الإنترنت أو جرّب لاحقاً.';
  }

  if (error.type == DioExceptionType.badResponse) {
    if (status == 404) {
      return 'الميزة غير متوفرة على السيرفر. ارفع آخر ملفات الباك وشغّل: php artisan migrate --force';
    }
    return 'استجابة غير متوقعة من السيرفر. تأكد من رفع مشروع matchy_matchy كاملاً وتشغيل migrate.';
  }

  return fallback;
}

bool _isEnglishThrottleMessage(String message) {
  final lower = message.toLowerCase();
  return lower.contains('too many attempts') || lower.contains('too many requests');
}

