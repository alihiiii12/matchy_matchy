import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:matchy_matchy/core/data/catalog_meta.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/authenticated_image_loader.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';

abstract final class IdPhotoViewer {
  static Future<void> showAdmin({
    required String resource,
    required int userId,
    required bool front,
    void Function(String message)? onError,
  }) {
    final path = '/admin/$resource/$userId/id-${front ? 'front' : 'back'}';
    return _showBytesDialog(
      loader: () => AuthenticatedImageLoader.loadBytes(path),
      onError: onError,
    );
  }

  static Future<void> show(
    String? url, {
    void Function(String message)? onError,
  }) async {
    final apiPath = CatalogMeta.apiPathFromUrl(url);
    if (apiPath != null) {
      return _showBytesDialog(
        loader: () => AuthenticatedImageLoader.loadBytes(apiPath),
        onError: onError,
      );
    }

    final resolved = CatalogMeta.resolveImageUrl(url);
    if (resolved == null || resolved.isEmpty) {
      _notify(onError, 'صورة الهوية غير متوفرة على السيرفر');
      return;
    }

    if (_isPdf(resolved)) {
      final uri = Uri.tryParse(resolved);
      if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _notify(onError, 'تعذر فتح ملف PDF');
      }
      return;
    }

    final height = Get.height * 0.75;
    await Get.dialog<void>(
      Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Column(
            children: [
              AppBar(
                title: Text(AppStrings.viewIdPhoto),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4,
                  child: Image.network(
                    resolved,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (_, __, ___) => _errorContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _showBytesDialog({
    required Future<Uint8List?> Function() loader,
    void Function(String message)? onError,
  }) async {
    final bytes = await loader();
    if (bytes == null) {
      _notify(onError, 'تعذر تحميل الصورة من السيرفر');
      return;
    }

    final height = Get.height * 0.75;
    await Get.dialog<void>(
      Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Column(
            children: [
              AppBar(
                title: Text(AppStrings.viewIdPhoto),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4,
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _errorContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'تعذر تحميل الصورة.\nتأكد من رفع الملف على السيرفر.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  static bool _isPdf(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    return path.endsWith('.pdf');
  }

  static void _notify(void Function(String message)? onError, String message) {
    if (onError != null) {
      onError(message);
      return;
    }

    showMatchySnackBar(
      message: message,
      type: AppSnackBarType.error,
    );
  }
}
