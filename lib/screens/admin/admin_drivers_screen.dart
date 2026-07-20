import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:matchy_matchy/core/controllers/admin_drivers_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class AdminDriversScreen extends GetView<AdminDriversController> {
  const AdminDriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.adminDrivers),
        actions: [
          IconButton(onPressed: controller.load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Get.toNamed(AppRoutes.adminCreateDriver);
          if (created == true) controller.load();
        },
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: Text(AppStrings.createDriverAccount),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null) {
          return Center(child: Text(controller.error.value!, style: TextStyle(color: AppColors.error)));
        }
        if (controller.drivers.isEmpty) {
          return Center(child: Text(AppStrings.noDriversYet));
        }

        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.drivers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final driver = controller.drivers[i];
              return _DriverCard(
                driver: driver,
                loading: controller.isActionLoading(driver['id'] as int),
                onRenew: () => controller.renewSubscription(driver),
                onCancel: () => controller.cancelSubscription(driver),
                onBlock: () => controller.blockDriver(driver),
                onDelete: () => controller.deleteDriver(driver),
                onResetPassword: () => controller.resetDriverPassword(driver),
                onCopyPassword: (password) => controller.copyText(password, AppStrings.password),
                onEdit: () => controller.editDriver(driver),
                onViewIdFront: () => controller.showIdPhoto(driver, front: true),
                onViewIdBack: () => controller.showIdPhoto(driver, front: false),
              );
            },
          ),
        );
      }),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.driver,
    required this.loading,
    required this.onRenew,
    required this.onCancel,
    required this.onBlock,
    required this.onDelete,
    required this.onResetPassword,
    required this.onCopyPassword,
    required this.onEdit,
    required this.onViewIdFront,
    required this.onViewIdBack,
  });

  final Map<String, dynamic> driver;
  final bool loading;
  final VoidCallback onRenew;
  final VoidCallback onCancel;
  final VoidCallback onBlock;
  final VoidCallback onDelete;
  final VoidCallback onResetPassword;
  final ValueChanged<String> onCopyPassword;
  final VoidCallback onEdit;
  final VoidCallback onViewIdFront;
  final VoidCallback onViewIdBack;

  @override
  Widget build(BuildContext context) {
    final profile = driver['driver_profile'] as Map<String, dynamic>?;
    final status = profile?['status'] as String? ?? '';
    final statusLabel = profile?['status_label'] as String? ?? '';
    final active = profile?['subscription_active'] as bool? ?? false;
    final statusColor = status == 'blocked'
        ? AppColors.error
        : status == 'cancelled'
            ? Colors.orange
            : active
                ? AppColors.success
                : AppColors.error;

    String expiryText = '—';
    final expiresAt = profile?['subscription_expires_at'] as String?;
    if (expiresAt != null && expiresAt.isNotEmpty) {
      try {
        expiryText = DateFormat('yyyy/MM/dd').format(DateTime.parse(expiresAt).toLocal());
      } catch (_) {
        expiryText = expiresAt;
      }
    }

    final canRenew = status != 'blocked';
    final canCancelSubscription = status == 'active';
    final canBlock = status != 'blocked' && status != 'cancelled' && status != 'expired';
    final canForceDelete = status == 'blocked' || status == 'cancelled' || status == 'expired';
    final loginPassword = profile?['login_password'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    driver['name'] as String? ?? '—',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(AppStrings.email, driver['email'] as String? ?? '—'),
            _InfoRow(AppStrings.phone, driver['phone'] as String? ?? AppStrings.phoneNotSet),
            _PasswordRow(
              password: loginPassword,
              loading: loading,
              onCopy: onCopyPassword,
              onReset: onResetPassword,
            ),
            _InfoRow(AppStrings.vehicleType, profile?['vehicle_type'] as String? ?? '—'),
            _InfoRow(AppStrings.plateNumber, profile?['plate_number'] as String? ?? '—'),
            _InfoRow(AppStrings.subscriptionExpires, expiryText),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: onViewIdFront, child: Text('${AppStrings.viewIdPhoto} — أمام'))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(onPressed: onViewIdBack, child: Text('${AppStrings.viewIdPhoto} — خلف'))),
              ],
            ),
            if (status != 'blocked') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: loading ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(AppStrings.editDriver),
                ),
              ),
            ],
            if (canRenew) ...[
              const SizedBox(height: 12),
              GradientButton(
                label: loading ? AppStrings.renewingSubscription : AppStrings.renewSubscription,
                height: 44,
                onPressed: loading ? null : onRenew,
              ),
            ],
            if (canCancelSubscription) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(onPressed: loading ? null : onCancel, child: Text(AppStrings.cancelSubscription)),
              ),
            ],
            if (canBlock) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: loading ? null : onBlock,
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: BorderSide(color: AppColors.error)),
                  child: Text(AppStrings.blockDriver),
                ),
              ),
            ],
            if (canForceDelete) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: loading ? null : onDelete,
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: BorderSide(color: AppColors.error)),
                  child: Text(AppStrings.forceDeleteDriver),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
          children: [
            TextSpan(text: '$label: ', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _PasswordRow extends StatelessWidget {
  const _PasswordRow({
    required this.password,
    required this.loading,
    required this.onCopy,
    required this.onReset,
  });

  final String? password;
  final bool loading;
  final ValueChanged<String> onCopy;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final hasPassword = password != null && password!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                children: [
                  TextSpan(
                    text: '${AppStrings.driverLoginPassword}: ',
                    style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: hasPassword ? password! : AppStrings.driverLoginPasswordMissing,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: hasPassword ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasPassword)
            IconButton(
              onPressed: loading ? null : () => onCopy(password!),
              icon: const Icon(Icons.copy_outlined, size: 18),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            )
          else
            TextButton(
              onPressed: loading ? null : onReset,
              child: Text(loading ? '...' : AppStrings.resetDriverPassword, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
