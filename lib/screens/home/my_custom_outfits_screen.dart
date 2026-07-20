import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/custom_outfit_repository.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class MyCustomOutfitsScreen extends StatefulWidget {
  const MyCustomOutfitsScreen({super.key});

  @override
  State<MyCustomOutfitsScreen> createState() => _MyCustomOutfitsScreenState();
}

class _MyCustomOutfitsScreenState extends State<MyCustomOutfitsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await CustomOutfitRepository.instance.fetchMine();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiFriendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _pay(Map<String, dynamic> item, String method) async {
    final id = item['id'] as int?;
    if (id == null) return;
    try {
      final res = await CustomOutfitRepository.instance.pay(
        id: id,
        paymentMethod: method,
      );
      if (!mounted) return;
      final orderId = res['data']?['order_id'];
      showAppSnackBar(
        context,
        message: method == 'cash_on_delivery'
            ? 'تم إنشاء الطلب بالدفع عند الاستلام'
            : 'تم إنشاء الطلب — راجع طلباتي لإرسال إثبات شام كاش إن لزم',
        type: AppSnackBarType.success,
      );
      await _load();
      if (orderId != null) {
        Get.toNamed(AppRoutes.myOrders);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: apiFriendlyError(e), type: AppSnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.myCustomOutfits),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.describeOutfit),
        icon: const Icon(Icons.add),
        label: Text(AppStrings.describeYourOutfit),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: AppColors.error)))
              : _items.isEmpty
                  ? const Center(child: Text('لا توجد طلبات مخصصة بعد'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final item = _items[i];
                          final status = item['status'] as String? ?? '';
                          final quoted = (item['quoted_price'] as num?)?.toDouble();
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['status_label'] as String? ?? status,
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(item['fabric_description'] as String? ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['sizes_description'] as String? ?? '',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (quoted != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'السعر المقترح: ${CurrencyFormatter.format(quoted)}',
                                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                                    ),
                                  ],
                                  if (status == 'awaiting_payment') ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: FilledButton(
                                            onPressed: () => _pay(item, 'cash_on_delivery'),
                                            child: const Text('دفع عند الاستلام'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () => _pay(item, 'sham_cash'),
                                            child: const Text('شام كاش'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (status == 'converted' && item['order_id'] != null) ...[
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () => Get.toNamed(AppRoutes.myOrders),
                                      child: const Text('عرض طلباتي'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
