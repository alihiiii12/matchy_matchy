import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/data/delivery_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/core/services/delivery_location_utils.dart';
import 'package:matchy_matchy/core/services/delivery_service.dart';
import 'package:matchy_matchy/core/services/location_picker_navigation.dart';
import 'package:matchy_matchy/core/services/location_service.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class WriteManualInvoiceController extends GetxController {
  final contentController = TextEditingController();
  final submitting = false.obs;
  final submitFeedback = RxnString();
  final submitFeedbackSuccess = RxnBool();
  final locationReady = false.obs;
  final locationLoading = false.obs;
  final locationTick = 0.obs;
  final locationSummary = ''.obs;
  final governorateSummary = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _refreshLocationDisplay();
  }

  @override
  void onClose() {
    contentController.dispose();
    super.onClose();
  }

  void _refreshLocationDisplay() {
    locationLoading.value = DeliverySession.locationLoading;
    locationReady.value = DeliverySession.hasSavedLocation;
    locationSummary.value = DeliverySession.deliveryLocationSummary;
    governorateSummary.value = DeliveryService.governorateById(DeliverySession.buyerGovernorateId).name;
    locationTick.value++;
  }

  Future<void> useMyLocation() async {
    locationLoading.value = true;
    locationReady.value = false;

    try {
      final result = await ensureDeliveryLocation(force: true);
      if (!result.isGranted) {
        _showMessage(
          DeliverySession.locationError ?? LocationService.messageForStatus(result.status),
          success: false,
        );
      } else {
        _showMessage(AppStrings.deliveryLocationSelected, success: true);
      }
    } finally {
      _refreshLocationDisplay();
    }
  }

  Future<void> pickOtherLocation() async {
    locationLoading.value = false;
    DeliverySession.locationLoading = false;

    try {
      final ok = await LocationPickerNavigation.open();
      if (ok) {
        _refreshLocationDisplay();
        _showMessage(AppStrings.deliveryLocationSelected, success: true);
      }
    } catch (_) {
      _showMessage(AppStrings.mapPickerOpenFailed, success: false);
    }
  }

  Future<void> submit() async {
    if (!AuthService.instance.isLoggedIn) {
      Get.toNamed(AppRoutes.login);
      return;
    }

    final content = contentController.text.trim();
    if (content.length < 10) {
      _showMessage(AppStrings.manualInvoiceContentRequired, success: false);
      return;
    }

    if (!DeliverySession.hasSavedLocation) {
      _showMessage(AppStrings.chooseDeliveryLocationFirst, success: false);
      return;
    }

    if (!DeliverySession.hasHomeDescription) {
      _showMessage(AppStrings.homeDescriptionRequired, success: false);
      return;
    }

    submitting.value = true;
    submitFeedback.value = null;
    submitFeedbackSuccess.value = null;

    try {
      _ensureStructuredAddress();

      await ApiClient.instance.postJson(
        '/manual-invoices',
        data: {
          'content': content,
          'latitude': DeliverySession.latitude,
          'longitude': DeliverySession.longitude,
          'buyer_governorate_id': DeliverySession.buyerGovernorateId,
          'city': DeliverySession.city,
          'area_name': DeliverySession.areaName,
          'home_description': DeliverySession.homeDescription,
        },
      );

      _showFeedback(AppStrings.manualInvoiceSent, success: true);
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (isClosed) return;
      Get.back();
    } on DioException catch (e) {
      _showFeedback(apiFriendlyError(e, fallback: AppStrings.manualInvoiceSendFailed), success: false);
    } catch (_) {
      _showFeedback(AppStrings.manualInvoiceSendFailed, success: false);
    } finally {
      submitting.value = false;
    }
  }

  void _ensureStructuredAddress() {
    if (DeliverySession.latitude == null || DeliverySession.longitude == null) return;

    final needsCity = DeliverySession.city.trim().isEmpty;
    final needsArea = DeliverySession.areaName.trim().isEmpty;
    if (!needsCity && !needsArea) return;

    final fallback = LocationService.buildFromCoordinates(
      DeliverySession.latitude!,
      DeliverySession.longitude!,
    );

    if (needsCity) DeliverySession.city = fallback.city;
    if (needsArea) DeliverySession.areaName = fallback.areaName;
    _refreshLocationDisplay();
  }

  void _showFeedback(String message, {required bool success}) {
    submitFeedback.value = message;
    submitFeedbackSuccess.value = success;
    _showMessage(message, success: success);
  }

  void _showMessage(String message, {required bool success}) {
    final context = Get.context;
    if (context != null && context.mounted) {
      showAppSnackBar(
        context,
        message: message,
        type: success ? AppSnackBarType.success : AppSnackBarType.error,
      );
      return;
    }

    showMatchySnackBar(
      message: message,
      type: success ? AppSnackBarType.success : AppSnackBarType.error,
      aboveBottomNav: false,
    );
  }
}

class WriteManualInvoiceBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(WriteManualInvoiceController());
  }
}
