import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/main_shell_controller.dart';
import 'package:matchy_matchy/core/controllers/seller_dashboard_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';
import 'package:matchy_matchy/core/widgets/notification_badge_icon.dart';
import 'package:matchy_matchy/core/widgets/profile_avatar.dart';

class SellerDashboardScreen extends GetView<SellerDashboardController> {
  const SellerDashboardScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  SellerDashboardController get controller {
    final tag = 'seller_dashboard_$embedded';
    if (!Get.isRegistered<SellerDashboardController>(tag: tag)) {
      Get.put(SellerDashboardController(), tag: tag);
    }
    return Get.find<SellerDashboardController>(tag: tag);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          if (controller.loading.value && controller.totalUnitsSold.value == 0) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: controller.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                _Header(onRefresh: controller.load),
                if (controller.error.value != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    controller.error.value!,
                    style: TextStyle(color: AppColors.error, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(onPressed: controller.load, child: const Text('إعادة المحاولة')),
                  ),
                ],
                const SizedBox(height: 20),
                _MonthSummaryCard(
                  unitsSold: controller.monthUnitsSold.value,
                  revenue: controller.monthRevenue.value,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: AppStrings.sellerTotalUnitsSold,
                        value: '${controller.totalUnitsSold.value}',
                        icon: Icons.shopping_bag_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        label: AppStrings.sellerTotalRevenue,
                        value: CurrencyFormatter.format(controller.totalRevenue.value),
                        icon: Icons.payments_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(AppStrings.sellerProducts, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 12),
                _ProductsOverviewCard(
                  published: controller.publishedProducts.value,
                  pending: controller.pendingProducts.value,
                  onOpenProducts: _openProductsTab,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  void _openProductsTab() {
    // Seller role retired — single-vendor rozetaj store.
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Obx(() {
          final user = AuthService.instance.userRx.value;
          return ProfileAvatar(radius: 22, imageUrl: user?.avatarUrl);
        }),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() {
                final name = AuthService.instance.userRx.value?.name ?? '';
                return Text(
                  '${AppStrings.hi}، $name',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              }),
              Text(
                AppStrings.sellerDashboardSubtitle,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh)),
        const NotificationBadgeIcon(),
      ],
    );
  }
}

class _MonthSummaryCard extends StatelessWidget {
  const _MonthSummaryCard({required this.unitsSold, required this.revenue});

  final int unitsSold;
  final double revenue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.sellerMonthSalesTitle,
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            '${AppStrings.sellerMonthUnitsSold}: $unitsSold',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            '${AppStrings.sellerMonthRevenue}: ${CurrencyFormatter.format(revenue)}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent, size: 22),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3)),
        ],
      ),
    );
  }
}

class _ProductsOverviewCard extends StatelessWidget {
  const _ProductsOverviewCard({
    required this.published,
    required this.pending,
    required this.onOpenProducts,
  });

  final int published;
  final int pending;
  final VoidCallback onOpenProducts;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.12)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpenProducts,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: AppColors.accent, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.sellerManageProducts, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(
                      '${AppStrings.sellerPublishedProducts}: $published  •  ${AppStrings.sellerPendingProducts}: $pending',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
