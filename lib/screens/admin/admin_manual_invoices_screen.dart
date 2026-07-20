import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/admin_manual_invoices_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class AdminManualInvoicesScreen extends GetView<AdminManualInvoicesController> {
  const AdminManualInvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.adminManualInvoices),
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
        if (controller.invoices.isEmpty) {
          return Center(child: Text(AppStrings.noManualInvoicesYet));
        }

        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.invoices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final invoice = controller.invoices[i];
              final id = invoice['id'] as int;
              final busy = controller.actionId.value == id;
              final status = invoice['status'] as String? ?? 'pending';
              final customer = invoice['customer'] as Map<String, dynamic>?;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('#$id', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          const Spacer(),
                          _StatusChip(status: invoice['status_label'] as String? ?? status),
                        ],
                      ),
                      if (customer != null) ...[
                        const SizedBox(height: 8),
                        Text('${AppStrings.customer}: ${customer['name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        if ((customer['phone'] as String?)?.isNotEmpty == true)
                          Text('${AppStrings.phone}: ${customer['phone']}', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                      const SizedBox(height: 10),
                      Text(invoice['content'] as String? ?? '', style: TextStyle(height: 1.5, color: AppColors.textSecondary)),
                      if ((invoice['address'] as String?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Text('${AppStrings.address}: ${invoice['address']}', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                      if (status == 'pending') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: busy ? null : () => controller.approve(invoice),
                                child: Text(busy ? AppStrings.processing : AppStrings.approve),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: busy ? null : () => controller.reject(invoice),
                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                                child: Text(AppStrings.reject),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (status == 'approved' && invoice['order_id'] != null) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: busy ? null : () => controller.assignDriverToOrder(invoice['order_id'] as int),
                          icon: const Icon(Icons.local_shipping_outlined),
                          label: Text(AppStrings.assignDriver),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status, style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
