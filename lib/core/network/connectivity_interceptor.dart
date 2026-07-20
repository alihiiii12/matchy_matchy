import 'package:dio/dio.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/services/connectivity_service.dart';

/// يمنع طلبات API بدون إنترنت ويعرض تنبيه للمستخدم.
class ConnectivityInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!await ConnectivityService.instance.hasConnection()) {
      ConnectivityService.instance.showNoInternetAlert();
      options.extra[ConnectivityService.offlineAlertExtraKey] = true;
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: AppStrings.noInternetConnection,
        ),
      );
      return;
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_isLikelyOffline(err) && !await ConnectivityService.instance.hasConnection()) {
      if (err.requestOptions.extra[ConnectivityService.offlineAlertExtraKey] != true) {
        ConnectivityService.instance.showNoInternetAlert();
        err.requestOptions.extra[ConnectivityService.offlineAlertExtraKey] = true;
      }
    }
    handler.next(err);
  }

  bool _isLikelyOffline(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout;
  }
}

/// لا تعرض رسالة مكررة إذا التنبيه ظهر تلقائياً من [ConnectivityInterceptor].
bool wasOfflineAlertShown(DioException error) =>
    error.requestOptions.extra[ConnectivityService.offlineAlertExtraKey] == true;
