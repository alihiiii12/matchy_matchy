import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/payment_controller.dart';
import 'package:matchy_matchy/core/data/delivery_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/services/delivery_service.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';
import 'package:matchy_matchy/core/widgets/al_baraka_cards.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';
import 'package:matchy_matchy/core/widgets/sham_cash_barcode.dart';

class PaymentScreen extends GetView<PaymentController> {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final govName = DeliveryService.governorateById(DeliverySession.buyerGovernorateId).name;

    return Obx(() {
      final amount = controller.amount;
      final payable = controller.payableAmount;
      final paymentMethod = controller.paymentMethod.value;
      final paying = controller.paying.value;
      final showShamCash = paymentMethod == 'sham_cash' && payable > 0;
      final showAlBaraka = paymentMethod == 'al_baraka' && payable > 0;
      final showManualTransfer = showShamCash || showAlBaraka;

      return Stack(
        children: [
          Scaffold(
            appBar: AppBar(title: Text(AppStrings.payment)),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AddressSummary(
                          governorate: govName,
                          city: DeliverySession.city,
                          area: DeliverySession.areaName,
                          home: DeliverySession.homeDescription,
                        ),
                        if (DeliverySession.discountAmount > 0) ...[
                          const SizedBox(height: 16),
                          _OrderAmountSummary(amount: amount),
                        ],
                        const SizedBox(height: 20),
                        Text(AppStrings.paymentMethod, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 12),
                        _PaymentOption(
                          title: AppStrings.shamCash,
                          subtitle: AppStrings.shamCashDesc,
                          icon: Icons.qr_code_2,
                          selected: paymentMethod == 'sham_cash',
                          onTap: paying ? null : () => controller.selectPaymentMethod('sham_cash'),
                        ),
                        _PaymentOption(
                          title: AppStrings.alBaraka,
                          subtitle: AppStrings.alBarakaDesc,
                          icon: Icons.account_balance_outlined,
                          selected: paymentMethod == 'al_baraka',
                          onTap: paying ? null : () => controller.selectPaymentMethod('al_baraka'),
                        ),
                        _PaymentOption(
                          title: AppStrings.cashOnDelivery,
                          subtitle: AppStrings.cashOnDeliveryDesc,
                          icon: Icons.payments_outlined,
                          selected: paymentMethod == 'cash_on_delivery',
                          onTap: paying ? null : () => controller.selectPaymentMethod('cash_on_delivery'),
                        ),
                        if (showShamCash) ...[
                          const SizedBox(height: 16),
                          const ShamCashBarcodeCard(),
                          const SizedBox(height: 16),
                          _ShamCashTransferForm(controller: controller, enabled: !paying),
                        ],
                        if (showAlBaraka) ...[
                          const SizedBox(height: 16),
                          const AlBarakaCards(),
                          const SizedBox(height: 16),
                          _ShamCashTransferForm(controller: controller, enabled: !paying),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: GradientButton(
                    label: paying
                        ? AppStrings.verifyingPayment
                        : showManualTransfer
                            ? '${AppStrings.verifyShamCash} · ${CurrencyFormatter.format(payable)}'
                            : '${AppStrings.confirmOrder} ${CurrencyFormatter.format(payable)}',
                    onPressed: paying ? null : () => controller.confirmOrder(),
                  ),
                ),
              ],
            ),
          ),
          if (paying)
            Container(
              color: Colors.black26,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(AppStrings.sendingOrder),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _ShamCashTransferForm extends StatelessWidget {
  const _ShamCashTransferForm({required this.controller, required this.enabled});

  final PaymentController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.shamCashTransferDetails, style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            AppStrings.shamCashTransferHint,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller.senderAccountCtrl,
            enabled: enabled,
            decoration: InputDecoration(
              labelText: AppStrings.shamSenderAccount,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.surface,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.transferNameCtrl,
            enabled: enabled,
            decoration: InputDecoration(
              labelText: AppStrings.shamTransferName,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.surface,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.transferRefCtrl,
            enabled: enabled,
            decoration: InputDecoration(
              labelText: AppStrings.shamTransferRef,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.surface,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.transferAmountCtrl,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: AppStrings.shamTransferAmount,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.surface,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderAmountSummary extends StatelessWidget {
  const _OrderAmountSummary({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _AmountRow(label: AppStrings.subtotal, value: CurrencyFormatter.format(DeliverySession.checkoutSubtotal)),
          _AmountRow(label: AppStrings.deliveryFee, value: AppStrings.deliveryFeePendingAdmin),
          if (DeliverySession.hasAppliedCoupon)
            _AmountRow(
              label: '${AppStrings.discount} (${DeliverySession.appliedCouponCode})',
              value: '- ${CurrencyFormatter.format(DeliverySession.discountAmount)}',
            ),
          const Divider(height: 20),
          _AmountRow(label: AppStrings.total, value: CurrencyFormatter.format(amount), bold: true),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.value, this.bold = false});

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
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }
}

class _AddressSummary extends StatelessWidget {
  const _AddressSummary({
    required this.governorate,
    required this.city,
    required this.area,
    required this.home,
  });

  final String governorate;
  final String city;
  final String area;
  final String home;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(AppStrings.deliveryAddress, style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text('$governorate — $city — $area', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(home, style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? AppColors.accent : AppColors.border, width: selected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: ListTile(
          leading: Icon(icon, color: AppColors.primary),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
          trailing: selected ? const Icon(Icons.check_circle, color: AppColors.accent) : null,
        ),
      ),
    );
  }
}
