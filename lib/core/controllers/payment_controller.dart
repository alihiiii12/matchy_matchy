import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
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
  final pickingProof = false.obs;
  final paymentMethod = DeliverySession.paymentMethod.obs;
  final paymentProof = Rxn<File>();
  final paymentProofName = RxnString();

  double get amount {
    final argTotal = totalArg ?? (Get.arguments as double?);
    if (argTotal != null && argTotal > 0) return argTotal;
    return DeliverySession.checkoutTotal;
  }

  double get payableAmount => amount;

  bool get requiresPaymentProof => paymentMethod.value == 'sham_cash' && payableAmount > 0;

  bool get paymentProofIsImage {
    final name = paymentProofName.value ?? paymentProof.value?.path ?? '';
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.heic');
  }

  @override
  void onInit() {
    super.onInit();
    totalArg = Get.arguments as double?;
    if (paymentMethod.value.isEmpty) {
      paymentMethod.value = 'cash_on_delivery';
    }
  }

  void selectPaymentMethod(String method) {
    paymentMethod.value = method;
    if (method != 'sham_cash') {
      paymentProof.value = null;
      paymentProofName.value = null;
    }
  }

  Future<void> pickPaymentProof() async {
    if (pickingProof.value) return;

    pickingProof.value = true;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      final file = result?.files.single;
      final path = file?.path;
      if (path != null && path.isNotEmpty) {
        paymentProof.value = File(path);
        paymentProofName.value = file?.name ?? path.split(Platform.pathSeparator).last;
      }
    } catch (_) {
      _showError('تعذر اختيار الملف');
    } finally {
      pickingProof.value = false;
    }
  }

  void clearPaymentProof() {
    paymentProof.value = null;
    paymentProofName.value = null;
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

    if (requiresPaymentProof && paymentProof.value == null) {
      _showError(AppStrings.paymentProofRequired);
      return;
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

      final orderTotal = DeliverySession.checkoutTotal;
      final payable = orderTotal;

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
        paymentProof: paymentProof.value,
        paymentProofName: paymentProofName.value,
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

    final code = DeliverySession.appliedCouponCode;
    if (code == null || code.isEmpty) {
      return true;
    }

    try {
      final data = await CouponRepository.instance.validate(name: code, subtotal: cart.subtotal);
      DeliverySession.applyCoupon(
        code: data['name'] as String? ?? code,
        couponId: data['coupon_id'] as int,
        percent: data['discount_percent'] as int? ?? 0,
        discount: (data['discount_amount'] as num).toDouble(),
      );
      DeliverySession.setCheckoutPricing(subtotal: cart.subtotal, deliveryFee: 0);
      return true;
    } on DioException catch (e) {
      DeliverySession.clearCoupon();
      DeliverySession.setCheckoutPricing(subtotal: cart.subtotal, deliveryFee: 0);
      _showError(apiFriendlyError(e, fallback: AppStrings.couponApplyFailed));
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
