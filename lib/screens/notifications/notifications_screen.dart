import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/notifications_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/app_notification.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class NotificationsScreen extends GetView<NotificationsController> {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = controller.service;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.notifications),
        actions: [
          Obx(() {
            if (service.items.isEmpty) return const SizedBox.shrink();
            return PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'read_all') {
                  controller.markAllRead();
                } else if (value == 'delete_all') {
                  controller.deleteAllNotifications();
                }
              },
              itemBuilder: (context) => [
                if (service.unreadCount.value > 0)
                  PopupMenuItem(
                    value: 'read_all',
                    child: Text(AppStrings.markAllRead),
                  ),
                PopupMenuItem(
                  value: 'delete_all',
                  child: Text(AppStrings.deleteAllNotifications),
                ),
              ],
            );
          }),
        ],
      ),
      body: Obx(() {
        if (service.loading.value && service.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (service.items.isEmpty) {
          final loadError = service.error.value;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    loadError != null ? Icons.cloud_off_outlined : Icons.notifications_none,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loadError ?? AppStrings.noNotifications,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: loadError != null ? AppColors.error : AppColors.textSecondary),
                  ),
                  if (loadError != null) ...[
                    const SizedBox(height: 16),
                    OutlinedButton(onPressed: controller.refresh, child: Text(AppStrings.retryAction)),
                  ],
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: service.items.length,
            itemBuilder: (_, i) {
              final notification = service.items[i];
              return Obx(() {
                controller.confirmingIds.length;
                controller.confirmStateVersion;
                final deleting = controller.isDeleting(notification.id);
                return Dismissible(
                  key: ValueKey('notification_${notification.id}'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => controller.deleteNotification(notification),
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    color: AppColors.error,
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  child: _NotificationTile(
                    notification: notification,
                    confirming: controller.isConfirming(notification.id),
                    deleting: deleting,
                    showConfirmButton: controller.canShowConfirmButton(notification),
                    alreadyConfirmed: controller.isArrivalConfirmed(notification),
                    onTap: () => controller.onNotificationTap(notification),
                    onConfirmArrival: () => controller.confirmArrival(notification),
                    onDelete: () => controller.deleteNotification(notification),
                  ),
                );
              });
            },
          ),
        );
      }),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.confirming,
    required this.deleting,
    required this.showConfirmButton,
    required this.alreadyConfirmed,
    required this.onTap,
    required this.onConfirmArrival,
    required this.onDelete,
  });

  final AppNotificationItem notification;
  final bool confirming;
  final bool deleting;
  final bool showConfirmButton;
  final bool alreadyConfirmed;
  final VoidCallback onTap;
  final VoidCallback onConfirmArrival;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: notification.isRead ? null : AppColors.accent.withValues(alpha: 0.05),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: notification.isRead
                    ? AppColors.inputFill
                    : AppColors.accent.withValues(alpha: 0.15),
                child: Icon(
                  Icons.notifications,
                  color: notification.isRead ? AppColors.textSecondary : AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          notification.timeLabel,
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(notification.body, style: TextStyle(color: AppColors.textSecondary)),
                    if (showConfirmButton) ...[
                      const SizedBox(height: 12),
                      GradientButton(
                        label: confirming ? AppStrings.confirmingArrival : AppStrings.confirmArrival,
                        height: 44,
                        onPressed: confirming ? null : onConfirmArrival,
                      ),
                    ] else if (alreadyConfirmed) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: AppColors.success, size: 20),
                            SizedBox(width: 8),
                            Text(
                              AppStrings.arrivalAlreadyConfirmed,
                              style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: deleting ? null : onDelete,
                icon: deleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.delete_outline, color: AppColors.error.withValues(alpha: 0.85), size: 22),
                tooltip: AppStrings.deleteNotification,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
