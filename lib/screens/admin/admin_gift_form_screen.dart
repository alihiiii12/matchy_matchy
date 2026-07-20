import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/admin_gift_form_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class AdminGiftFormScreen extends GetView<AdminGiftFormController> {
  const AdminGiftFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isEditing ? AppStrings.editGiftReward : AppStrings.addGiftReward),
      ),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Obx(() => DropdownButtonFormField<String>(
                  value: controller.rewardType.value,
                  decoration: InputDecoration(labelText: AppStrings.giftRewardType),
                  items: AdminGiftFormController.rewardTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_typeLabel(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) controller.rewardType.value = value;
                  },
                )),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.pointsCostController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppStrings.giftPointsCost,
                hintText: '100',
              ),
              validator: (value) {
                final parsed = int.tryParse(value?.trim() ?? '');
                if (parsed == null || parsed < 1) return AppStrings.giftPointsCostInvalid;
                return null;
              },
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.rewardType.value == 'discount_percent') {
                return TextFormField(
                  controller: controller.percentController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppStrings.giftDiscountPercent,
                    hintText: '5',
                  ),
                );
              }
              if (controller.rewardType.value == 'free_product') {
                if (controller.loadingProducts.value) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return DropdownButtonFormField<String>(
                  value: controller.selectedProductId.value,
                  decoration: InputDecoration(labelText: AppStrings.giftRewardProduct),
                  items: controller.products
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text('${p.name} (${p.brand})'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => controller.selectedProductId.value = value,
                );
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.titleController,
              decoration: InputDecoration(
                labelText: AppStrings.giftRewardTitle,
                hintText: AppStrings.giftRewardTitleHint,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: AppStrings.giftRewardDescription,
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => SwitchListTile(
                  title: Text(AppStrings.giftRewardActive),
                  value: controller.isActive.value,
                  activeColor: AppColors.accent,
                  onChanged: (value) => controller.isActive.value = value,
                )),
            const SizedBox(height: 24),
            Obx(
              () => GradientButton(
                label: controller.submitting.value ? AppStrings.saving : AppStrings.save,
                onPressed: controller.submitting.value ? null : controller.submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'discount_percent':
        return AppStrings.giftTypeDiscount;
      case 'free_delivery':
        return AppStrings.giftTypeFreeDelivery;
      case 'free_product':
        return AppStrings.giftTypeFreeProduct;
      default:
        return AppStrings.giftTypeCustom;
    }
  }
}
