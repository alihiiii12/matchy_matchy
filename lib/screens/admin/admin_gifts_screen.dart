import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/admin_gifts_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/points_format.dart';

class AdminGiftsScreen extends GetView<AdminGiftsController> {
  const AdminGiftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.adminGiftRewards),
        actions: [
          IconButton(onPressed: controller.load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.openCreateForm,
        icon: const Icon(Icons.add),
        label: Text(AppStrings.addGiftReward),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null) {
          return Center(child: Text(controller.error.value!, style: TextStyle(color: AppColors.error)));
        }
        if (controller.gifts.isEmpty) {
          return Center(child: Text(AppStrings.noGiftRewardsYet));
        }

        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: controller.gifts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final gift = controller.gifts[i];
              return _GiftAdminCard(
                gift: gift,
                loading: controller.isActionLoading(gift['id'] as int),
                typeLabel: controller.rewardTypeLabel(gift['reward_type'] as String?),
                onEdit: () => controller.openEditForm(gift),
                onDelete: () => controller.deleteGift(gift),
              );
            },
          ),
        );
      }),
    );
  }
}

class _GiftAdminCard extends StatelessWidget {
  const _GiftAdminCard({
    required this.gift,
    required this.loading,
    required this.typeLabel,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> gift;
  final bool loading;
  final String typeLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title = gift['title'] as String? ?? '—';
    final cost = gift['points_cost'] as int? ?? 0;
    final summary = gift['reward_summary'] as String? ?? gift['description'] as String? ?? '';
    final isActive = gift['is_active'] as bool? ?? true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isActive ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? AppStrings.couponActive : AppStrings.couponInactive,
                    style: TextStyle(
                      color: isActive ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(typeLabel, style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 13)),
            if (summary.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(summary, style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
            ],
            const SizedBox(height: 8),
            Text(
              '${PointsFormat.display(cost)} ${AppStrings.pointsUnit}',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: loading ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(AppStrings.edit),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: loading ? null : onDelete,
                  icon: loading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.delete_outline, size: 18, color: AppColors.error),
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
