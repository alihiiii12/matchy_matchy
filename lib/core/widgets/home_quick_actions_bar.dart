import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/main_shell_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

/// شريط إجراءات الصفحة الرئيسية لمتجر ماتشي ماتشي (بدون نقاط/فواتير زادك).
class HomeQuickActionsBar extends StatelessWidget {
  const HomeQuickActionsBar({super.key});

  void _requireLogin(VoidCallback action) {
    if (!AuthService.instance.isLoggedIn) {
      Get.toNamed(AppRoutes.login);
      return;
    }
    action();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthService.instance.user?.isAdmin == true;
    final isDriver = AuthService.instance.user?.isDriver == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: AppStrings.homeSearchAction,
              icon: Icons.search,
              onPressed: () => Get.toNamed(AppRoutes.search),
            ),
          ),
          if (!isAdmin && !isDriver) ...[
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                label: AppStrings.describeYourOutfit,
                icon: Icons.checkroom_outlined,
                onPressed: () => Get.toNamed(AppRoutes.describeOutfit),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                label: AppStrings.myOrders,
                icon: Icons.receipt_long_outlined,
                onPressed: () => _requireLogin(() {
                  if (Get.isRegistered<MainShellController>()) {
                    Get.find<MainShellController>().setIndex(2);
                    return;
                  }
                  Get.toNamed(AppRoutes.myOrders);
                }),
              ),
            ),
          ],
          if (isAdmin) ...[
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                label: AppStrings.adminOrders,
                icon: Icons.admin_panel_settings_outlined,
                onPressed: () => Get.toNamed(AppRoutes.adminOrders),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                label: AppStrings.adminProducts,
                icon: Icons.inventory_2_outlined,
                onPressed: () => Get.toNamed(AppRoutes.adminProducts),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
