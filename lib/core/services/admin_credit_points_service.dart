import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';

abstract final class AdminCreditPointsService {
  static Future<bool> creditUser(Map<String, dynamic> user) async {
    final pointsController = TextEditingController();
    final noteController = TextEditingController();

    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text('${AppStrings.creditPoints} — ${user['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pointsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: AppStrings.creditPointsHint),
            ),
            TextField(
              controller: noteController,
              decoration: InputDecoration(labelText: AppStrings.description),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),
          TextButton(onPressed: () => Get.back(result: true), child: Text(AppStrings.save)),
        ],
      ),
    );

    if (ok != true) {
      pointsController.dispose();
      noteController.dispose();
      return false;
    }

    final points = int.tryParse(pointsController.text.trim());
    final note = noteController.text.trim();
    pointsController.dispose();
    noteController.dispose();

    if (points == null || points <= 0) {
      showMatchySnackBar(
        message: AppStrings.creditPointsHint,
        type: AppSnackBarType.error,
      );
      return false;
    }

    try {
      await ApiClient.instance.postJson(
        '/admin/users/${user['id']}/credit-points',
        data: {
          'points': points,
          if (note.isNotEmpty) 'note': note,
        },
      );
      showMatchySnackBar(
        message: AppStrings.creditPointsSuccess,
        type: AppSnackBarType.success,
      );
      return true;
    } on DioException catch (e) {
      showMatchySnackBar(
        message: apiFriendlyError(e),
        type: AppSnackBarType.error,
      );
      return false;
    }
  }
}
