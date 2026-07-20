import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/data/mock_data.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.messagesTitle)),
      body: ListView.builder(
        itemCount: MockData.messages.length,
        itemBuilder: (_, i) {
          final (name, preview, time, unread) = MockData.messages[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.accent.withValues(alpha: 0.2),
              child: Text(name[0], style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
            title: Text(name, style: TextStyle(fontWeight: unread ? FontWeight.w700 : FontWeight.w500)),
            subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(time, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                if (unread)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                  ),
              ],
            ),
            onTap: () => Get.toNamed(AppRoutes.messageDetail, arguments: name),
          );
        },
      ),
    );
  }
}
