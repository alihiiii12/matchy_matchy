import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/main_shell_controller.dart';
import 'package:matchy_matchy/core/data/delivery_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final paymentMethod = ModalRoute.of(context)?.settings.arguments as String? ?? 'cash_on_delivery';
    final message = (paymentMethod == 'sham_cash' || paymentMethod == 'al_baraka')
        ? AppStrings.paymentSuccessShamCash
        : AppStrings.paymentSuccessCod;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 32),
              Text(AppStrings.paymentSuccess, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 48),
              GradientButton(
                label: AppStrings.myOrders,
                onPressed: () {
                  DeliverySession.resetCheckout();
                  Get.offAllNamed(AppRoutes.main);
                  Get.find<MainShellController>().setIndex(2);
                },              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  DeliverySession.resetCheckout();
                  Get.offAllNamed(AppRoutes.main);
                },                child: Text(AppStrings.backToHome, style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
