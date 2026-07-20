import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/widgets/app_text_field.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class AddressScreen extends StatelessWidget {
  const AddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.addressTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AppTextField(label: AppStrings.fullName, hint: AppStrings.enterFullName, icon: Icons.person_outline),
            SizedBox(height: 16),
            AppTextField(label: AppStrings.streetAddress, hint: AppStrings.streetAddress, icon: Icons.home_outlined),
            SizedBox(height: 16),
            AppTextField(label: AppStrings.city, hint: AppStrings.city, icon: Icons.location_city_outlined),
            SizedBox(height: 16),
            AppTextField(label: AppStrings.postalCode, hint: AppStrings.postalCode, icon: Icons.markunread_mailbox_outlined),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: GradientButton(label: AppStrings.saveAddress, onPressed: () => Get.back()),
        ),
      ),
    );
  }
}
