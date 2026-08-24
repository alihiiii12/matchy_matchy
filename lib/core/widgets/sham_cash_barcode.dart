import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class ShamCashBarcodeCard extends StatelessWidget {
  const ShamCashBarcodeCard({super.key});

  static const qrAsset = 'assets/images/sham_cash_qr.png';
  static const accountName = 'رزان مازن العش';
  static const accountId = '1988254382a4c58fc28efa5db9d954ee';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            AppStrings.shamCash,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              qrAsset,
              width: 240,
              height: 240,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            accountName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          SelectableText(
            accountId,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: accountId));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppStrings.shamCashIdCopied)),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 18),
            label: Text(AppStrings.copyAccountId),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.shamCashScanHint,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.45),
          ),
        ],
      ),
    );
  }
}
