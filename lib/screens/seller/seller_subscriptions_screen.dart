import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/seller_subscriptions_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class SellerSubscriptionsScreen extends GetView<SellerSubscriptionsController> {
  const SellerSubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.sellerSubscriptions),
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
        final others = controller.otherSubscriptions;

        if (account == null && others.isEmpty) {
          return Center(child: Text(AppStrings.noSellerSubscriptionsYet));
        }

        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (account != null) ...[
                Text(
                  AppStrings.sellerAccountSubscription,
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
                  icon: Icons.storefront_outlined,
                  iconColor: AppColors.primary,
                ),
              ],
              if (others.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  AppStrings.sellerOtherSubscriptions,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                ...others.map(
                  (subscription) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SubscriptionCard(
                      subscription: subscription,
                      statusLabel: controller.statusLabel(subscription),
                      statusColor: controller.statusColor(subscription),
                      startDate: controller.formatDate(subscription['starts_at'] as String?),
                      endDate: controller.formatDate(subscription['expires_at'] as String?),
                      amount: controller.formatAmount(subscription['amount_paid'] as num?),
                      icon: Icons.local_shipping_outlined,
                      iconColor: AppColors.success,
                    ),
                  ),
                ),
              ],
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
    required this.icon,
    required this.iconColor,
  });

  final Map<String, dynamic> subscription;
  final String statusLabel;
  final Color statusColor;
  final String startDate;
  final String endDate;
  final String amount;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final title = subscription['title'] as String? ?? '—';
    final brand = subscription['brand_name'] as String?;

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
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      if (brand != null && brand.isNotEmpty)
                        Text(brand, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
