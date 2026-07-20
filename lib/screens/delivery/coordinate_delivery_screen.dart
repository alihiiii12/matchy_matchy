import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/coordinate_delivery_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class CoordinateDeliveryScreen extends GetView<CoordinateDeliveryController> {
  const CoordinateDeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CoordinateDeliveryController>()) {
      Get.put(CoordinateDeliveryController());
    }

    final crossItems = controller.crossItems;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.coordinateDeliveryTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.coordinateDeliveryDesc,
                      style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (crossItems.isNotEmpty) ...[
              _InfoLine(Icons.store, '${AppStrings.sellerLocation}: ${crossItems.first.sellerGovernorate.name}'),
              _InfoLine(Icons.home, '${AppStrings.yourGovernorate}: ${crossItems.first.buyerGovernorate.name}'),
              _InfoLine(
                Icons.straighten,
                '${AppStrings.distance}: ${crossItems.map((i) => i.distanceKm).reduce((a, b) => a > b ? a : b).round()} ${AppStrings.km}',
              ),
              _InfoLine(Icons.access_time, '${AppStrings.estimatedArrival}: ${crossItems.first.etaLabel}'),
              const SizedBox(height: 20),
            ],
            Text(AppStrings.agreedTime, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            Obx(
              () => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CoordinateDeliveryController.timeSlots.map((slot) {
                  final selected = controller.timeSlot.value == slot;
                  return ChoiceChip(
                    label: Text(slot),
                    selected: selected,
                    onSelected: (_) => controller.selectTimeSlot(slot),
                    selectedColor: AppColors.accent.withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller.noteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: AppStrings.addNote,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: controller.contactDeliveryTeam,
              icon: const Icon(Icons.phone),
              label: Text(AppStrings.contactDeliveryTeam),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                foregroundColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: AppStrings.confirmCoordination,
              onPressed: controller.confirm,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}
