import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class AdminBroadcastNotificationController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final bodyController = TextEditingController();

  final submitting = false.obs;
  final audience = 'all'.obs;

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    submitting.value = true;
    try {
      final res = await ApiClient.instance.postJson(
        '/admin/notifications/broadcast',
        data: {
          'title': titleController.text.trim(),
          'body': bodyController.text.trim(),
          'audience': audience.value,
        },
      );

      final sentCount = res.data?['data']?['sent_count'] as int? ?? 0;

      await Get.dialog<void>(
        AlertDialog(
          title: Text(AppStrings.messageSent),
          content: Text('${AppStrings.messageSentToUsers} ($sentCount)'),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text(AppStrings.done)),
          ],
        ),
        barrierDismissible: false,
      );

      Get.back(result: true);
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    } catch (_) {
      _showMessage(AppStrings.messageSendFailed, success: false);
    } finally {
      submitting.value = false;
    }
  }

  void _showMessage(String message, {required bool success}) {
    showMatchySnackBar(
      message: message,
      type: success ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }

  @override
  void onClose() {
    titleController.dispose();
    bodyController.dispose();
    super.onClose();
  }
}

class AdminBroadcastNotificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AdminBroadcastNotificationController());
  }
}
