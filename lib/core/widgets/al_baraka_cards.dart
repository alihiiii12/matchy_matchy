import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class AlBarakaCards extends StatelessWidget {
  const AlBarakaCards({super.key});

  static const frontAsset = 'assets/images/al_baraka_card_front.png';
  static const backAsset = 'assets/images/al_baraka_card_back.png';
  static const accountName = 'رزان المشي';
  static const cif = '1444156';
  static const branch = 'مشاريع حلب';
  static const swift = 'BBSYSYDA';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            AppStrings.alBaraka,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(frontAsset, fit: BoxFit.contain),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(backAsset, fit: BoxFit.contain),
          ),
          const SizedBox(height: 12),
          Text(accountName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 6),
          Text('${AppStrings.alBarakaCif}: $cif', textAlign: TextAlign.center),
          Text('${AppStrings.alBarakaBranch}: $branch', textAlign: TextAlign.center),
          Text('${AppStrings.alBarakaSwift}: $swift', textAlign: TextAlign.center),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: cif));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppStrings.alBarakaCifCopied)),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 18),
            label: Text(AppStrings.copyCif),
          ),
          Text(
            AppStrings.alBarakaHint,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.45),
          ),
        ],
      ),
    );
  }
}
