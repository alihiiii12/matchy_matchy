import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/cart_controller.dart';
import 'package:matchy_matchy/core/data/delivery_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/coupon_repository.dart';
import 'package:matchy_matchy/core/repositories/order_repository.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/core/services/connectivity_service.dart';
import 'package:matchy_matchy/core/services/notification_service.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class PaymentController extends GetxController {
  late final double? totalArg;
  final paying = false.obs;
  final paymentMethod = DeliverySession.paymentMethod.obs;

  final senderAccountCtrl = TextEditingController();
  final transferNameCtrl = TextEditingController();
  final transferRefCtrl = TextEditingController();
  final transferAmountCtrl = TextEditingController();

  double get amount {
    final argTotal = totalArg ?? (Get.arguments as double?);
    if (argTotal != null && argTotal > 0) return argTotal;
    return DeliverySession.checkoutTotal;
  }

  double get payableAmount => amount;

  bool get isManualTransfer =>
      (paymentMethod.value == 'sham_cash' || paymentMethod.value == 'al_baraka') && payableAmount > 0;

  bool get isShamCash => paymentMethod.value == 'sham_cash' && payableAmount > 0;

  @override
  void onInit() {
    super.onInit();
    totalArg = Get.arguments as double?;
    if (paymentMethod.value.isEmpty) {
      paymentMethod.value = 'cash_on_delivery';
    }
    if (payableAmount > 0) {
      transferAmountCtrl.text = payableAmount.toStringAsFixed(0);
    }
  }

  @override
  void onClose() {
    senderAccountCtrl.dispose();
    transferNameCtrl.dispose();
    transferRefCtrl.dispose();
    transferAmountCtrl.dispose();
    super.onClose();
  }

  void selectPaymentMethod(String method) {
    paymentMethod.value = method;
    if (isManualTransfer && transferAmountCtrl.text.trim().isEmpty && payableAmount > 0) {
      transferAmountCtrl.text = payableAmount.toStringAsFixed(0);
    }
  }

  Future<void> confirmOrder() async {
    if (paying.value) return;

    if (!await ConnectivityService.instance.ensureConnection()) return;

    if (!AuthService.instance.isLoggedIn) {
      _showError('يجب تسجيل الدخول لإتمام الشراء');
      Get.toNamed(AppRoutes.login);
      return;
    }

    if (!DeliverySession.hasSavedLocation) {
      _showError(AppStrings.chooseDeliveryLocationFirst);
      Get.back();
      return;
    }

    if (!DeliverySession.hasHomeDescription) {
      _showError(AppStrings.homeDescriptionRequired);
      Get.back();
      return;
    }

    final cart = CartController.instance;
    if (cart.isEmpty) {
      _showError('سلتك فارغة');
      return;
    }

    String? senderAccount;
    String? transferName;
    String? transferRef;
    double? transferAmount;

    if (isManualTransfer) {
      senderAccount = senderAccountCtrl.text.trim();
      transferName = transferNameCtrl.text.trim();
      transferRef = transferRefCtrl.text.trim();
      transferAmount = double.tryParse(transferAmountCtrl.text.trim().replaceAll(',', ''));

      if (senderAccount.isEmpty) {
        _showError(AppStrings.shamSenderAccountRequired);
        return;
      }
      if (transferName.isEmpty) {
        _showError(AppStrings.shamTransferNameRequired);
        return;
      }
      if (transferRef.isEmpty) {
        _showError(AppStrings.shamTransferRefRequired);
        return;
      }
      if (transferAmount == null || transferAmount <= 0) {
        _showError(AppStrings.shamTransferAmountRequired);
        return;
      }
    }

    final removed = await cart.pruneUnavailableItems();
    if (removed > 0) {
      if (cart.isEmpty) {
        _showError('المنتجات في سلتك لم تعد متوفرة. أضف منتجات من المتجر ثم أعد المحاولة.');
        return;
      }
      _showError('تمت إزالة منتجات غير متوفرة من سلتك. راجع السلة ثم أكّد الطلب مرة أخرى.');
      return;
    }

    paying.value = true;
    try {
      DeliverySession.paymentMethod = paymentMethod.value;

      if (!await _syncCouponWithCart(cart)) {
        return;
      }

      final payable = DeliverySession.checkoutTotal;

      final order = await OrderRepository.instance.createOrder(
        items: cart.items.map((i) => i.toOrderItemJson()).toList(),
        subtotal: cart.subtotal,
        deliveryFee: 0,
        total: payable,
        latitude: DeliverySession.latitude!,
        longitude: DeliverySession.longitude!,
        buyerGovernorateId: DeliverySession.buyerGovernorateId,
        city: DeliverySession.city,
        areaName: DeliverySession.areaName,
        homeDescription: DeliverySession.homeDescription,
        paymentMethod: paymentMethod.value,
        senderAccountName: senderAccount,
        transferName: transferName,
        transferRef: transferRef,
        transferAmount: transferAmount,
        couponCode: DeliverySession.appliedCouponCode,
      );

      final deliveryJson = order['delivery'] as Map<String, dynamic>?;
      if (deliveryJson != null) {
        DeliverySession.lastCreatedDelivery = DeliveryRepository.instance.parseDelivery(deliveryJson);
      }

      await cart.clear();
      DeliverySession.resetCheckout();

      if (Get.isRegistered<NotificationService>()) {
        unawaited(NotificationService.instance.refresh(pushNew: false));
      }

      await Get.offNamed(AppRoutes.paymentSuccess, arguments: paymentMethod.value);
    } on DioException catch (e) {
      _showError(apiFriendlyError(e, fallback: 'تعذر إرسال الطلب للخادم'));
    } catch (_) {
      _showError('تعذر إتمام الطلب، حاول مرة أخرى');
    } finally {
      paying.value = false;
    }
  }

  void _showError(String message) {
    final context = Get.context;
    if (context != null) {
      showAppSnackBar(context, message: message, type: AppSnackBarType.error);
    } else {
      Get.snackbar(AppStrings.appName, message);
    }
  }

  Future<bool> _syncCouponWithCart(CartController cart) async {
    DeliverySession.setCheckoutPricing(subtotal: cart.subtotal, deliveryFee: 0);

    if (!DeliverySession.hasAppliedCoupon) {
      return true;
    }

    try {
      final result = await CouponRepository.instance.validate(
        name: DeliverySession.appliedCouponCode!,
        subtotal: cart.subtotal,
      );
      DeliverySession.applyCoupon(
        code: result['name'] as String? ?? DeliverySession.appliedCouponCode!,
        couponId: result['coupon_id'] as int,
        percent: result['discount_percent'] as int? ?? 0,
        discount: (result['discount_amount'] as num).toDouble(),
      );
      return true;
    } on DioException catch (e) {
      DeliverySession.clearCoupon();
      _showError(apiFriendlyError(e, fallback: 'الكوبون غير صالح'));
      return false;
    } catch (_) {
      DeliverySession.clearCoupon();
      _showError('الكوبون غير صالح');
      return false;
    }
  }
}

class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(PaymentController());
  }
}
