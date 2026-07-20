import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/driver_subscriptions_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class DriverSubscriptionsScreen extends GetView<DriverSubscriptionsController> {
  const DriverSubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.driverSubscriptions),
        actions: [
          IconButton(onPressed: controller.load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value != null) {
          return Center(child: Text(controller.error.value!, style: TextStyle(color: AppColors.error)));
        }

        final account = controller.accountSubscription.value;
        if (account == null) {
          return Center(child: Text(AppStrings.noDriverSubscriptionsYet));
        }

        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                AppStrings.driverAccountSubscription,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              _SubscriptionCard(
                subscription: account,
                statusLabel: controller.statusLabel(account),
                statusColor: controller.statusColor(account),
                startDate: controller.formatDate(account['starts_at'] as String?),
                endDate: controller.formatDate(account['expires_at'] as String?),
                amount: controller.formatAmount(account['amount_paid'] as num?),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.subscription,
    required this.statusLabel,
    required this.statusColor,
    required this.startDate,
    required this.endDate,
    required this.amount,
  });

  final Map<String, dynamic> subscription;
  final String statusLabel;
  final Color statusColor;
  final String startDate;
  final String endDate;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final title = subscription['title'] as String? ?? '—';
    final fleet = subscription['fleet_name'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_shipping_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      if (fleet != null && fleet.isNotEmpty)
                        Text(fleet, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InfoRow(AppStrings.freeDeliverySubscriptionStartDate, startDate),
            _InfoRow(AppStrings.freeDeliverySubscriptionEndDate, endDate),
            _InfoRow(AppStrings.freeDeliverySubscriptionAmount, amount),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}
