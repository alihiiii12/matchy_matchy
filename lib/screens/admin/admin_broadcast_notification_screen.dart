import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/admin_broadcast_notification_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class AdminBroadcastNotificationScreen extends GetView<AdminBroadcastNotificationController> {
  const AdminBroadcastNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.adminBroadcastMessage)),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              AppStrings.adminBroadcastHint,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            _FieldLabel(AppStrings.notificationTitle),
            TextFormField(
              controller: controller.titleController,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty) ? AppStrings.notificationTitleRequired : null,
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.notificationBody),
            TextFormField(
              controller: controller.bodyController,
              textInputAction: TextInputAction.newline,
              minLines: 4,
              maxLines: 8,
              validator: (v) => (v == null || v.trim().isEmpty) ? AppStrings.notificationBodyRequired : null,
            ),
            const SizedBox(height: 20),
            _FieldLabel(AppStrings.broadcastAudience),
            Obx(
              () => Column(
                children: [
                  RadioListTile<String>(
                    value: 'all',
                    groupValue: controller.audience.value,
                    onChanged: (v) => controller.audience.value = v!,
                    title: Text(AppStrings.broadcastAudienceAll),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<String>(
                    value: 'customer',
                    groupValue: controller.audience.value,
                    onChanged: (v) => controller.audience.value = v!,
                    title: Text(AppStrings.broadcastAudienceCustomers),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<String>(
                    value: 'seller',
                    groupValue: controller.audience.value,
                    onChanged: (v) => controller.audience.value = v!,
                    title: Text(AppStrings.broadcastAudienceSellers),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Obx(
              () => GradientButton(
                label: controller.submitting.value ? AppStrings.sendingMessage : AppStrings.sendMessage,
                onPressed: controller.submitting.value ? null : controller.submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    );
  }
}
