import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/driver_earnings_repository.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

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
      final data = await DriverEarningsRepository.instance.fetch();
      if (!mounted) return;
      setState(() {
        _data = data;
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

  @override
  Widget build(BuildContext context) {
    final balance = (_data?['earnings_balance'] as num?)?.toDouble() ?? 0;
    final history = (_data?['history'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final payModel = _data?['pay_model'] as String? ?? '';
    final commission = _data?['commission_percent'];

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.driverEarnings),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: AppColors.error)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('رصيد الأرباح', style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 8),
                            Text(
                              CurrencyFormatter.format(balance),
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                            ),
                            if (payModel.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                commission != null ? '$payModel · عمولة $commission%' : payModel,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('سجل الأرباح', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 12),
                      if (history.isEmpty)
                        const Text('لا توجد أرباح مسجّلة بعد')
                      else
                        ...history.map((row) {
                          final amount = (row['amount'] as num?)?.toDouble() ?? 0;
                          return Card(
                            child: ListTile(
                              title: Text(row['order_code'] as String? ?? 'طلب'),
                              subtitle: Text(row['note'] as String? ?? row['created_at'] as String? ?? ''),
                              trailing: Text(
                                CurrencyFormatter.format(amount),
                                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}
