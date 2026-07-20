import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/admin_free_delivery_subscription_form_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class AdminFreeDeliverySubscriptionFormScreen extends GetView<AdminFreeDeliverySubscriptionFormController> {
  const AdminFreeDeliverySubscriptionFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isEditing ? AppStrings.editFreeDeliverySubscription : AppStrings.addFreeDeliverySubscription),
      ),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              AppStrings.adminFreeDeliveryHint,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            _FieldLabel(AppStrings.freeDeliverySubscriptionBrand),
            Obx(() {
              if (controller.loadingSellers.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final options = controller.sellersWithBrand;
              if (options.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(AppStrings.noSellerBrandsForFreeDelivery, style: TextStyle(color: AppColors.textSecondary)),
                );
              }

              final selected = controller.selectedSellerId.value;
              final items = options
                  .map(
                    (seller) => DropdownMenuItem<int>(
                      value: seller['id'] as int?,
                      child: Text(controller.sellerLabel(seller)),
                    ),
                  )
                  .toList();

              return DropdownButtonFormField<int>(
                value: items.any((item) => item.value == selected) ? selected : null,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: items,
                onChanged: (value) => controller.selectedSellerId.value = value,
                validator: (_) => controller.selectedSellerId.value == null
                    ? AppStrings.freeDeliverySubscriptionBrandRequired
                    : null,
              );
            }),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.freeDeliverySubscriptionStartDate),
            Obx(
              () => OutlinedButton.icon(
                onPressed: () => controller.pickStartsAt(context),
                icon: const Icon(Icons.calendar_today_outlined),
                label: Align(alignment: Alignment.centerRight, child: Text(controller.startsAtLabel)),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48), alignment: Alignment.centerRight),
              ),
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.freeDeliverySubscriptionEndDate),
            Obx(
              () => OutlinedButton.icon(
                onPressed: () => controller.pickExpiresAt(context),
                icon: const Icon(Icons.event_outlined),
                label: Align(alignment: Alignment.centerRight, child: Text(controller.expiresAtLabel)),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48), alignment: Alignment.centerRight),
              ),
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.freeDeliverySubscriptionAmount),
            TextFormField(
              controller: controller.amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                suffixText: AppStrings.currencySymbol,
              ),
              validator: (v) {
                final value = double.tryParse(v?.trim() ?? '');
                if (value == null || value < 0) return AppStrings.freeDeliverySubscriptionAmountRequired;
                return null;
              },
            ),
            const SizedBox(height: 28),
            Obx(
              () => GradientButton(
                label: controller.submitting.value
                    ? AppStrings.saving
                    : (controller.isEditing ? AppStrings.saveChanges : AppStrings.addFreeDeliverySubscription),
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
