import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/widgets/app_text_field.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class AddCardScreen extends StatelessWidget {
  const AddCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.addNewCard)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AppTextField(label: AppStrings.cardNumber, hint: '1234 5678 9012 3456', icon: Icons.credit_card),
            SizedBox(height: 16),
            AppTextField(label: AppStrings.cardHolder, hint: 'اسم حامل البطاقة', icon: Icons.person_outline),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: AppTextField(label: AppStrings.expiry, hint: 'MM/YY', icon: Icons.calendar_today_outlined)),
                SizedBox(width: 16),
                Expanded(child: AppTextField(label: AppStrings.cvv, hint: '123', icon: Icons.lock_outline, obscureText: true)),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: GradientButton(label: AppStrings.addCard, onPressed: () => Get.back()),
        ),
      ),
    );
  }
}
