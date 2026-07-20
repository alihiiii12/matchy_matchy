import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';

class LegalPoliciesScreen extends StatelessWidget {
  const LegalPoliciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.legalPolicies)),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Text(
            'شروط الخدمة\n\nباستخدامك روزي تاج، فإنك توافق على شروطنا وأحكامنا...\n\n'
            'سياسة الخصوصية\n\nنحترم خصوصيتك ونحمي بياناتك الشخصية...',
            style: TextStyle(height: 1.6),
          ),
        ),
      ),
    );
  }
}
