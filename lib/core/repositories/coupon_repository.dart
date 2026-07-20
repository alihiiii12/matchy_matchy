import 'package:matchy_matchy/core/network/api_client.dart';

class CouponRepository {
  CouponRepository._();
  static final instance = CouponRepository._();

  Future<Map<String, dynamic>> validate({required String name, required double subtotal}) async {
    final res = await ApiClient.instance.postJson(
      '/coupons/validate',
      data: {
        'name': name.trim(),
        'subtotal': subtotal,
      },
    );
    return res.data!['data'] as Map<String, dynamic>;
  }
}
