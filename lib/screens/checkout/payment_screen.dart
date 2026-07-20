import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/payment_controller.dart';
import 'package:matchy_matchy/core/data/delivery_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/services/delivery_service.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';
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
      final pickingProof = controller.pickingProof.value;
      final proof = controller.paymentProof.value;
      final proofName = controller.paymentProofName.value;
      final proofIsImage = controller.paymentProofIsImage;
      final showShamCashProof = paymentMethod == 'sham_cash' && payable > 0;

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
                          title: AppStrings.cashOnDelivery,
                          subtitle: AppStrings.cashOnDeliveryDesc,
                          icon: Icons.payments_outlined,
                          selected: paymentMethod == 'cash_on_delivery',
                          onTap: paying ? null : () => controller.selectPaymentMethod('cash_on_delivery'),
                        ),
                        if (showShamCashProof) ...[
                          const SizedBox(height: 16),
                          const ShamCashBarcodeCard(),
                          const SizedBox(height: 16),
                          _PaymentProofSection(
                            proof: proof,
                            fileName: proofName,
                            isImage: proofIsImage,
                            picking: pickingProof,
                            onPick: paying || pickingProof ? null : controller.pickPaymentProof,
                            onClear: proof == null || paying ? null : controller.clearPaymentProof,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: GradientButton(
                    label: paying
                        ? 'جاري تأكيد الطلب...'
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
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('جاري إرسال طلبك...'),
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

class _PaymentProofSection extends StatelessWidget {
  const _PaymentProofSection({
    required this.proof,
    required this.fileName,
    required this.isImage,
    required this.picking,
    required this.onPick,
    required this.onClear,
  });

  final File? proof;
  final String? fileName;
  final bool isImage;
  final bool picking;
  final VoidCallback? onPick;
  final VoidCallback? onClear;

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
          Text(AppStrings.paymentProofTitle, style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(AppStrings.paymentProofHint, style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
          const SizedBox(height: 12),
          if (proof != null) ...[
            if (isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(proof!, height: 180, width: double.infinity, fit: BoxFit.cover),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        fileName ?? proof!.path.split(Platform.pathSeparator).last,
                        style: TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: onClear, child: Text(AppStrings.changePaymentFile)),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: picking
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload_file_outlined),
                label: Text(picking ? 'جاري الاختيار...' : AppStrings.pickPaymentFile),
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
              SizedBox(width: 8),
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
