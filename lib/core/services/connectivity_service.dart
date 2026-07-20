import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';

/// يتحقق من وجود اتصال شبكة ويعرض تنبيهاً موحّداً عند غياب الإنترنت.
class ConnectivityService {
  ConnectivityService._();

  static final instance = ConnectivityService._();

  static const offlineAlertExtraKey = 'offline_alert_shown';

  final Connectivity _connectivity = Connectivity();
  DateTime? _lastAlertAt;

  Future<bool> hasConnection() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// يعرض تنبيهاً إذا لا يوجد اتصال. يرجع false عند انقطاع الشبكة.
  Future<bool> ensureConnection({bool showAlert = true}) async {
    if (await hasConnection()) return true;
    if (showAlert) showNoInternetAlert();
    return false;
  }

  void showNoInternetAlert() {
    final now = DateTime.now();
    if (_lastAlertAt != null &&
        now.difference(_lastAlertAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastAlertAt = now;

    showMatchySnackBar(
      message: AppStrings.noInternetConnection,
      type: AppSnackBarType.error,
      duration: const Duration(seconds: 4),
    );
  }
}
