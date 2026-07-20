import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/admin_coupon_form_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class AdminCouponFormScreen extends GetView<AdminCouponFormController> {
  const AdminCouponFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isEditing ? AppStrings.editCoupon : AppStrings.addCoupon),
      ),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              AppStrings.adminCouponHint,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            _FieldLabel(AppStrings.couponName),
            TextFormField(
              controller: controller.nameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.characters,
              validator: (v) => (v == null || v.trim().isEmpty) ? AppStrings.couponNameRequired : null,
            ),
            const SizedBox(height: 16),
            const _FieldLabel('نوع الخصم'),
            Obx(
              () => Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('نسبة مئوية %'),
                    value: 'percent',
                    groupValue: controller.couponType.value,
                    onChanged: (v) => controller.couponType.value = v ?? 'percent',
                  ),
                  RadioListTile<String>(
                    title: const Text('قيمة ثابتة (ل.س)'),
                    value: 'fixed',
                    groupValue: controller.couponType.value,
                    onChanged: (v) => controller.couponType.value = v ?? 'fixed',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Obx(() => _FieldLabel(controller.valueFieldLabel)),
            Obx(
              () => TextFormField(
                controller: controller.valueController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  final value = int.tryParse(v?.trim() ?? '');
                  if (value == null || value < 1) return AppStrings.couponValueRequired;
                  if (controller.couponType.value == 'percent' && value > 100) {
                    return AppStrings.couponValueRequired;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.couponPerUserLimit),
            TextFormField(
              controller: controller.perUserLimitController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final value = int.tryParse(v?.trim() ?? '');
                if (value == null || value < 1) return AppStrings.couponPerUserLimitRequired;
                return null;
              },
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.couponExpiryDate),
            Obx(
              () => OutlinedButton.icon(
                onPressed: () => controller.pickExpiryDate(context),
                icon: const Icon(Icons.calendar_today_outlined),
                label: Align(
                  alignment: Alignment.centerRight,
                  child: Text(controller.expiresAtLabel),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  alignment: Alignment.centerRight,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Obx(
              () => GradientButton(
                label: controller.submitting.value
                    ? AppStrings.saving
                    : (controller.isEditing ? AppStrings.saveChanges : AppStrings.addCoupon),
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
