import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/order_track_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/repositories/order_repository.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/order_invoice_summary.dart';

class OrderTrackScreen extends GetView<OrderTrackController> {
  const OrderTrackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.trackOrderTitle)),
      body: Obx(() {
        final order = controller.order.value;
        if (order == null) {
          return const Center(child: Text('لا توجد بيانات للطلب'));
        }

        final steps = _stepsForStatus(order.status);

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (controller.loading.value) const LinearProgressIndicator(minHeight: 2),
            if (controller.error.value != null) ...[
              const SizedBox(height: 8),
              Text(
                controller.error.value!,
                style: TextStyle(color: AppColors.warning, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppStrings.order} ${order.orderCode}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        Text(order.statusLabel, style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OrderInvoiceSummary(order: order),
            if (order.isShamCashAwaitingRetry) ...[
              const SizedBox(height: 16),
              _RetryShamCashCard(
                orderId: order.id,
                onDone: () => controller.refreshOrder(order.id),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _InfoRow(label: AppStrings.orderDate, value: order.date),
              ),
            ),
            const SizedBox(height: 24),
            Text(AppStrings.orderStatus, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 16),
            ...steps.map((step) => _TrackStep(title: step.$1, subtitle: step.$2, done: step.$3)),
          ],
        );
      }),
    );
  }

  List<(String, String, bool)> _stepsForStatus(String status) {
    final cancelled = status == 'cancelled';
    final awaitingPayment = status == 'awaiting_payment';
    final awaitingReceipt = status == 'awaiting_receipt';
    final delivered = status == 'delivered';
    final outForDelivery = status == 'out_for_delivery' || awaitingReceipt || delivered;
    final processing = !cancelled &&
        !awaitingPayment &&
        (status == 'pending_review' ||
            status == 'processing' ||
            status == 'payment_confirmed' ||
            status == 'approved' ||
            outForDelivery);

    if (cancelled) {
      return [
        (AppStrings.orderPlaced, AppStrings.done, true),
        (AppStrings.orderCancelled, AppStrings.done, true),
      ];
    }

    if (awaitingPayment) {
      return [
        (AppStrings.orderPlaced, AppStrings.done, true),
        (AppStrings.awaitingPayment, AppStrings.pending, true),
        (AppStrings.processing, AppStrings.pending, false),
        (AppStrings.outForDelivery, AppStrings.pending, false),
        (AppStrings.delivered, AppStrings.pending, false),
      ];
    }

    return [
      (AppStrings.orderPlaced, AppStrings.done, true),
      (
        AppStrings.processing,
        processing ? AppStrings.done : AppStrings.pending,
        processing,
      ),
      (
        AppStrings.outForDelivery,
        outForDelivery ? AppStrings.done : AppStrings.pending,
        outForDelivery,
      ),
      if (awaitingReceipt)
        (AppStrings.confirmReceiptInApp, AppStrings.pending, true)
      else
        (
          AppStrings.delivered,
          delivered ? AppStrings.done : AppStrings.pending,
          delivered,
        ),
    ];
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: AppColors.textSecondary))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TrackStep extends StatelessWidget {
  const _TrackStep({required this.title, required this.subtitle, required this.done});

  final String title;
  final String subtitle;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: done ? AppColors.accent : AppColors.border,
              shape: BoxShape.circle,
            ),
            child: done ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: done ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RetryShamCashCard extends StatefulWidget {
  const _RetryShamCashCard({required this.orderId, required this.onDone});

  final int orderId;
  final VoidCallback onDone;

  @override
  State<_RetryShamCashCard> createState() => _RetryShamCashCardState();
}

class _RetryShamCashCardState extends State<_RetryShamCashCard> {
  final _account = TextEditingController();
  final _name = TextEditingController();
  final _ref = TextEditingController();
  final _amount = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _account.dispose();
    _name.dispose();
    _ref.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amount.text.trim().replaceAll(',', ''));
    if (_account.text.trim().isEmpty ||
        _name.text.trim().isEmpty ||
        _ref.text.trim().isEmpty ||
        amount == null ||
        amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.shamTransferAmountRequired)),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await OrderRepository.instance.resubmitShamCashTransfer(
        orderId: widget.orderId,
        senderAccountName: _account.text.trim(),
        transferName: _name.text.trim(),
        transferRef: _ref.text.trim(),
        transferAmount: amount,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.paymentSuccessShamCash)),
      );
      widget.onDone();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.loadFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.rejectPayment, style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.error)),
            const SizedBox(height: 6),
            Text(
              'لم يتم استلام الحوالة. حاول التسديد مرة أخرى.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(controller: _account, decoration: InputDecoration(labelText: AppStrings.shamSenderAccount, border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _name, decoration: InputDecoration(labelText: AppStrings.shamTransferName, border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _ref, decoration: InputDecoration(labelText: AppStrings.shamTransferRef, border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: AppStrings.shamTransferAmount, border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? AppStrings.verifyingPayment : AppStrings.verifyShamCash),
            ),
          ],
        ),
      ),
    );
  }
}
