import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/services/whatsapp_support_service.dart';

class HomeSupportButton extends StatelessWidget {
  const HomeSupportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppStrings.technicalSupport,
      onPressed: WhatsappSupportService.openTechnicalSupport,
      icon: const Icon(Icons.support_agent_outlined),
    );
  }
}
