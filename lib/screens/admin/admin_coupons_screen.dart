import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/admin_coupons_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class AdminCouponsScreen extends GetView<AdminCouponsController> {
  const AdminCouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.adminCoupons),
        actions: [
          IconButton(onPressed: controller.load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.openCreateForm,
        icon: const Icon(Icons.add),
        label: Text(AppStrings.addCoupon),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null) {
          return Center(child: Text(controller.error.value!, style: TextStyle(color: AppColors.error)));
        }
        if (controller.coupons.isEmpty) {
          return Center(child: Text(AppStrings.noCouponsYet));
        }

        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: controller.coupons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final coupon = controller.coupons[i];
              return _CouponAdminCard(
                coupon: coupon,
                loading: controller.isActionLoading(coupon['id'] as int),
                onEdit: () => controller.openEditForm(coupon),
                onDelete: () => controller.deleteCoupon(coupon),
              );
            },
          ),
        );
      }),
    );
  }
}

class _CouponAdminCard extends StatelessWidget {
  const _CouponAdminCard({
    required this.coupon,
    required this.loading,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> coupon;
  final bool loading;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final name = coupon['name'] as String? ?? '—';
    final value = coupon['value'] as num? ?? 0;
    final perUserLimit = coupon['per_user_limit'] as int? ?? 0;
    final totalUsages = coupon['total_usages'] as int? ?? 0;
    final isExpired = coupon['is_expired'] as bool? ?? false;
    final isValid = coupon['is_valid'] as bool? ?? false;
    final expiresAt = _formatDate(coupon['expires_at'] as String?);

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
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_offer_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        '$value%',
                        style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                _StatusChip(isValid: isValid, isExpired: isExpired),
              ],
            ),
            const SizedBox(height: 12),
            _InfoLine(AppStrings.couponPerUserLimit, '$perUserLimit ${AppStrings.times}'),
            _InfoLine(AppStrings.couponExpiryDate, expiresAt),
            _InfoLine(AppStrings.couponTotalUsages, '$totalUsages ${AppStrings.times}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: loading ? null : onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(AppStrings.edit),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: loading ? null : onDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(AppStrings.delete),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return '—';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isValid, required this.isExpired});

  final bool isValid;
  final bool isExpired;

  @override
  Widget build(BuildContext context) {
    final label = isValid ? AppStrings.couponActive : (isExpired ? AppStrings.couponExpired : AppStrings.couponInactive);
    final color = isValid ? AppColors.success : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
