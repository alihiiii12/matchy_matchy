import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:get/get.dart' hide Response;
import 'package:matchy_matchy/core/controllers/cart_controller.dart';
import 'package:matchy_matchy/core/data/delivery_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/coupon_repository.dart';
import 'package:matchy_matchy/core/services/delivery_location_utils.dart';
import 'package:matchy_matchy/core/services/delivery_service.dart';
import 'package:matchy_matchy/core/services/location_picker_navigation.dart';
import 'package:matchy_matchy/core/services/location_service.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class CheckoutAddressController extends GetxController {
  late final double? subtotalArg;

  final couponController = TextEditingController(text: DeliverySession.appliedCouponCode ?? '');

  final couponError = RxnString();
  final applyingCoupon = false.obs;
  final couponApplied = DeliverySession.hasAppliedCoupon.obs;
  final checkoutDiscount = 0.0.obs;
  final checkoutTotal = 0.0.obs;
  final locationReady = false.obs;
  final locationLoading = false.obs;
  final locationTick = 0.obs;
  final deliveryAddressSummary = ''.obs;
  final governorateSummary = ''.obs;

  double get subtotal {
    final live = CartController.instance.subtotal;
    if (live > 0) return live;
    return subtotalArg ?? (Get.arguments as double?) ?? 0;
  }
  double get deliveryFee => 0;
  double get discountAmount => DeliverySession.discountAmount;
  int get discountPercent => DeliverySession.discountPercent;

  double get total => DeliverySession.checkoutSubtotal > 0
      ? DeliverySession.checkoutTotal
      : (subtotal + deliveryFee - discountAmount).clamp(0, double.infinity);

  @override
  void onInit() {
    super.onInit();
    subtotalArg = Get.arguments as double?;
    DeliverySession.setCheckoutPricing(subtotal: subtotal, deliveryFee: deliveryFee);
    couponApplied.value = DeliverySession.hasAppliedCoupon;
    _syncCheckoutTotals();
    _refreshLocationDisplay();
  }

  @override
  void onClose() {
    couponController.dispose();
    super.onClose();
  }

  void _refreshLocationDisplay() {
    locationLoading.value = DeliverySession.locationLoading;
    locationReady.value = DeliverySession.hasSavedLocation;
    deliveryAddressSummary.value = DeliverySession.deliveryLocationSummary;
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

  void _syncCheckoutTotals() {
    DeliverySession.setCheckoutPricing(subtotal: subtotal, deliveryFee: deliveryFee);
    checkoutDiscount.value = discountAmount;
    checkoutTotal.value = total;
  }

  Future<void> applyCoupon() async {
    final code = couponController.text.trim();
    if (code.isEmpty) {
      couponError.value = AppStrings.couponNameRequired;
      return;
    }

    applyingCoupon.value = true;
    couponError.value = null;
    try {
      final data = await CouponRepository.instance.validate(name: code, subtotal: subtotal);
      DeliverySession.applyCoupon(
        code: data['name'] as String? ?? code.toUpperCase(),
        couponId: data['coupon_id'] as int,
        percent: data['discount_percent'] as int? ?? 0,
        discount: (data['discount_amount'] as num).toDouble(),
      );
      DeliverySession.setCheckoutPricing(subtotal: subtotal, deliveryFee: deliveryFee);
      couponApplied.value = true;
      couponController.text = DeliverySession.appliedCouponCode ?? code;
      _syncCheckoutTotals();
      _showMessage(AppStrings.couponAppliedSuccess, success: true);
    } on DioException catch (e) {
      couponError.value = apiFriendlyError(e, fallback: AppStrings.couponApplyFailed);
      removeCoupon(showMessage: false);
    } catch (_) {
      couponError.value = AppStrings.couponApplyFailed;
      removeCoupon(showMessage: false);
    } finally {
      applyingCoupon.value = false;
    }
  }

  void removeCoupon({bool showMessage = true}) {
    DeliverySession.clearCoupon();
    DeliverySession.setCheckoutPricing(subtotal: subtotal, deliveryFee: deliveryFee);
    couponApplied.value = false;
    couponController.clear();
    couponError.value = null;
    _syncCheckoutTotals();
    if (showMessage) {
      _showMessage(AppStrings.couponRemoved, success: true);
    }
  }

  Future<void> continueToPayment() async {
    if (!DeliverySession.hasSavedLocation) {
      _showMessage(AppStrings.chooseDeliveryLocationFirst, success: false);
      return;
    }

    if (!DeliverySession.hasHomeDescription) {
      _showMessage(AppStrings.homeDescriptionRequired, success: false);
      return;
    }

    DeliverySession.setCheckoutPricing(subtotal: subtotal, deliveryFee: deliveryFee);
    Get.toNamed(AppRoutes.payment, arguments: total);
  }

  void _showMessage(String message, {required bool success}) {
    showMatchySnackBar(
      message: message,
      type: success ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }
}

class CheckoutAddressBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(CheckoutAddressController());
  }
}
