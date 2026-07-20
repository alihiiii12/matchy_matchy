import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class MessageDetailScreen extends StatelessWidget {
  const MessageDetailScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _Bubble(text: 'مرحباً! كيف يمكننا مساعدتك اليوم؟', sent: false),
                _Bubble(text: 'لدي سؤال عن طلبي ZDK-2835', sent: true),
                _Bubble(text: 'بالتأكيد! طلبك قيد الشحن ومن المتوقع وصوله غداً.', sent: false),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: AppStrings.typeMessage,
                      filled: true,
                      fillColor: AppColors.inputFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.accent,
                  child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: () {}),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.sent});

  final String text;
  final bool sent;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: sent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: sent ? AppColors.accent : AppColors.inputFill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text, style: TextStyle(color: sent ? Colors.white : AppColors.textPrimary)),
      ),
    );
  }
}
