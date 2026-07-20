import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/custom_outfit_repository.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';

class AdminCustomOutfitsScreen extends StatefulWidget {
  const AdminCustomOutfitsScreen({super.key});

  @override
  State<AdminCustomOutfitsScreen> createState() => _AdminCustomOutfitsScreenState();
}

class _AdminCustomOutfitsScreenState extends State<AdminCustomOutfitsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  int? _actionId;

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
      final list = await CustomOutfitRepository.instance.adminFetch();
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

  Future<void> _setPrice(Map<String, dynamic> item) async {
    final priceCtrl = TextEditingController(
      text: item['quoted_price'] != null ? '${item['quoted_price']}' : '',
    );
    final notesCtrl = TextEditingController(text: item['admin_notes'] as String? ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تحديد السعر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'السعر المقترح'),
            ),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'ملاحظات الإدارة'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppStrings.save)),
        ],
      ),
    );
    if (ok != true) return;
    final price = double.tryParse(priceCtrl.text.trim());
    if (price == null) return;

    final id = item['id'] as int;
    setState(() => _actionId = id);
    try {
      await CustomOutfitRepository.instance.adminSetPrice(
        id: id,
        quotedPrice: price,
        adminNotes: notesCtrl.text.trim(),
      );
      if (!mounted) return;
      showAppSnackBar(context, message: 'تم تحديد السعر', type: AppSnackBarType.success);
      await _load();
    } on DioException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: apiFriendlyError(e), type: AppSnackBarType.error);
    } finally {
      if (mounted) setState(() => _actionId = null);
    }
  }

  Future<void> _reject(Map<String, dynamic> item) async {
    final id = item['id'] as int;
    setState(() => _actionId = id);
    try {
      await CustomOutfitRepository.instance.adminReject(id: id);
      if (!mounted) return;
      showAppSnackBar(context, message: 'تم الرفض', type: AppSnackBarType.success);
      await _load();
    } on DioException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: apiFriendlyError(e), type: AppSnackBarType.error);
    } finally {
      if (mounted) setState(() => _actionId = null);
    }
  }

  Future<void> _convert(Map<String, dynamic> item) async {
    final id = item['id'] as int;
    setState(() => _actionId = id);
    try {
      await CustomOutfitRepository.instance.adminConvertToOrder(id);
      if (!mounted) return;
      showAppSnackBar(context, message: 'تم التحويل لطلب شراء', type: AppSnackBarType.success);
      await _load();
    } on DioException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: apiFriendlyError(e), type: AppSnackBarType.error);
    } finally {
      if (mounted) setState(() => _actionId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.adminCustomOutfits),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: AppColors.error)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      final id = item['id'] as int;
                      final busy = _actionId == id;
                      final user = item['user'] as Map<String, dynamic>?;
                      final status = item['status'] as String? ?? '';
                      final quoted = (item['quoted_price'] as num?)?.toDouble();
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user?['name'] as String? ?? 'زبون', style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(item['status_label'] as String? ?? status, style: TextStyle(color: AppColors.accent)),
                              const SizedBox(height: 8),
                              Text(item['fabric_description'] as String? ?? ''),
                              Text(item['sizes_description'] as String? ?? '', style: TextStyle(color: AppColors.textSecondary)),
                              if (quoted != null)
                                Text(
                                  CurrencyFormatter.format(quoted),
                                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                                ),
                              const SizedBox(height: 12),
                              if (busy)
                                const LinearProgressIndicator()
                              else
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    if (status == 'pending' || status == 'awaiting_payment')
                                      OutlinedButton(onPressed: () => _setPrice(item), child: const Text('تسعير')),
                                    if (status != 'converted' && status != 'rejected')
                                      OutlinedButton(
                                        onPressed: () => _reject(item),
                                        child: Text(AppStrings.reject, style: TextStyle(color: AppColors.error)),
                                      ),
                                    if (status == 'awaiting_payment')
                                      FilledButton(onPressed: () => _convert(item), child: const Text('تحويل لطلب')),
                                  ],
                                ),
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
