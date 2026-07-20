import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/delivery_tracking_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/delivery.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class DeliveryTrackingScreen extends GetView<DeliveryTrackingController> {
  const DeliveryTrackingScreen({super.key, this.delivery});

  final DeliveryOrder? delivery;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<DeliveryTrackingController>() && delivery != null) {
      Get.put(DeliveryTrackingController(delivery!));
    }

    return Obx(() {
      final d = controller.delivery.value ?? delivery;
      if (d == null) {
        return Scaffold(
          appBar: AppBar(title: Text(AppStrings.deliveryTracking)),
          body: Center(child: Text(AppStrings.noActiveDeliveries)),
        );
      }

      final isAwaiting = d.status == DeliveryStatus.awaitingCoordination;
      final needsConfirm = d.awaitingCustomerConfirmation;
      final showLiveTracking = !needsConfirm && d.status != DeliveryStatus.delivered;

      final steps = isAwaiting
          ? [
              (AppStrings.orderPlaced, true),
              (AppStrings.awaitingCoordination, true),
              (AppStrings.pickedUpFromStore, false),
              (AppStrings.onTheWayToYou, false),
              (AppStrings.orderDelivered, false),
            ]
          : [
              (AppStrings.preparingOrder, d.status.index >= DeliveryStatus.preparing.index),
              (AppStrings.pickedUpFromStore, d.status.index >= DeliveryStatus.pickedUp.index),
              (AppStrings.onTheWayToYou, d.status.index >= DeliveryStatus.onTheWay.index),
              (AppStrings.driverArrived, d.status.index >= DeliveryStatus.arrived.index),
              (AppStrings.orderDelivered, d.status.index >= DeliveryStatus.delivered.index),
            ];

      return Scaffold(
        appBar: AppBar(title: Text(needsConfirm ? AppStrings.confirmReceiptInApp : AppStrings.deliveryTracking)),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (needsConfirm) ...[
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.accent),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.deliveryStoppedAwaitingConfirm,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.confirmReceiptMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        Obx(
                          () => GradientButton(
                            label: AppStrings.confirmReceipt,
                            onPressed: controller.confirming.value ? null : controller.confirmReceipt,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (showLiveTracking) ...[
                Container(
                  height: 220,
                  width: double.infinity,
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.accent.withValues(alpha: 0.1)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.map_outlined, size: 80, color: AppColors.primary.withValues(alpha: 0.3)),
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${(d.progress * 100).round()}%',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time, size: 16, color: AppColors.accent),
                              const SizedBox(width: 6),
                              Text(
                                '${AppStrings.estimatedArrival}: ${d.estimatedTime}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        needsConfirm ? Icons.check_circle_outline : Icons.local_shipping,
                        color: Colors.white,
                        size: 36,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.statusLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                            Text('${AppStrings.order} ${d.orderId}', style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (isAwaiting && d.sellerGovernorate != null && d.buyerGovernorate != null) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    color: AppColors.warning.withValues(alpha: 0.06),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.coordinateDeliveryDesc, style: const TextStyle(fontSize: 13, height: 1.5)),
                          const SizedBox(height: 12),
                          _DetailRow(AppStrings.sellerLocation, d.sellerGovernorate!.name),
                          _DetailRow(AppStrings.yourGovernorate, d.buyerGovernorate!.name),
                          if (d.distanceKm != null)
                            _DetailRow(AppStrings.distance, '${d.distanceKm!.round()} ${AppStrings.km}'),
                          const SizedBox(height: 12),
                          GradientButton(
                            label: AppStrings.contactDeliveryTeam,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppStrings.deliveryTeamPhone)),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              if (showLiveTracking && d.driver != null) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(AppStrings.driverInfo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                            child: const Icon(Icons.person, color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.driver!.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text('${d.driver!.vehicle} • ${d.driver!.plateNumber}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 14),
                                    Text(' ${d.driver!.rating}', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton.filled(
                            onPressed: () {},
                            icon: const Icon(Icons.phone, color: Colors.white),
                            style: IconButton.styleFrom(backgroundColor: AppColors.success),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(AppStrings.deliveryProgress, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              const SizedBox(height: 16),
              ...steps.map((step) => _StepTile(title: step.$1, done: step.$2)),

              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(AppStrings.orderSummary, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _DetailRow(AppStrings.deliveryAddressLabel, d.address),
                        _DetailRow(AppStrings.deliveryType, d.modeLabel),
                        if (d.sellerGovernorate != null)
                          _DetailRow(AppStrings.sellerLocation, d.sellerGovernorate!.name),
                        _DetailRow(AppStrings.deliveryFee, CurrencyFormatter.format(d.deliveryFee)),
                        _DetailRow(AppStrings.total, CurrencyFormatter.format(d.total), bold: true),
                      ],
                    ),
                  ),
                ),
              ),
              if (showLiveTracking && d.driver != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: GradientButton(
                    label: AppStrings.callDriver,
                    onPressed: () {},
                  ),
                )
              else
                const SizedBox(height: 32),
            ],
          ),
        ),
      );
    });
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.title, required this.done});

  final String title;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: done ? AppColors.accent : AppColors.border,
              shape: BoxShape.circle,
            ),
            child: done ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                color: done ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: AppColors.textSecondary))),
          Expanded(flex: 3, child: Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500))),
        ],
      ),
    );
  }
}
