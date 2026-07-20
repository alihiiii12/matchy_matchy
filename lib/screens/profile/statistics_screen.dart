import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/statistics_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';

class StatisticsScreen extends GetView<StatisticsController> {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.statistics)),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(controller.error.value!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.error)),
                  const SizedBox(height: 16),
                  OutlinedButton(onPressed: controller.load, child: const Text('إعادة المحاولة')),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.load,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _StatCard(
                  label: AppStrings.totalOrders,
                  value: '${controller.totalOrders.value}',
                  icon: Icons.shopping_bag,
                ),
                _StatCard(
                  label: AppStrings.totalSpent,
                  value: CurrencyFormatter.format(controller.totalSpent.value),
                  icon: Icons.attach_money,
                ),
                _StatCard(
                  label: AppStrings.favoritesCount,
                  value: '${controller.favoritesCount}',
                  icon: Icons.favorite,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white70),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
        ],
      ),
    );
  }
}
