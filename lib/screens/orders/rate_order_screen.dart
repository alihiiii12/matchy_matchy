import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/reviews_repository.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class RateOrderScreen extends StatefulWidget {
  const RateOrderScreen({super.key});

  @override
  State<RateOrderScreen> createState() => _RateOrderScreenState();
}

class _RateOrderScreenState extends State<RateOrderScreen> {
  late final int _orderId;
  late final List<String> _productIds;
  final _productRatings = <String, int>{};
  final _productComments = <String, TextEditingController>{};
  int _driverRating = 5;
  final _driverComment = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      _orderId = args['order_id'] as int? ?? 0;
      _productIds = (args['product_ids'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    } else if (args is int) {
      _orderId = args;
      _productIds = [];
    } else {
      _orderId = 0;
      _productIds = [];
    }
    for (final id in _productIds) {
      _productRatings[id] = 5;
      _productComments[id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _productComments.values) {
      c.dispose();
    }
    _driverComment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_orderId <= 0 || _submitting) return;
    setState(() => _submitting = true);
    try {
      for (final id in _productIds) {
        await ReviewsRepository.instance.rateProduct(
          orderId: _orderId,
          productId: id,
          rating: _productRatings[id] ?? 5,
          comment: _productComments[id]?.text.trim(),
        );
      }
      await ReviewsRepository.instance.rateDriver(
        orderId: _orderId,
        rating: _driverRating,
        comment: _driverComment.text.trim(),
      );
      if (!mounted) return;
      showAppSnackBar(context, message: 'شكراً لتقييمك', type: AppSnackBarType.success);
      Get.back(result: true);
    } on DioException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: apiFriendlyError(e), type: AppSnackBarType.error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _stars(int value, ValueChanged<int> onChanged) {
    return Row(
      children: List.generate(5, (i) {
        final star = i + 1;
        return IconButton(
          onPressed: () => onChanged(star),
          icon: Icon(star <= value ? Icons.star : Icons.star_border, color: Colors.amber),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.rateOrder)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_productIds.isEmpty)
            Text('رقم الطلب: $_orderId', style: TextStyle(color: AppColors.textSecondary))
          else
            ..._productIds.map((id) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${AppStrings.rateProduct}: $id', style: const TextStyle(fontWeight: FontWeight.w700)),
                      _stars(_productRatings[id] ?? 5, (v) => setState(() => _productRatings[id] = v)),
                      TextField(
                        controller: _productComments[id],
                        decoration: const InputDecoration(labelText: 'تعليق (اختياري)', border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.rateDriver, style: TextStyle(fontWeight: FontWeight.w700)),
                  _stars(_driverRating, (v) => setState(() => _driverRating = v)),
                  TextField(
                    controller: _driverComment,
                    decoration: const InputDecoration(labelText: 'تعليق (اختياري)', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: _submitting ? 'جاري الإرسال...' : AppStrings.save,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
