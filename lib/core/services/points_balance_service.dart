import 'package:get/get.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';

/// Single source of truth for points balance — prevents duplicate API calls.
abstract final class PointsBalanceService {
  static final balance = 0.obs;
  static DateTime? _fetchedAt;
  static Future<int>? _inFlight;
  static const _staleAfter = Duration(seconds: 20);

  static Future<int> resolve({bool force = false}) async {
    if (!AuthService.instance.isLoggedIn) {
      balance.value = 0;
      return 0;
    }

    if (!force &&
        _fetchedAt != null &&
        DateTime.now().difference(_fetchedAt!) < _staleAfter) {
      return balance.value;
    }

    if (_inFlight != null) {
      return _inFlight!;
    }

    final task = _fetch(force: force);
    _inFlight = task;
    try {
      return await task;
    } finally {
      _inFlight = null;
    }
  }

  static Future<int> _fetch({required bool force}) async {
    try {
      final res = await ApiClient.instance.getJson('/points/balance', force: force);
      final value = (res.data!['data'] as Map<String, dynamic>)['points_balance'] as int? ?? 0;
      _apply(value);
      return value;
    } catch (_) {
      return balance.value;
    }
  }

  static void apply(int value) => _apply(value);

  static void _apply(int value) {
    balance.value = value;
    _fetchedAt = DateTime.now();
    AuthService.instance.updatePointsBalance(value);
  }

  static void reset() {
    balance.value = 0;
    _fetchedAt = null;
    _inFlight = null;
  }
}
