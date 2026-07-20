import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/main_shell_controller.dart';
import 'package:matchy_matchy/core/controllers/theme_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/core/widgets/glowing_bottom_nav_bar.dart';
import 'package:matchy_matchy/screens/categories/categories_screen.dart';
import 'package:matchy_matchy/screens/favorites/favorites_screen.dart';
import 'package:matchy_matchy/screens/home/home_screen.dart';
import 'package:matchy_matchy/screens/orders/my_orders_screen.dart';
import 'package:matchy_matchy/screens/profile/profile_screen.dart';
import 'package:matchy_matchy/screens/driver/driver_jobs_screen.dart';

class MainShell extends GetView<MainShellController> {
  const MainShell({super.key});

  static final _customerScreens = [
    const HomeScreen(),
    const CategoriesScreen(embedded: true),
    MyOrdersScreen(embedded: true),
    const FavoritesScreen(embedded: true),
    const ProfileScreen(),
  ];

  static final _driverScreens = [
    const DriverJobsScreen(embedded: true),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<MainShellController>()) {
      Get.put(MainShellController());
    }

    return Obx(
      () {
        final _ = Get.find<ThemeController>().themeMode.value;
        final user = AuthService.instance.userRx.value;
        final isDriver = user?.isDriver == true;
        final screens = isDriver ? _driverScreens : _customerScreens;
        final navItems = isDriver ? _driverNavItems : _customerNavItems;

        final index = controller.currentIndex.value.clamp(0, screens.length - 1);
        if (index != controller.currentIndex.value) {
          controller.currentIndex.value = index;
        }

        return Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

              return FadeTransition(
                opacity: fade,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(index),
              child: screens[index],
            ),
          ),
          bottomNavigationBar: GlowingBottomNavBar(
            currentIndex: index,
            onTap: controller.setIndex,
            items: navItems,
          ),
        );
      },
    );
  }

  static List<NavBarDestination> get _customerNavItems => [
    NavBarDestination(icon: Icons.home_outlined, activeIcon: Icons.home, label: AppStrings.navHome),
    NavBarDestination(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view, label: AppStrings.navCategories),
    NavBarDestination(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: AppStrings.navOrders),
    NavBarDestination(icon: Icons.favorite_border, activeIcon: Icons.favorite, label: AppStrings.navFavorite),
    NavBarDestination(icon: Icons.person_outline, activeIcon: Icons.person, label: AppStrings.navProfile),
  ];

  static List<NavBarDestination> get _driverNavItems => [
    NavBarDestination(icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping, label: AppStrings.navDriverJobs),
    NavBarDestination(icon: Icons.person_outline, activeIcon: Icons.person, label: AppStrings.navProfile),
  ];
}
