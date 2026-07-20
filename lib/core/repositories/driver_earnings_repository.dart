import 'package:matchy_matchy/core/network/api_client.dart';

class DriverEarningsRepository {
  DriverEarningsRepository._();
  static final instance = DriverEarningsRepository._();

  Future<Map<String, dynamic>> fetch() async {
    final res = await ApiClient.instance.getJson('/driver/earnings', force: true);
    return res.data!['data'] as Map<String, dynamic>;
  }
}
