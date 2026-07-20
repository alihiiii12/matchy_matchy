import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/my_deliveries_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/delivery.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class MyDeliveriesScreen extends GetView<MyDeliveriesController> {
  MyDeliveriesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  MyDeliveriesController get controller {
    final tag = 'my_deliveries_$embedded';
    if (!Get.isRegistered<MyDeliveriesController>(tag: tag)) {
      Get.put(MyDeliveriesController(embedded: embedded), tag: tag);
    }
    return Get.find<MyDeliveriesController>(tag: tag);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: embedded
            ? null
            : AppBar(
                title: Text(AppStrings.myDeliveries),
                bottom: TabBar(
                  tabs: [
                    Tab(text: AppStrings.activeDeliveries),
                    Tab(text: AppStrings.completedDeliveries),
                  ],
                ),
              ),
        body: SafeArea(
          child: Column(
            children: [
              if (embedded) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.myDeliveries, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                      TextButton(
                        onPressed: controller.goToMyOrders,
                        child: Text(AppStrings.myOrders),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  tabs: [
                    Tab(text: AppStrings.activeDeliveries),
                    Tab(text: AppStrings.completedDeliveries),
                  ],
                ),
              ],
              Obx(() {
                if (controller.loading.value) {
                  return const LinearProgressIndicator(minHeight: 2);
                }
                return const SizedBox.shrink();
              }),
              Expanded(
                child: Obx(() {
                  final loadError = controller.error.value;
                  if (loadError != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(loadError, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            TextButton(onPressed: controller.load, child: const Text('إعادة المحاولة')),
                          ],
                        ),
                      ),
                    );
                  }
                  return TabBarView(
                    children: [
                      _DeliveryList(
                        deliveries: controller.active,
                        emptyMessage: AppStrings.noActiveDeliveries,
                        onOpen: controller.openDelivery,
                        onConfirmReceipt: controller.confirmReceipt,
                      ),
                      _DeliveryList(
                        deliveries: controller.completed,
                        emptyMessage: AppStrings.completedDeliveries,
                        onOpen: controller.openDelivery,
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryList extends StatelessWidget {
  const _DeliveryList({
    required this.deliveries,
    required this.emptyMessage,
    required this.onOpen,
    this.onConfirmReceipt,
  });

  final List<DeliveryOrder> deliveries;
  final String emptyMessage;
  final void Function(DeliveryOrder) onOpen;
  final Future<void> Function(DeliveryOrder)? onConfirmReceipt;

  @override
  Widget build(BuildContext context) {
    if (deliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: deliveries.length,
      itemBuilder: (_, i) => _DeliveryCard(
        delivery: deliveries[i],
        onOpen: onOpen,
        onConfirmReceipt: onConfirmReceipt,
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({
    required this.delivery,
    required this.onOpen,
    this.onConfirmReceipt,
  });

  final DeliveryOrder delivery;
  final void Function(DeliveryOrder) onOpen;
  final Future<void> Function(DeliveryOrder)? onConfirmReceipt;

  Color get _statusColor {
    switch (delivery.status) {
      case DeliveryStatus.delivered:
        return AppColors.success;
      case DeliveryStatus.onTheWay:
      case DeliveryStatus.arrived:
        return AppColors.accent;
      case DeliveryStatus.awaitingCoordination:
        return AppColors.warning;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onOpen(delivery),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(delivery.statusLabel, style: TextStyle(color: _statusColor, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                  const Spacer(),
                  Text('${AppStrings.order} ${delivery.orderId}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              Text(delivery.itemsSummary, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(delivery.modeLabel, style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(delivery.address, style: TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: delivery.progress,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${AppStrings.estimatedArrival}: ${delivery.estimatedTime}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text(CurrencyFormatter.format(delivery.total), style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              if (delivery.awaitingCustomerConfirmation && onConfirmReceipt != null) ...[
                const SizedBox(height: 12),
                GradientButton(
                  label: AppStrings.confirmReceipt,
                  height: 44,
                  onPressed: () => onConfirmReceipt!(delivery),
                ),
              ] else if (delivery.status != DeliveryStatus.delivered) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => onOpen(delivery),
                    icon: Icon(
                      delivery.status == DeliveryStatus.awaitingCoordination ? Icons.phone_in_talk : Icons.my_location,
                      size: 18,
                    ),
                    label: Text(
                      delivery.status == DeliveryStatus.awaitingCoordination
                          ? AppStrings.coordinateNow
                          : AppStrings.trackDelivery,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
