import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/checkout_address_controller.dart';
import 'package:matchy_matchy/core/data/delivery_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';
import 'package:matchy_matchy/core/widgets/delivery_location_chooser.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class CheckoutAddressScreen extends GetView<CheckoutAddressController> {
  const CheckoutAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.checkoutAddressTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    AppStrings.checkoutAddressSubtitle,
                    style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Obx(
                    () {
                      final _ = controller.locationTick.value;
                      return DeliveryLocationChooser(
                        locationReady: controller.locationReady.value,
                        locationLoading: controller.locationLoading.value,
                        selectedAddress: controller.deliveryAddressSummary.value,
                        governorateLabel: controller.governorateSummary.value,
                        locationRevision: controller.locationTick.value,
                        onHomeDescriptionChanged: () => controller.locationTick.value++,
                        onUseMyLocation: controller.useMyLocation,
                        onPickOtherLocation: controller.pickOtherLocation,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(AppStrings.couponCode, style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Obx(() {
                    final applied = controller.couponApplied.value;
                    final applying = controller.applyingCoupon.value;
                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller.couponController,
                            textCapitalization: TextCapitalization.characters,
                            enabled: !applied && !applying,
                            decoration: InputDecoration(
                              hintText: AppStrings.enterCouponCode,
                              filled: true,
                              fillColor: AppColors.inputFill,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              errorText: controller.couponError.value,
                            ),
                            onChanged: (_) => controller.couponError.value = null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (applied)
                          IconButton(
                            onPressed: controller.removeCoupon,
                            icon: const Icon(Icons.close, color: AppColors.error),
                            tooltip: AppStrings.removeCoupon,
                          )
                        else
                          FilledButton(
                            onPressed: applying ? null : controller.applyCoupon,
                            child: applying
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(AppStrings.applyCoupon),
                          ),
                      ],
                    );
                  }),
                  Obx(() {
                    if (!controller.couponApplied.value) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          '${AppStrings.couponApplied}: ${DeliverySession.appliedCouponCode} (${controller.discountPercent}%)',
                          style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 24),
                  _SummaryRow(label: AppStrings.subtotal, value: CurrencyFormatter.format(controller.subtotal)),
                  _SummaryRow(
                    label: AppStrings.deliveryFee,
                    value: AppStrings.deliveryFeePendingAdmin,
                  ),
                  Obx(
                    () => controller.checkoutDiscount.value > 0
                        ? _SummaryRow(
                            label: AppStrings.discount,
                            value: '- ${CurrencyFormatter.format(controller.checkoutDiscount.value)}',
                          )
                        : const SizedBox.shrink(),
                  ),
                  const Divider(height: 24),
                  Obx(
                    () => _SummaryRow(
                      label: AppStrings.total,
                      value: CurrencyFormatter.format(controller.checkoutTotal.value),
                      bold: true,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: GradientButton(label: AppStrings.continueToPayment, onPressed: controller.continueToPayment),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500, fontSize: bold ? 18 : 14)),
        ],
      ),
    );
  }
}
