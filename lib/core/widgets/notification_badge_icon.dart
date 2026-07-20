import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/services/notification_service.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class NotificationBadgeIcon extends StatelessWidget {
  const NotificationBadgeIcon({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<NotificationService>()) {
      return IconButton(
        onPressed: () => Get.toNamed(AppRoutes.notifications),
        icon: const Icon(Icons.notifications_outlined),
      );
    }

    final service = Get.find<NotificationService>();

    return Obx(
      () => Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: () => Get.toNamed(AppRoutes.notifications),
            icon: const Icon(Icons.notifications_outlined),
          ),
          if (service.unreadCount.value > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                child: Text(
                  service.unreadCount.value > 9 ? '9+' : '${service.unreadCount.value}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
