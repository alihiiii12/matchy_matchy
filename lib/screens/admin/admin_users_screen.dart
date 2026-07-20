import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/admin_users_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class AdminUsersScreen extends GetView<AdminUsersController> {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.adminUsers),
        actions: [
          Obx(() {
            if (controller.exporting.value) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            return IconButton(
              tooltip: AppStrings.exportPdf,
              onPressed: controller.users.isEmpty ? null : controller.exportPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
            );
          }),
          IconButton(onPressed: controller.load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null) {
          return Center(child: Text(controller.error.value!, style: TextStyle(color: AppColors.error)));
        }
        if (controller.users.isEmpty) {
          return Center(child: Text(AppStrings.noUsersYet));
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${AppStrings.totalAccounts}: ${controller.users.length}',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: controller.exportPdf,
                    icon: const Icon(Icons.download_outlined),
                    label: Text(AppStrings.exportPdf),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.users.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final user = controller.users[i];
                    return _UserCard(user: user, index: i + 1);
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.index});

  final Map<String, dynamic> user;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                  child: Text('$index', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    user['name'] as String? ?? '—',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user['role_label'] as String? ?? 'زبون',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.phone_outlined, label: AppStrings.phone, value: user['phone'] as String? ?? '—'),
            const SizedBox(height: 6),
            _InfoRow(icon: Icons.email_outlined, label: AppStrings.email, value: user['email'] as String? ?? '—'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    );
  }
}
