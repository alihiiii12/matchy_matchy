import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/brand_logo.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

Future<void> showWelcomeDialog(BuildContext context, AuthUser user) {
  late final IconData roleIcon;
  late final Color roleColor;

  if (user.isDriver) {
    roleIcon = Icons.local_shipping_outlined;
    roleColor = AppColors.accent;
  } else if (user.isSeller) {
    roleIcon = Icons.storefront_outlined;
    roleColor = AppColors.accent;
  } else {
    roleIcon = Icons.favorite_outline;
    roleColor = AppColors.success;
  }

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradientVertical,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const BrandLogo(size: 96),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(roleIcon, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          user.roleLabel,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                AuthService.welcomeMessage(user),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.6,
                  color: roleColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: GradientButton(
                label: AppStrings.welcomeContinue,
                onPressed: () => Get.back(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
