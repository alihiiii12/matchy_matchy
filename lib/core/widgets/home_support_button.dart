import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class HomeSupportButton extends StatelessWidget {
  const HomeSupportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppStrings.customerService,
      onPressed: () => Get.toNamed(AppRoutes.helpSupport),
      icon: const Icon(Icons.support_agent_outlined),
    );
  }
}
