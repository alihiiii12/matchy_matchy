import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/admin_credit_points_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class AdminCreditPointsScreen extends GetView<AdminCreditPointsController> {
  const AdminCreditPointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.creditPoints)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: controller.setSearch,
              decoration: InputDecoration(
                hintText: AppStrings.creditPointsChooseCustomer,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final err = controller.error.value;
              if (err != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(err, textAlign: TextAlign.center, style: TextStyle(color: AppColors.error)),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: controller.load, child: Text(AppStrings.retryAction)),
                      ],
                    ),
                  ),
                );
              }

              final list = controller.filteredUsers;
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    AppStrings.noCustomersForCreditPoints,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: list.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final user = list[index];
                  final id = user['id'] as int?;
                  final crediting = controller.creditingUserId.value == id;

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          _initial((user['name'] as String?) ?? '?'),
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                      title: Text(user['name'] as String? ?? '—', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['phone'] as String? ?? '—'),
                          Text(
                            '${AppStrings.pointsBalance}: ${user['points_balance'] ?? 0} ${AppStrings.pointsUnit}',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: crediting
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.add_circle_outline, color: AppColors.primary),
                      onTap: crediting ? null : () => controller.creditUser(user),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

String _initial(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, 1);
}
