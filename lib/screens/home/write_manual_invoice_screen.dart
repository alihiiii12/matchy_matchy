import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/write_manual_invoice_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/delivery_location_chooser.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class WriteManualInvoiceScreen extends GetView<WriteManualInvoiceController> {
  const WriteManualInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.writeInvoiceAction)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(AppStrings.manualInvoiceHint, style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 16),
          Obx(() {
            final _ = controller.locationTick.value;
            return DeliveryLocationChooser(
              locationReady: controller.locationReady.value,
              locationLoading: controller.locationLoading.value,
              selectedAddress: controller.locationSummary.value,
              governorateLabel: controller.governorateSummary.value,
              locationRevision: controller.locationTick.value,
              onHomeDescriptionChanged: () => controller.locationTick.value++,
              onUseMyLocation: controller.useMyLocation,
              onPickOtherLocation: controller.pickOtherLocation,
            );
          }),
          const SizedBox(height: 16),
          TextField(
            controller: controller.contentController,
            maxLines: 10,
            decoration: InputDecoration(
              labelText: AppStrings.manualInvoiceContentLabel,
              hintText: AppStrings.manualInvoiceContentHint,
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          Obx(() {
            final feedback = controller.submitFeedback.value;
            final isSuccess = controller.submitFeedbackSuccess.value == true;
            if (feedback != null && feedback.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isSuccess ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (isSuccess ? AppColors.success : AppColors.error).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                        color: isSuccess ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          feedback,
                          style: TextStyle(
                            color: isSuccess ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Obx(
            () => GradientButton(
              label: controller.submitting.value ? AppStrings.sending : AppStrings.sendManualInvoice,
              onPressed: controller.submitting.value ? null : controller.submit,
            ),
          ),
        ],
      ),
    );
  }
}
