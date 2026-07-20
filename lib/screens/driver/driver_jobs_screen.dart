import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/driver_jobs_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/driver_job_pricing.dart';
import 'package:matchy_matchy/core/widgets/driver_job_products.dart';
import 'package:matchy_matchy/core/widgets/driver_manual_invoice_card.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';
import 'package:matchy_matchy/core/widgets/notification_badge_icon.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class DriverJobsScreen extends GetView<DriverJobsController> {
  const DriverJobsScreen({super.key, this.embedded = false});

  final bool embedded;

  static const embeddedTag = 'driver_jobs_embedded';

  @override
  DriverJobsController get controller {
    if (embedded) {
      if (!Get.isRegistered<DriverJobsController>(tag: embeddedTag)) {
        Get.put(DriverJobsController(), tag: embeddedTag);
      }
      return Get.find<DriverJobsController>(tag: embeddedTag);
    }
    if (!Get.isRegistered<DriverJobsController>()) {
      Get.put(DriverJobsController());
    }
    return Get.find<DriverJobsController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: embedded
          ? null
          : AppBar(
              title: Text(AppStrings.driverJobsTitle),
              actions: [
                Obx(() {
                  if (controller.archiving.value) {
                    return const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }
                  return IconButton(
                    tooltip: AppStrings.archiveDriverJobs,
                    onPressed: controller.archiveJobs,
                    icon: const Icon(Icons.archive_outlined),
                  );
                }),
                const NotificationBadgeIcon(),
                IconButton(onPressed: controller.load, icon: const Icon(Icons.refresh)),
              ],
              bottom: TabBar(
                controller: controller.tabController,
                tabs: [
                  Tab(text: AppStrings.driverJobsActive),
                  Tab(text: AppStrings.driverJobsRejected),
                  Tab(text: AppStrings.driverJobsCompleted),
                ],
              ),
            ),
      body: SafeArea(
        child: Column(
          children: [
            if (embedded)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppStrings.driverJobsTitle,
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Obx(() {
                          if (controller.archiving.value) {
                            return const Padding(
                              padding: EdgeInsets.all(8),
                              child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          }
                          return IconButton(
                            tooltip: AppStrings.archiveDriverJobs,
                            onPressed: controller.archiveJobs,
                            icon: const Icon(Icons.archive_outlined),
                          );
                        }),
                        const NotificationBadgeIcon(),
                        IconButton(onPressed: controller.load, icon: const Icon(Icons.refresh)),
                      ],
                    ),
                    TabBar(
                      controller: controller.tabController,
                      tabs: [
                        Tab(text: AppStrings.driverJobsActive),
                        Tab(text: AppStrings.driverJobsRejected),
                        Tab(text: AppStrings.driverJobsCompleted),
                      ],
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Obx(() {
                final _ = controller.selectedTab.value;
                if (controller.loading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.error.value != null) {
                  return Center(child: Text(controller.error.value!, style: TextStyle(color: AppColors.error)));
                }

                final jobs = controller.currentJobs;
                if (jobs.isEmpty) {
                  return Center(child: Text(controller.emptyMessage));
                }

                return RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: jobs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _JobCard(job: jobs[i], controller: controller),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.controller});

  final Map<String, dynamic> job;
  final DriverJobsController controller;

  bool _flag(String key) {
    final v = job[key];
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase().trim();
      return s == '1' || s == 'true' || s == 'yes';
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final loading = controller.isActionLoading(job['id']?.toString() ?? '');
    final canAccept = _flag('can_accept');
    final canReject = _flag('can_reject') || canAccept;
    final canStartTransit = _flag('can_start_transit');
    final canConfirmPayment = _flag('can_confirm_payment');
    final canMarkDelivered = _flag('can_mark_delivered');
    final statusLabel = job['status_label'] as String? ?? '';
    final rejectionReason = job['rejection_reason'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job['order_code'] as String? ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabel, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(job['address'] as String? ?? '', style: TextStyle(color: AppColors.textSecondary)),
            if (DriverManualInvoiceCard.isManualJob(job)) ...[
              const SizedBox(height: 8),
              DriverManualInvoiceCard(content: DriverManualInvoiceCard.contentOf(job) ?? '', compact: true),
            ],
            const SizedBox(height: 8),
            DriverJobPricing(
              job: job,
              compact: true,
              onTap: () => Get.toNamed(AppRoutes.driverJobDetail, arguments: job['id']),
            ),
            const SizedBox(height: 8),
            DriverJobProducts(job: job, compact: true),
            if (job['estimated_time'] != null) ...[
              const SizedBox(height: 6),
              Text('${AppStrings.expectedDelivery}: ${job['estimated_time']}'),
            ],
            if (rejectionReason != null && rejectionReason.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${AppStrings.rejectDeliveryJobReason}: $rejectionReason',
                style: TextStyle(color: AppColors.error, fontSize: 13, height: 1.4),
              ),
            ],
            const SizedBox(height: 12),
            if (canAccept) ...[
              GradientButton(
                label: loading ? AppStrings.confirmingArrival : AppStrings.acceptDeliveryJob,
                height: 44,
                onPressed: loading ? null : () => controller.acceptJob(job),
              ),
              if (canReject) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: loading ? null : () => controller.rejectJob(job),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                  ),
                  child: Text(AppStrings.rejectDeliveryJob),
                ),
              ],
            ] else if (canStartTransit) ...[
              GradientButton(
                label: loading ? AppStrings.confirmingArrival : AppStrings.startDeliveryTrip,
                height: 44,
                onPressed: loading ? null : () => controller.startTransit(job),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.driverJobDetail, arguments: job['id']),
                icon: const Icon(Icons.info_outline),
                label: Text(AppStrings.viewDeliveryJob),
              ),
            ] else if (canConfirmPayment || canMarkDelivered) ...[
              if (canConfirmPayment)
                GradientButton(
                  label: loading ? AppStrings.confirmingArrival : 'تأكيد قبض المبلغ',
                  height: 44,
                  onPressed: loading ? null : () => controller.confirmPaymentCollected(job),
                ),
              if (canMarkDelivered) ...[
                if (canConfirmPayment) const SizedBox(height: 8),
                GradientButton(
                  label: loading ? AppStrings.confirmingArrival : AppStrings.driverMarkDelivered,
                  height: 44,
                  onPressed: loading ? null : () => controller.markDelivered(job),
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.driverJobDetail, arguments: job['id']),
                icon: const Icon(Icons.info_outline),
                label: Text(AppStrings.viewDeliveryJob),
              ),
            ] else
              OutlinedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.driverJobDetail, arguments: job['id']),
                icon: const Icon(Icons.info_outline),
                label: Text(AppStrings.viewDeliveryJob),
              ),
          ],
        ),
      ),
    );
  }
}
