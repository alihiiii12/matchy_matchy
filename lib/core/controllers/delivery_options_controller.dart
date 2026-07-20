import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/cart_controller.dart';
import 'package:matchy_matchy/core/data/delivery_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/delivery.dart';
import 'package:matchy_matchy/core/services/delivery_location_utils.dart';
import 'package:matchy_matchy/core/services/delivery_service.dart';
import 'package:matchy_matchy/core/services/location_picker_navigation.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class DeliveryOptionsController extends GetxController {
  late final double? subtotalArg;
  final analysis = Rx<CartDeliveryAnalysis?>(null);
  final reloadTick = 0.obs;
  final locationReady = false.obs;
  final locationLoading = false.obs;
  final locationTick = 0.obs;
  final deliveryAddressSummary = ''.obs;
  final governorateSummary = ''.obs;

  CartController get cart => CartController.instance;

  double get subtotal => subtotalArg ?? cart.subtotal;

  CartDeliveryAnalysis get currentAnalysis =>
      analysis.value ??
      DeliveryService.analyzeCart(
        products: cart.productsForDelivery(),
        buyerGovernorateId: DeliverySession.buyerGovernorateId,
      );

  double get total => subtotal + currentAnalysis.totalFee;

  bool get canContinue =>
      !cart.isEmpty &&
      DeliverySession.hasSavedLocation &&
      DeliverySession.hasHomeDescription &&
      (!currentAnalysis.needsCoordination || DeliverySession.interGovCoordinated);

  Worker? _cartWorker;

  @override
  void onInit() {
    super.onInit();
    subtotalArg = Get.arguments as double?;
    final initial = _buildAnalysis();
    analysis.value = initial;
    DeliverySession.lastAnalysis = initial;
    _refreshLocationDisplay();
    _cartWorker = ever(cart.cartItems, (_) => _onCartChanged());
  }

  @override
  void onClose() {
    _cartWorker?.dispose();
    super.onClose();
  }

  CartDeliveryAnalysis _buildAnalysis() {
    return DeliveryService.analyzeCart(
      products: cart.productsForDelivery(),
      buyerGovernorateId: DeliverySession.buyerGovernorateId,
    );
  }

  void _onCartChanged() {
    final next = _buildAnalysis();
    analysis.value = next;
    DeliverySession.lastAnalysis = next;
    reloadTick.value++;
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
      _refreshAnalysis();
      if (!result.isGranted && DeliverySession.locationError != null) {
        Get.snackbar('', DeliverySession.locationError!);
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
        _refreshAnalysis();
        Get.snackbar('', AppStrings.deliveryLocationSelected);
      }
    } catch (_) {
      Get.snackbar('', AppStrings.mapPickerOpenFailed);
    }
  }

  void _refreshAnalysis() {
    final next = _buildAnalysis();
    analysis.value = next;
    DeliverySession.lastAnalysis = next;
    reloadTick.value++;
  }

  void goBack() => Get.back();

  Future<void> openCoordinateDelivery() async {
    final done = await Get.toNamed<bool>(AppRoutes.coordinateDelivery, arguments: currentAnalysis);
    if (done == true) reloadTick.value++;
  }

  void continueToPayment() {
    if (!DeliverySession.hasSavedLocation) {
      Get.snackbar('', AppStrings.chooseDeliveryLocationFirst);
      return;
    }
    if (!DeliverySession.hasHomeDescription) {
      Get.snackbar('', AppStrings.homeDescriptionRequired);
      return;
    }
    DeliverySession.lastAnalysis = currentAnalysis;
    Get.toNamed(AppRoutes.payment, arguments: total);
  }
}

class DeliveryOptionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DeliveryOptionsController>(() => DeliveryOptionsController());
  }
}
