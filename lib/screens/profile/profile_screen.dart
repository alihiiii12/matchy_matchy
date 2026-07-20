import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/profile_avatar.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  bool get _isDriver => AuthService.instance.user?.isDriver == true;
  bool get _isStaff => _isDriver;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 16),
            Obx(() {
              final user = AuthService.instance.userRx.value;
              return Row(
                children: [
                  ProfileAvatar(
                    key: ValueKey(user?.avatarUrl ?? 'no-avatar'),
                    radius: 36,
                    imageUrl: user?.avatarUrl,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'زائر',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      if (AuthService.instance.isLoggedIn &&
                          ((user?.phone?.trim().isNotEmpty ?? false) || _isStaff))
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            (user?.phone?.trim().isNotEmpty ?? false)
                                ? user!.phone!
                                : AppStrings.phoneNotSet,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ),
                      if (AuthService.instance.isLoggedIn)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            user!.roleLabel,
                            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () async {
                      final updated = await Get.toNamed(AppRoutes.editProfile);
                      if (updated == true) {
                        await AuthService.instance.refreshProfile();
                      }
                    },
                    icon: Icon(Icons.edit_outlined, color: AppColors.accent),
                  ),
                ],
              );
            }),
            const SizedBox(height: 24),
            _MenuSection(
              title: AppStrings.account,
              items: [
                _MenuItem(icon: Icons.person_outline, label: AppStrings.editProfile, route: AppRoutes.editProfile),
                if (!_isStaff)
                  _MenuItem(icon: Icons.lock_outline, label: AppStrings.changePassword, route: AppRoutes.changePassword),
                _MenuItem(icon: Icons.dark_mode_outlined, label: AppStrings.appearance, route: AppRoutes.appearance),
                _MenuItem(icon: Icons.language, label: AppStrings.language, route: AppRoutes.language),
              ],
            ),
            if (_isDriver)
              _MenuSection(
                title: AppStrings.driverAccount,
                items: [
                  _MenuItem(
                    icon: Icons.card_membership_outlined,
                    label: AppStrings.driverSubscriptions,
                    route: AppRoutes.driverSubscriptions,
                  ),
                  _MenuItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: AppStrings.driverEarnings,
                    route: AppRoutes.driverEarnings,
                  ),
                ],
              )
            else
              _MenuSection(
                title: AppStrings.shopping,
                items: [
                  _MenuItem(icon: Icons.grid_view, label: AppStrings.allCategories, route: AppRoutes.categories),
                  _MenuItem(icon: Icons.shopping_cart_outlined, label: AppStrings.myCart, route: AppRoutes.cart),
                  _MenuItem(icon: Icons.receipt_long_outlined, label: AppStrings.myOrders, route: AppRoutes.myOrders),
                  _MenuItem(icon: Icons.favorite_border, label: AppStrings.myFavorite, route: AppRoutes.favorites),
                  _MenuItem(icon: Icons.checkroom_outlined, label: AppStrings.describeYourOutfit, route: AppRoutes.describeOutfit),
                  _MenuItem(icon: Icons.straighten_outlined, label: AppStrings.sizeGuide, route: AppRoutes.sizeGuide),
                  _MenuItem(icon: Icons.bar_chart, label: AppStrings.statistics, route: AppRoutes.statistics),
                ],
              ),
            _MenuSection(
              title: AppStrings.support,
              items: [
                _MenuItem(icon: Icons.notifications_outlined, label: AppStrings.notifications, route: AppRoutes.notifications),
                _MenuItem(icon: Icons.help_outline, label: AppStrings.helpSupport, route: AppRoutes.helpSupport),
                _MenuItem(icon: Icons.policy_outlined, label: AppStrings.legalPolicies, route: AppRoutes.legalPolicies),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.logout, color: AppColors.error),
              title: Text(AppStrings.logout, style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
              onTap: () => _showLogoutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.logout),
        content: Text(AppStrings.logoutConfirm),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () async {
              Get.back();
              await AuthService.instance.logout();
              Get.offAllNamed(AppRoutes.login);
            },
            child: Text(AppStrings.logout, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});

  final String title;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 8),
          child: Text(title, style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        ...items.map((item) => ListTile(
              leading: Icon(item.icon, color: AppColors.primary),
              title: Text(item.label),
              trailing: forwardChevronIcon(context),
              onTap: () async {
                if (item.route == AppRoutes.editProfile) {
                  final updated = await Get.toNamed(item.route);
                  if (updated == true) {
                    await AuthService.instance.refreshProfile();
                  }
                  return;
                }
                Get.toNamed(item.route);
              },
              contentPadding: EdgeInsets.zero,
            )),
        const Divider(),
      ],
    );
  }
}

class _MenuItem {
  const _MenuItem({required this.icon, required this.label, required this.route});

  final IconData icon;
  final String label;
  final String route;
}
