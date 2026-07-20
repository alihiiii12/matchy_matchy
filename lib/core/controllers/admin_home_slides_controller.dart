import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:get/get.dart' hide Response, MultipartFile;
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/home_slide_repository.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class AdminHomeSlidesController extends GetxController {
  AdminHomeSlidesController({required this.slideType});

  final String slideType;

  final loading = true.obs;
  final actionLoadingId = RxnString();
  final slides = <Map<String, dynamic>>[].obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final res = await ApiClient.instance.getJson(
        '/admin/home-slides',
        query: {'type': slideType},
      );
      final body = res.data!;
      final list = body['data'] as List<dynamic>? ?? [];
      slides.value = list.cast<Map<String, dynamic>>();
      if (body['setup_required'] == true && body['message'] is String) {
        error.value = body['message'] as String;
      }
    } on DioException catch (e) {
      error.value = apiFriendlyError(e, fallback: AppStrings.loadHomeSlidesFailed);
    } finally {
      loading.value = false;
    }
  }

  bool isActionLoading(String id) => actionLoadingId.value == id;

  Future<void> openCreateForm() async {
    final saved = await Get.toNamed(
      AppRoutes.adminHomeSlideForm,
      arguments: {'type': slideType},
    );
    if (saved == true) await load();
  }

  Future<void> openEditForm(Map<String, dynamic> slide) async {
    final saved = await Get.toNamed(
      AppRoutes.adminHomeSlideForm,
      arguments: {'type': slideType, 'slide': slide},
    );
    if (saved == true) await load();
  }

  Future<void> deleteSlide(Map<String, dynamic> slide) async {
    final title = slide['title'] as String? ?? '';
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.deleteHomeSlide),
        content: Text(AppStrings.deleteHomeSlideConfirm.replaceFirst('{title}', title)),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(AppStrings.delete, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final id = slide['id'] as String;
    actionLoadingId.value = id;
    try {
      await ApiClient.instance.deleteJson('/admin/home-slides/$id');
      await HomeSlideRepository.instance.reload();
      _showMessage(AppStrings.homeSlideDeleted, success: true);
      await load();
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    } finally {
      actionLoadingId.value = null;
    }
  }

  void _showMessage(String message, {required bool success}) {
    showMatchySnackBar(
      message: message,
      type: success ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }
}

class AdminHomeSlidesBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AdminHomeSlidesController(slideType: 'category'), tag: 'category');
    Get.put(AdminHomeSlidesController(slideType: 'brand'), tag: 'brand');
  }
}
