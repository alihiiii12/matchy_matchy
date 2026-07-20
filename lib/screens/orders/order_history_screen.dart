import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/order_history_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';

class OrderHistoryScreen extends GetView<OrderHistoryController> {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<OrderHistoryController>()) {
      Get.put(OrderHistoryController());
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.orderHistory)),
      body: Column(
        children: [
          Obx(() {
            if (controller.loading.value) {
              return const LinearProgressIndicator(minHeight: 2);
            }
            return const SizedBox.shrink();
          }),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const Center(child: CircularProgressIndicator());
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
                return const Center(child: Text('لا يوجد سجل طلبات'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: controller.orders.length,
                itemBuilder: (_, i) {
                  final order = controller.orders[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text('${AppStrings.order} ${order.orderCode}'),
                      subtitle: Text('${order.date} • ${CurrencyFormatter.format(order.total)}'),
                      trailing: Text(order.statusLabel, style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
