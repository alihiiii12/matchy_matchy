import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.helpSupport)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(leading: Icon(Icons.help_outline, color: AppColors.primary), title: Text(AppStrings.faq)),
          ListTile(leading: Icon(Icons.chat_outlined, color: AppColors.primary), title: Text(AppStrings.liveChat)),
          ListTile(leading: Icon(Icons.email_outlined, color: AppColors.primary), title: Text(AppStrings.emailSupport)),
          ListTile(leading: Icon(Icons.phone_outlined, color: AppColors.primary), title: Text(AppStrings.callUs)),
        ],
      ),
    );
  }
}
