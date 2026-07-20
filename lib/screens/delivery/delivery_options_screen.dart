import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/delivery_options_controller.dart';
import 'package:matchy_matchy/core/data/delivery_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/controllers/cart_controller.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';
import 'package:matchy_matchy/core/widgets/delivery_location_chooser.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class DeliveryOptionsScreen extends GetView<DeliveryOptionsController> {
  const DeliveryOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<DeliveryOptionsController>()) {
      Get.put(DeliveryOptionsController());
    }

    if (CartController.instance.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.deliveryOptions)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppStrings.cartEmpty, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 16),
                GradientButton(
                  label: AppStrings.continueShopping,
                  onPressed: controller.goBack,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Obx(() {
      final _ = controller.reloadTick.value;
      final __ = controller.locationTick.value;
      final analysis = controller.currentAnalysis;
      final canContinue = controller.canContinue;

      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.deliveryOptions)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HowItWorksCard(),
              const SizedBox(height: 20),
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
                    compact: true,
                  );
                },
              ),
              if (analysis.needsCoordination) ...[
                const SizedBox(height: 20),
                if (DeliverySession.interGovCoordinated)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${AppStrings.coordinationDone} — ${DeliverySession.coordinatedTimeSlot}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: DeliverySession.hasSavedLocation ? controller.openCoordinateDelivery : null,
                    icon: const Icon(Icons.phone_in_talk),
                    label: Text(AppStrings.coordinateDelivery),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: AppColors.warning,
                      side: BorderSide(color: AppColors.warning),
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              _SummaryRow(label: AppStrings.subtotal, value: CurrencyFormatter.format(controller.subtotal)),
              _SummaryRow(label: AppStrings.deliveryFee, value: CurrencyFormatter.format(analysis.totalFee)),
              const Divider(height: 24),
              _SummaryRow(label: AppStrings.total, value: CurrencyFormatter.format(controller.total), bold: true),
              if (!DeliverySession.hasSavedLocation && !DeliverySession.locationLoading) ...[
                const SizedBox(height: 12),
                Text(
                  AppStrings.locationRequired,
                  style: TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
              if (DeliverySession.hasSavedLocation && !DeliverySession.hasHomeDescription) ...[
                const SizedBox(height: 12),
                Text(
                  AppStrings.homeDescriptionRequired,
                  style: TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
              if (!canContinue && DeliverySession.hasSavedLocation && analysis.needsCoordination) ...[
                const SizedBox(height: 12),
                Text(
                  AppStrings.coordinationRequired,
                  style: TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 24),
              GradientButton(
                label: AppStrings.continueToPayment,
                onPressed: canContinue ? controller.continueToPayment : null,
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.accent.withValues(alpha: 0.06)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.deliveryHowItWorks, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          _RuleRow(icon: Icons.flash_on, text: AppStrings.deliveryRuleLocal, color: AppColors.success),
          _RuleRow(icon: Icons.location_city, text: AppStrings.deliveryRuleSameGov, color: AppColors.primary),
          _RuleRow(icon: Icons.route, text: AppStrings.deliveryRuleCrossGov, color: AppColors.warning),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textSecondary))),
        ],
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
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400, fontSize: bold ? 18 : 14)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w600, fontSize: bold ? 20 : 14)),
        ],
      ),
    );
  }
}
