import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/my_orders_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/order_invoice_summary.dart';

class MyOrdersScreen extends GetView<MyOrdersController> {
  MyOrdersScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  MyOrdersController get controller {
    final tag = 'my_orders_$embedded';
    if (!Get.isRegistered<MyOrdersController>(tag: tag)) {
      Get.put(MyOrdersController(embedded: embedded), tag: tag);
    }
    return Get.find<MyOrdersController>(tag: tag);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: embedded ? null : AppBar(title: Text(AppStrings.myOrders)),
      body: SafeArea(
        child: Column(
          children: [
            if (embedded)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.myOrders, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    TextButton(
                      onPressed: controller.goToOrderHistory,
                      child: Text(AppStrings.history, style: TextStyle(color: AppColors.accent)),
                    ),
                  ],
                ),
              ),
            Obx(() {
              if (controller.loading.value) {
                return const LinearProgressIndicator(minHeight: 2);
              }
              return const SizedBox.shrink();
            }),
            Expanded(
              child: Obx(() {
                if (controller.loading.value) {
                  return const SizedBox.shrink();
                }
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
                if (controller.orders.isEmpty) {
                  return const Center(child: Text('لا توجد طلبات بعد'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: controller.orders.length,
                  itemBuilder: (_, i) {
                    final order = controller.orders[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            InkWell(
                              onTap: () => controller.openOrder(order),
                              borderRadius: BorderRadius.circular(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${AppStrings.order} ${order.orderCode}',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      _StatusChip(status: order.statusLabel),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(order.date, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                  if (order.itemsLabel.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      order.itemsLabel,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            OrderInvoiceSummary(order: order, compact: true, showEstimatedTime: true),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    if (status == AppStrings.delivered || status == 'مكتمل') {
      color = AppColors.success;
    } else if (status == AppStrings.inTransit ||
        status == 'الكابتن في الطريق إليك' ||
        status == 'قيد التوصيل') {
      color = AppColors.accent;
    } else {
      color = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
