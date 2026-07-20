import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/admin_sales_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';

class AdminSalesScreen extends GetView<AdminSalesController> {
  const AdminSalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.adminSales),
        actions: [
          Obx(() {
            if (controller.exporting.value) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            return IconButton(
              tooltip: AppStrings.exportPdf,
              onPressed: controller.sales.isEmpty ? null : controller.exportPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
            );
          }),
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
        if (controller.sales.isEmpty) {
          return Center(child: Text(AppStrings.noSalesYet));
        }

        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _SalesSummary(
                totalLines: controller.totalLines.value,
                totalRevenue: controller.totalRevenue.value,
              ),
              const SizedBox(height: 16),
              ...controller.sales.map((sale) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SaleLineCard(sale: sale),
                  )),
            ],
          ),
        );
      }),
    );
  }
}

class _SalesSummary extends StatelessWidget {
  const _SalesSummary({required this.totalLines, required this.totalRevenue});

  final int totalLines;
  final double totalRevenue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${AppStrings.totalSoldItems}: $totalLines',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            '${AppStrings.totalSalesRevenue}: ${CurrencyFormatter.format(totalRevenue)}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _SaleLineCard extends StatelessWidget {
  const _SaleLineCard({required this.sale});

  final Map<String, dynamic> sale;

  @override
  Widget build(BuildContext context) {
    final productName = sale['product_name'] as String? ?? '—';
    final brand = sale['product_brand'] as String?;
    final sellerName = sale['seller_name'] as String? ?? AppStrings.unknownSeller;
    final seller = sale['seller'] as Map<String, dynamic>?;
    final sellerPhone = seller?['phone'] as String?;
    final sellerGov = sale['seller_governorate_name'] as String?;
    final quantity = sale['quantity'] as int? ?? 0;
    final unitPrice = (sale['unit_price'] as num?)?.toDouble() ?? 0;
    final lineTotal = (sale['line_total'] as num?)?.toDouble() ?? 0;
    final orderCode = sale['order_code'] as String? ?? '—';
    final statusLabel = sale['order_status_label'] as String? ?? '—';
    final soldAt = _formatDate(sale['sold_at'] as String?);
    final customer = sale['customer'] as Map<String, dynamic>?;
    final customerName = customer?['name'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(productName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      if (brand != null && brand.isNotEmpty)
                        Text(brand, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Text(
                  CurrencyFormatter.format(lineTotal),
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.accent),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.storefront_outlined,
              label: AppStrings.sellerNameLabel,
              value: sellerName,
            ),
            if (sellerPhone != null && sellerPhone.isNotEmpty)
              _InfoRow(icon: Icons.phone_outlined, label: AppStrings.phone, value: sellerPhone),
            if (sellerGov != null && sellerGov.isNotEmpty)
              _InfoRow(icon: Icons.location_on_outlined, label: AppStrings.sellerLocation, value: sellerGov),
            _InfoRow(
              icon: Icons.shopping_bag_outlined,
              label: AppStrings.quantity,
              value: '$quantity × ${CurrencyFormatter.format(unitPrice)}',
            ),
            _InfoRow(icon: Icons.receipt_long_outlined, label: AppStrings.order, value: orderCode),
            if (customerName != null && customerName.isNotEmpty)
              _InfoRow(icon: Icons.person_outline, label: AppStrings.customer, value: customerName),
            _InfoRow(icon: Icons.info_outline, label: AppStrings.orderStatus, value: statusLabel),
            _InfoRow(icon: Icons.calendar_today_outlined, label: AppStrings.soldAt, value: soldAt),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
                children: [
                  TextSpan(text: '$label: ', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
