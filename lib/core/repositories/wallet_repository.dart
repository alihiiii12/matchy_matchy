import 'package:matchy_matchy/core/network/api_client.dart';

class WalletRepository {
  WalletRepository._();
  static final instance = WalletRepository._();

  Future<double> fetchBalance({bool force = false}) async {
    final res = await ApiClient.instance.getJson('/wallet/balance', force: force);
    final data = res.data!['data'] as Map<String, dynamic>;
    return (data['wallet_balance'] as num?)?.toDouble() ?? 0;
  }

  Future<List<Map<String, dynamic>>> fetchHistory({bool force = false}) async {
    final res = await ApiClient.instance.getJson('/wallet/history', force: force);
    return (res.data!['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }
}
