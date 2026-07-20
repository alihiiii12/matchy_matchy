import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class DriverManualInvoiceCard extends StatelessWidget {
  const DriverManualInvoiceCard({
    super.key,
    required this.content,
    this.compact = false,
  });

  final String content;
  final bool compact;

  static bool isManualJob(Map<String, dynamic> job) {
    return job['is_manual_invoice'] == true ||
        job['order_source'] == 'manual' ||
        ((job['manual_invoice_content'] as String?)?.trim().isNotEmpty == true);
  }

  static String? contentOf(Map<String, dynamic> job) {
    final text = job['manual_invoice_content'] as String?;
    if (text != null && text.trim().isNotEmpty) return text.trim();
    if (job['is_manual_invoice'] == true || job['order_source'] == 'manual') {
      return job['items_summary'] as String?;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (content.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: AppColors.accent, size: compact ? 18 : 20),
              const SizedBox(width: 8),
              Text(
                AppStrings.manualInvoiceForDriver,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 13 : 14,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            content,
            style: TextStyle(
              fontSize: compact ? 13 : 14,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
