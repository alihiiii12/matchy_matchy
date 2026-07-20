import 'package:dio/dio.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/network/connectivity_interceptor.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';

/// يعرض خطأ API للمستخدم دون تكرار تنبيه انقطاع الإنترنت.
void showApiErrorSnackBar(
  DioException error, {
  String fallback = 'تعذر الاتصال بالخادم',
}) {
  if (wasOfflineAlertShown(error)) return;

  showMatchySnackBar(
    message: apiFriendlyError(error, fallback: fallback),
    type: AppSnackBarType.error,
  );
}
