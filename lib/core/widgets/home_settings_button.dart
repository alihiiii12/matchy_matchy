import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class HomeSettingsButton extends StatelessWidget {
  const HomeSettingsButton({super.key});

  void _requireLogin(VoidCallback action) {
    if (!AuthService.instance.isLoggedIn) {
      Get.toNamed(AppRoutes.login);
      return;
    }
    action();
  }

  bool get _showChangePassword {
    final user = AuthService.instance.user;
    if (user == null) return true;
    return !user.isSeller && !user.isDriver;
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        AppStrings.settings,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _SettingsTile(
                  icon: Icons.person_outline,
                  label: AppStrings.editProfile,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _requireLogin(() => Get.toNamed(AppRoutes.editProfile));
                  },
                ),
                _SettingsTile(
                  icon: Icons.language,
                  label: AppStrings.language,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Get.toNamed(AppRoutes.language);
                  },
                ),
                if (_showChangePassword)
                  _SettingsTile(
                    icon: Icons.lock_outline,
                    label: AppStrings.changePassword,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _requireLogin(() => Get.toNamed(AppRoutes.changePassword));
                    },
                  ),
                _SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  label: AppStrings.appearance,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Get.toNamed(AppRoutes.appearance);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppStrings.settings,
      onPressed: () => _openSheet(context),
      icon: const Icon(Icons.settings_outlined),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: Icon(Icons.chevron_left, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
