import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class ShamCashBarcodeCard extends StatelessWidget {
  const ShamCashBarcodeCard({super.key});

  static const _qrAsset = 'assets/images/sham_cash_qr.png';

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
            'شام كاش',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              _qrAsset,
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'امسح رمز QR أو حوّل المبلغ يدوياً ثم أكّد الطلب',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}
