import 'package:matchy_matchy/core/network/api_client.dart';

class StoreSettingsRepository {
  StoreSettingsRepository._();
  static final instance = StoreSettingsRepository._();

  Future<Map<String, dynamic>> fetchPublic({bool force = false}) async {
    final res = await ApiClient.instance.getJson('/store-settings', force: force);
    return res.data!['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchAdmin({bool force = false}) async {
    final res = await ApiClient.instance.getJson('/admin/store-settings', force: force);
    return res.data!['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAdmin({
    required bool freeDeliveryEnabled,
    required double freeDeliveryMinOrder,
    String? freeDeliveryCouponCode,
  }) async {
    final res = await ApiClient.instance.patchJson(
      '/admin/store-settings',
      data: {
        'free_delivery_enabled': freeDeliveryEnabled,
        'free_delivery_min_order': freeDeliveryMinOrder,
        if (freeDeliveryCouponCode != null) 'free_delivery_coupon_code': freeDeliveryCouponCode,
      },
    );
    ApiClient.instance.invalidateGetCache('/store-settings');
    ApiClient.instance.invalidateGetCache('/admin/store-settings');
    return res.data!['data'] as Map<String, dynamic>;
  }
}
