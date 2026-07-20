import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/data/body_measurements.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';
import 'package:matchy_matchy/core/widgets/catalog_image.dart';

/// منتجات الطلب في بطاقة/تفاصيل مهمة الكابتن.
class DriverJobProducts extends StatelessWidget {
  const DriverJobProducts({
    super.key,
    required this.job,
    this.compact = false,
  });

  final Map<String, dynamic> job;
  final bool compact;

  static List<Map<String, dynamic>> itemsOf(Map<String, dynamic> job) {
    final raw = job['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) => (e['product_name']?.toString() ?? '').trim().isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = itemsOf(job);
    final summary = (job['items_summary'] as String?)?.trim() ?? '';

    if (items.isEmpty && summary.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'المنتجات المطلوبة',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: compact ? 13 : 14,
          ),
        ),
        SizedBox(height: compact ? 6 : 8),
        if (items.isNotEmpty)
          ...items.map((item) => _ItemRow(item: item, compact: compact))
        else
          Text(
            summary,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: compact ? 12 : 13,
              height: 1.4,
            ),
          ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.compact});

  final Map<String, dynamic> item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final name = item['product_name']?.toString() ?? 'منتج';
    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final imageUrl = item['image_url']?.toString();
    Map<String, dynamic>? options;
    final rawOpts = item['options'];
    if (rawOpts is Map) {
      options = Map<String, dynamic>.from(rawOpts);
    }
    final optionsLabel = BodyMeasurements.formatMemberOptions(options);

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 6 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: compact ? 40 : 48,
              height: compact ? 40 : 48,
              child: CatalogImage(
                imageUrl: imageUrl,
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
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 13 : 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'الكمية: $qty',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: compact ? 12 : 13,
                  ),
                ),
                if (optionsLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    optionsLabel,
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
          if (price > 0)
            Text(
              CurrencyFormatter.format(price * qty),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: compact ? 12 : 13,
              ),
            ),
        ],
      ),
    );
  }
}
