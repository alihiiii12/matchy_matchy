import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/wallet_repository.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _loading = true;
  String? _error;
  double _balance = 0;
  List<Map<String, dynamic>> _history = [];

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
      final balance = await WalletRepository.instance.fetchBalance(force: true);
      final history = await WalletRepository.instance.fetchHistory(force: true);
      if (!mounted) return;
      setState(() {
        _balance = balance;
        _history = history;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.myWallet),
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
                            Text(AppStrings.walletBalance, style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 8),
                            Text(
                              CurrencyFormatter.format(_balance),
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('سجل المحفظة', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 12),
                      if (_history.isEmpty)
                        const Text('لا توجد حركات بعد')
                      else
                        ..._history.map((tx) {
                          final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
                          return Card(
                            child: ListTile(
                              title: Text(tx['reason'] as String? ?? tx['type'] as String? ?? 'حركة'),
                              subtitle: Text(tx['created_at'] as String? ?? ''),
                              trailing: Text(
                                CurrencyFormatter.format(amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: amount >= 0 ? AppColors.success : AppColors.error,
                                ),
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
