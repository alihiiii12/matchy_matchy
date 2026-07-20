import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/repositories/order_repository.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';
import 'package:matchy_matchy/core/widgets/catalog_image.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderInvoiceSummary extends StatelessWidget {
  const OrderInvoiceSummary({
    super.key,
    required this.order,
    this.compact = false,
    this.showEstimatedTime = true,
  });

  final OrderSummary order;
  final bool compact;
  final bool showEstimatedTime;

  Future<void> _callCaptain(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 13.0 : 14.0;
    final deliveryLabel = order.deliveryFee > 0
        ? CurrencyFormatter.format(order.deliveryFee)
        : AppStrings.deliveryFeePendingAdmin;
    final driver = order.delivery?.driver;
    final itemsLabel = order.itemsLabel;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.orderInvoice,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: compact ? 14 : 15,
            ),
          ),
          if (order.items.isNotEmpty) ...[
            SizedBox(height: compact ? 8 : 10),
            ...order.items.map((item) => _ProductRow(item: item, compact: compact)),
            SizedBox(height: compact ? 6 : 8),
            const Divider(height: 1),
          ] else if (itemsLabel.isNotEmpty) ...[
            SizedBox(height: compact ? 8 : 10),
            _row('المنتج', itemsLabel, fontSize: fontSize, isTextValue: true),
            SizedBox(height: compact ? 6 : 8),
            const Divider(height: 1),
          ],
          SizedBox(height: compact ? 8 : 10),
          _row(AppStrings.orderPrice, CurrencyFormatter.format(order.subtotal), fontSize: fontSize),
          SizedBox(height: compact ? 4 : 6),
          _row(AppStrings.deliveryFee, deliveryLabel, fontSize: fontSize, isTextValue: order.deliveryFee <= 0),
          if (order.discountAmount > 0) ...[
            SizedBox(height: compact ? 4 : 6),
            _row(
              '− ${AppStrings.discount}',
              CurrencyFormatter.format(order.discountAmount),
              fontSize: fontSize,
              valueColor: AppColors.success,
            ),
          ],
          SizedBox(height: compact ? 6 : 8),
          const Divider(height: 1),
          SizedBox(height: compact ? 6 : 8),
          _row(
            AppStrings.total,
            CurrencyFormatter.format(order.total),
            fontSize: compact ? 14 : 15,
            bold: true,
            valueColor: AppColors.accent,
          ),
          if (showEstimatedTime && order.estimatedTime != null && order.estimatedTime!.isNotEmpty) ...[
            SizedBox(height: compact ? 8 : 10),
            _row(
              AppStrings.estimatedArrival,
              order.estimatedTime!,
              fontSize: fontSize,
              isTextValue: true,
            ),
          ],
          if (driver != null) ...[
            SizedBox(height: compact ? 8 : 10),
            _row(AppStrings.driverInfo, driver.name, fontSize: fontSize, isTextValue: true),
            if (driver.phone.trim().isNotEmpty) ...[
              SizedBox(height: compact ? 4 : 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'هاتف الكابتن',
                      style: TextStyle(fontSize: fontSize, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ),
                  InkWell(
                    onTap: () => _callCaptain(driver.phone),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone, size: 16, color: AppColors.accent),
                          const SizedBox(width: 6),
                          Text(
                            driver.phone,
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    required double fontSize,
    bool bold = false,
    Color? valueColor,
    bool isTextValue = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ?? (isTextValue ? AppColors.textSecondary : AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.item, required this.compact});

  final OrderLineItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 6 : 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: compact ? 40 : 48,
              height: compact ? 40 : 48,
              child: CatalogImage(
                imageUrl: item.imageUrl,
                fallbackIcon: Icons.checkroom_outlined,
                fallbackColor: AppColors.primary,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 13 : 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'الكمية: ${item.quantity}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: compact ? 12 : 13,
                  ),
                ),
                if (item.optionsLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.optionsLabel!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: compact ? 11 : 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(item.price * item.quantity),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: compact ? 12 : 13,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
