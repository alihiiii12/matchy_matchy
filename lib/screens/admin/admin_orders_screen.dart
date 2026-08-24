import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/admin_orders_controller.dart';
import 'package:matchy_matchy/core/data/body_measurements.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';
import 'package:matchy_matchy/core/widgets/notification_badge_icon.dart';

class AdminOrdersScreen extends GetView<AdminOrdersController> {
  const AdminOrdersScreen({super.key, this.embedded = false});

  final bool embedded;

  static const embeddedTagForRefresh = 'admin_orders_embedded';

  @override
  AdminOrdersController get controller {
    if (embedded) {
      if (!Get.isRegistered<AdminOrdersController>(tag: embeddedTagForRefresh)) {
        Get.put(AdminOrdersController(), tag: embeddedTagForRefresh);
      }
      return Get.find<AdminOrdersController>(tag: embeddedTagForRefresh);
    }
    return Get.find<AdminOrdersController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: embedded
          ? null
          : AppBar(
              title: Text(AppStrings.adminOrders),
              actions: [
                const NotificationBadgeIcon(),
                Obx(() {
                  if (controller.archiving.value) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }
                  return IconButton(
                    tooltip: AppStrings.archiveOrders,
                    onPressed: controller.archiveOrders,
                    icon: const Icon(Icons.archive_outlined),
                  );
                }),
                IconButton(onPressed: controller.load, icon: const Icon(Icons.refresh)),
              ],
            ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (embedded)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.adminOrders,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const NotificationBadgeIcon(),
                    Obx(() {
                      if (controller.archiving.value) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      return IconButton(
                        tooltip: AppStrings.archiveOrders,
                        onPressed: controller.archiveOrders,
                        icon: const Icon(Icons.archive_outlined),
                      );
                    }),
                    IconButton(onPressed: controller.load, icon: const Icon(Icons.refresh)),
                  ],
                ),
              ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null) {
          return Center(child: Text(controller.error.value!, style: TextStyle(color: AppColors.error)));
        }
        if (controller.orders.isEmpty) {
          return Center(child: Text(AppStrings.noOrdersYet));
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.orders.length,
            itemBuilder: (_, i) {
              final order = controller.orders[i];
              return _OrderCard(
                order: order,
                onSetDeliveryTime: () => controller.showDeliveryTimeDialog(order),
                onApprovePayment: () => controller.approvePayment(order),
                onRejectPayment: () => controller.confirmRejectPayment(order),
                onRejectOrder: () => controller.confirmRejectOrder(order),
                onConfirmDelivered: () => controller.confirmDriverDelivery(order),
                onTrackDriver: () => controller.openDriverTracking(order),
                onViewCustomerLocation: () => controller.openCustomerLocation(order),
                onTapTotal: () {
                  final id = order['id'] as int?;
                  if (id == null) return;
                  final delivery = order['delivery'] as Map<String, dynamic>?;
                  final canTrack = delivery?['can_track_driver'] == true;
                  if (canTrack) {
                    controller.openDriverTracking(order);
                  } else {
                    controller.focusOrder(id);
                  }
                },
                highlight: controller.highlightOrderId.value == order['id'],
                onAssignDriver: () => controller.assignDriver(order),
                onViewPaymentProof: () {
                  final url = order['payment_proof_url'] as String?;
                  if (url != null && url.isNotEmpty) {
                    controller.showPaymentProof(url);
                  }
                },
              );
            },
          ),
        );
    });
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onSetDeliveryTime,
    required this.onApprovePayment,
    required this.onRejectPayment,
    required this.onRejectOrder,
    required this.onConfirmDelivered,
    required this.onTrackDriver,
    required this.onViewCustomerLocation,
    required this.onTapTotal,
    required this.onViewPaymentProof,
    required this.onAssignDriver,
    this.highlight = false,
  });

  final Map<String, dynamic> order;
  final VoidCallback onSetDeliveryTime;
  final VoidCallback onApprovePayment;
  final VoidCallback onRejectPayment;
  final VoidCallback onRejectOrder;
  final VoidCallback onConfirmDelivered;
  final VoidCallback onTrackDriver;
  final VoidCallback onViewCustomerLocation;
  final VoidCallback onTapTotal;
  final VoidCallback onViewPaymentProof;
  final VoidCallback onAssignDriver;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final customer = order['customer'] as Map<String, dynamic>?;
    final delivery = order['delivery'] as Map<String, dynamic>?;
    final items = order['items'] as List<dynamic>? ?? [];
    final status = order['status'] as String? ?? '';
    final paymentMethod = order['payment_method'] as String? ?? '';
    final proofUrl = order['payment_proof_url'] as String?;
    final hasTransfer = (order['sender_account_name'] as String?)?.trim().isNotEmpty == true &&
        (order['transfer_ref'] as String?)?.trim().isNotEmpty == true;
    final pendingReview = status == 'pending_review';
    final paymentConfirmed = status == 'payment_confirmed';
    final approved = status == 'approved';
    final awaitingPayment = status == 'awaiting_payment';
    final awaitingReceipt = status == 'awaiting_receipt';
    final isCancelled = status == 'cancelled';
    final canReject = !isCancelled && status != 'delivered';
    final isManualTransfer = paymentMethod == 'sham_cash' || paymentMethod == 'al_baraka';
    final canReviewShamCash = isManualTransfer &&
        (pendingReview || awaitingPayment) &&
        (hasTransfer || (proofUrl != null && proofUrl.isNotEmpty));
    final deliveryStatus = delivery?['status'] as String?;
    final driverReportedDelivery = delivery?['driver_delivery_reported'] == true ||
        deliveryStatus == 'driver_delivered';
    final canConfirmDriverDelivery = delivery?['can_confirm_driver_delivery'] == true ||
        (driverReportedDelivery && !isCancelled && status != 'delivered');
    final canTrackDriver = delivery?['can_track_driver'] == true ||
        (delivery?['driver_user_id'] != null &&
            !isCancelled &&
            status != 'delivered' &&
            deliveryStatus != 'delivered');
    final deliveryTimeSent = AdminOrdersController.isDeliveryTimeSent(order);
    final canSendDeliveryTime = !isCancelled &&
        !deliveryTimeSent &&
        (isManualTransfer
            ? paymentConfirmed
            : (pendingReview || paymentConfirmed || awaitingPayment || status == 'processing'));
    final hasCustomerLocation = order['has_customer_location'] as bool? ??
        (delivery?['has_customer_location'] as bool?) ??
        (order['latitude'] != null && order['longitude'] != null);
    final canAssignDriver = approved &&
        !isCancelled &&
        delivery != null &&
        (delivery['driver_user_id'] == null);
    final driverRejectionReason = delivery?['rejection_reason'] as String?;
    final driverRejectedBy = delivery?['rejected_by_driver_name'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: highlight
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.accent, width: 2),
            )
          : null,
      color: highlight ? AppColors.accent.withValues(alpha: 0.06) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(order['order_code'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                Text(
                  order['payment_method_label'] as String? ?? '',
                  style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (pendingReview) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppStrings.orderPendingReview,
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
            if (approved) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppStrings.orderApproved,
                  style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
            if (driverRejectionReason != null &&
                driverRejectionReason.isNotEmpty &&
                delivery?['driver_user_id'] == null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.driverRejectedDelivery,
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    if (driverRejectedBy != null && driverRejectedBy.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${AppStrings.driverOnMap}: $driverRejectedBy',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${AppStrings.rejectDeliveryJobReason}: $driverRejectionReason',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
            if (paymentConfirmed) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppStrings.paymentConfirmedStatus,
                  style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
            if (awaitingPayment) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppStrings.awaitingPayment,
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
            if (isCancelled) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
              AppStrings.orderCancelled,
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
            if (awaitingReceipt) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
              AppStrings.awaitingCustomerReceipt,
              style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
            if (customer != null) ...[
              const SizedBox(height: 8),
              Text('${customer['name']} — ${customer['email']}', style: TextStyle(color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 8),
            Text(
              '${order['governorate_name']} — ${order['city']} — ${order['area_name']}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if ((order['home_description'] as String?)?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                '${AppStrings.homeDescription}: ${order['home_description']}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
            ],
            const SizedBox(height: 8),
            InkWell(
              onTap: onTapTotal,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text('${AppStrings.total}: ${CurrencyFormatter.format(order['total'] as num)}'),
                    if (canTrackDriver) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.map_outlined, size: 18, color: AppColors.primary),
                    ],
                  ],
                ),
              ),
            ),
            if (items.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in items) ...[
                    Text(
                      '${e['product_name'] ?? e['product_id']} ×${e['quantity']}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    if (e['options'] is Map && (e['options'] as Map).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 6),
                        child: Text(
                          BodyMeasurements.formatMemberOptions(
                            Map<String, dynamic>.from(e['options'] as Map),
                          ),
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.35),
                        ),
                      )
                    else
                      const SizedBox(height: 4),
                  ],
                ],
              ),
            if (delivery != null) ...[
              const SizedBox(height: 8),
              Text(
                '${AppStrings.expectedDelivery}: ${(delivery['estimated_time'] as String?)?.isNotEmpty == true ? delivery['estimated_time'] : AppStrings.deliveryTimePending}',
              ),
            ],
            if (isManualTransfer && hasTransfer) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paymentMethod == 'al_baraka'
                          ? AppStrings.alBarakaReviewBadge
                          : AppStrings.shamCashReviewBadge,
                      style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      paymentMethod == 'al_baraka'
                          ? AppStrings.alBarakaTransferSection
                          : AppStrings.shamCashTransferSection,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text('${AppStrings.shamSenderAccount}: ${order['sender_account_name'] ?? '—'}'),
                    Text('${AppStrings.shamTransferName}: ${order['transfer_name'] ?? '—'}'),
                    Text('${AppStrings.shamTransferRef}: ${order['transfer_ref'] ?? '—'}'),
                    Text('${AppStrings.shamTransferAmount}: ${order['transfer_amount'] ?? '—'}'),
                  ],
                ),
              ),
            ],
            if (proofUrl != null && proofUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onViewPaymentProof,
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(AppStrings.viewPaymentProof),
              ),
            ],
            if (canReviewShamCash) ...[
              const SizedBox(height: 8),
              GradientButton(
                label: AppStrings.approvePayment,
                height: 48,
                onPressed: onApprovePayment,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: onRejectPayment,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Text(AppStrings.rejectPayment, style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
            if (canReject) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: onRejectOrder,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Text(AppStrings.rejectOrder, style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
            if (canSendDeliveryTime) ...[
              const SizedBox(height: 12),
              GradientButton(
                label: AppStrings.setDeliveryTime,
                height: 48,
                onPressed: onSetDeliveryTime,
              ),
            ] else if (deliveryTimeSent && !isCancelled) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        AppStrings.deliveryTimeAlreadySent,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (hasCustomerLocation) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onViewCustomerLocation,
                icon: const Icon(Icons.location_on_outlined),
                label: Text(AppStrings.viewCustomerLocationOnMap),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
            if (canAssignDriver && !hasCustomerLocation) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppStrings.orderCustomerLocationMissing,
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
            if (canAssignDriver) ...[
              const SizedBox(height: 8),
              GradientButton(
                label: AppStrings.assignDriver,
                height: 48,
                onPressed: onAssignDriver,
              ),
            ],
            if (delivery?['driver_name'] != null) ...[
              const SizedBox(height: 8),
              Text(
                '${AppStrings.assignDriver}: ${delivery!['driver_name']}',
                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
            if (canTrackDriver) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onTrackDriver,
                icon: const Icon(Icons.map_outlined),
                label: Text(AppStrings.trackDriverOnMap),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
            if (driverReportedDelivery && !canConfirmDriverDelivery && !isCancelled) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppStrings.driverReportedDeliveryPending,
                  style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
            if (canConfirmDriverDelivery) ...[
              const SizedBox(height: 8),
              GradientButton(
                label: AppStrings.adminConfirmDelivered,
                height: 48,
                onPressed: onConfirmDelivered,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
