import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/admin_free_delivery_subscriptions_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class AdminFreeDeliverySubscriptionsScreen extends GetView<AdminFreeDeliverySubscriptionsController> {
  const AdminFreeDeliverySubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.adminFreeDeliverySubscriptions),
        actions: [
          IconButton(onPressed: controller.load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.openCreateForm,
        icon: const Icon(Icons.add),
        label: Text(AppStrings.addFreeDeliverySubscription),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null) {
          return Center(child: Text(controller.error.value!, style: TextStyle(color: AppColors.error)));
        }
        if (controller.subscriptions.isEmpty) {
          return Center(child: Text(AppStrings.noFreeDeliverySubscriptionsYet));
        }

        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: controller.subscriptions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final subscription = controller.subscriptions[i];
              return _SubscriptionCard(
                subscription: subscription,
                loading: controller.isActionLoading(subscription['id'] as int),
                statusLabel: controller.statusLabel(subscription),
                statusColor: controller.statusColor(subscription),
                startDate: controller.formatDate(subscription['starts_at'] as String?),
                endDate: controller.formatDate(subscription['expires_at'] as String?),
                amount: controller.formatAmount(subscription['amount_paid'] as num?),
                onEdit: () => controller.openEditForm(subscription),
                onDelete: () => controller.deleteSubscription(subscription),
              );
            },
          ),
        );
      }),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.subscription,
    required this.loading,
    required this.statusLabel,
    required this.statusColor,
    required this.startDate,
    required this.endDate,
    required this.amount,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> subscription;
  final bool loading;
  final String statusLabel;
  final Color statusColor;
  final String startDate;
  final String endDate;
  final String amount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final brand = subscription['brand_name'] as String? ?? '—';
    final sellerName = subscription['seller_name'] as String?;

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
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_shipping_outlined, color: AppColors.success),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(brand, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      if (sellerName != null && sellerName.isNotEmpty)
                        Text(sellerName, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(onPressed: loading ? null : onEdit, icon: const Icon(Icons.edit_outlined), label: Text(AppStrings.edit)),
                const Spacer(),
                TextButton.icon(
                  onPressed: loading ? null : onDelete,
                  icon: Icon(Icons.delete_outline, color: AppColors.error),
                  label: Text(AppStrings.delete, style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
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
