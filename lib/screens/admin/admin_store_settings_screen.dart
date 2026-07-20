import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/store_settings_repository.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class AdminStoreSettingsScreen extends StatefulWidget {
  const AdminStoreSettingsScreen({super.key});

  @override
  State<AdminStoreSettingsScreen> createState() => _AdminStoreSettingsScreenState();
}

class _AdminStoreSettingsScreenState extends State<AdminStoreSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _freeDelivery = false;
  final _minOrder = TextEditingController();
  final _couponCode = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _minOrder.dispose();
    _couponCode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await StoreSettingsRepository.instance.fetchAdmin(force: true);
      if (!mounted) return;
      setState(() {
        _freeDelivery = data['free_delivery_enabled'] == true || data['free_delivery_enabled'] == 1 || data['free_delivery_enabled'] == '1';
        _minOrder.text = '${(data['free_delivery_min_order'] as num?)?.toDouble() ?? 0}';
        _couponCode.text = data['free_delivery_coupon_code'] as String? ?? '';
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

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await StoreSettingsRepository.instance.updateAdmin(
        freeDeliveryEnabled: _freeDelivery,
        freeDeliveryMinOrder: double.tryParse(_minOrder.text.trim()) ?? 0,
        freeDeliveryCouponCode: _couponCode.text.trim(),
      );
      if (!mounted) return;
      showAppSnackBar(context, message: 'تم حفظ إعدادات المتجر', type: AppSnackBarType.success);
    } on DioException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: apiFriendlyError(e), type: AppSnackBarType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.adminStoreSettings)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: AppColors.error)))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    SwitchListTile(
                      title: Text(AppStrings.freeDeliveryStoreWide),
                      subtitle: const Text('عند التفعيل: مجاني للجميع، أو عند بلوغ الحد الأدنى إن وُجد'),
                      value: _freeDelivery,
                      onChanged: (v) => setState(() => _freeDelivery = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _minOrder,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: AppStrings.freeDeliveryMinOrder,
                        hintText: '0 = بدون حد أدنى',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _couponCode,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'كود كوبون التوصيل المجاني',
                        hintText: 'مثال: FREEDEL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      label: _saving ? 'جاري الحفظ...' : AppStrings.save,
                      onPressed: _saving ? null : _save,
                    ),
                  ],
                ),
    );
  }
}
