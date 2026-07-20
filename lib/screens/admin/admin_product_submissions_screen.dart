import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/admin_product_submissions_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/catalog_image.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class AdminProductSubmissionsScreen extends GetView<AdminProductSubmissionsController> {
  const AdminProductSubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.adminProductApprovals),
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
        if (controller.submissions.isEmpty) {
          return Center(child: Text(AppStrings.noPendingProducts));
        }

        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.submissions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final submission = controller.submissions[i];
              return _SubmissionCard(
                submission: submission,
                loading: controller.isActionLoading(submission['id'] as int),
                actionLabel: controller.actionLabel(submission['action'] as String?),
                approveLabel: controller.approveButtonLabel(submission['action'] as String?),
                priceText: controller.formatPrice(submission['price']),
                onApprove: () => controller.approve(submission),
                onReject: () => controller.reject(submission),
              );
            },
          ),
        );
      }),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({
    required this.submission,
    required this.loading,
    required this.actionLabel,
    required this.approveLabel,
    required this.priceText,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> submission;
  final bool loading;
  final String actionLabel;
  final String approveLabel;
  final String priceText;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final seller = submission['seller'] as Map<String, dynamic>?;
    final currentProduct = submission['current_product'] as Map<String, dynamic>?;
    final action = submission['action'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(actionLabel, style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    submission['status_label'] as String? ?? AppStrings.pendingReview,
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (seller != null) ...[
              _InfoRow(AppStrings.sellerNameLabel, seller['name'] as String? ?? '—'),
              _InfoRow(AppStrings.email, seller['email'] as String? ?? '—'),
              _InfoRow(AppStrings.sellerBrandName, seller['brand_name'] as String? ?? '—'),
            ],
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CatalogImage(
                  imageUrl: submission['image_url'] as String?,
                  fallbackIcon: Icons.inventory_2_outlined,
                  width: 88,
                  height: 88,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(submission['name'] as String? ?? '—', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 4),
                      _InfoRow(AppStrings.sellerBrandName, submission['brand'] as String? ?? '—'),
                      _InfoRow(AppStrings.productPrice, priceText),
                      _InfoRow(AppStrings.category, submission['category_name'] as String? ?? '—'),
                      _InfoRow(AppStrings.subCategory, submission['sub_category_name'] as String? ?? '—'),
                      _InfoRow(AppStrings.governorate, submission['seller_governorate_name'] as String? ?? '—'),
                      if (submission['unit'] != null && (submission['unit'] as String).isNotEmpty)
                        _InfoRow(AppStrings.productUnit, submission['unit'] as String),
                    ],
                  ),
                ),
              ],
            ),
            if (currentProduct != null && action == 'update') ...[
              const SizedBox(height: 12),
              Text(AppStrings.currentProduct, style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                '${currentProduct['name']} — ${currentProduct['brand']} — ${currentProduct['price']}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            GradientButton(
              label: loading ? AppStrings.saving : approveLabel,
              height: 44,
              onPressed: loading ? null : onApprove,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: loading ? null : onReject,
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: BorderSide(color: AppColors.error)),
                child: Text(AppStrings.rejectProduct),
              ),
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
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
          children: [
            TextSpan(text: '$label: ', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
