import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';

class DriverJobPricing extends StatelessWidget {
  const DriverJobPricing({
    super.key,
    required this.job,
    this.compact = false,
    this.onTap,
  });

  final Map<String, dynamic> job;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final subtotal = job['subtotal'] as num?;
    final deliveryFee = job['delivery_fee'] as num?;
    final discount = (job['discount_amount'] as num?) ?? 0;
    final total = job['total'] as num?;

    if (subtotal == null && deliveryFee == null && total == null) {
      return const SizedBox.shrink();
    }

    final fontSize = compact ? 13.0 : 14.0;

    final box = Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (subtotal != null)
            _row(AppStrings.orderPrice, subtotal, fontSize: fontSize),
          if (deliveryFee != null) ...[
            if (subtotal != null) SizedBox(height: compact ? 4 : 6),
            _row(AppStrings.deliveryFee, deliveryFee, fontSize: fontSize),
          ],
          if (discount > 0) ...[
            SizedBox(height: compact ? 4 : 6),
            _row('− ${AppStrings.discount}', discount, fontSize: fontSize, valueColor: AppColors.success),
          ],
          if (total != null) ...[
            SizedBox(height: compact ? 6 : 8),
            Divider(height: 1, color: AppColors.border),
            SizedBox(height: compact ? 6 : 8),
            _row(
              AppStrings.total,
              total,
              fontSize: compact ? 14 : 15,
              bold: true,
              valueColor: AppColors.accent,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: box,
      ),
    );
  }

  Widget _row(
    String label,
    num value, {
    required double fontSize,
    bool bold = false,
    Color? valueColor,
  }) {
    return Row(
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
        Text(
          CurrencyFormatter.format(value),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
