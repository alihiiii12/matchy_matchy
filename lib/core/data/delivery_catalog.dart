import 'package:matchy_matchy/core/models/delivery.dart';
import 'package:matchy_matchy/core/services/delivery_service.dart';
import 'package:matchy_matchy/core/services/location_service.dart';

abstract final class DeliveryCatalog {
  static final activeDeliveries = [
    DeliveryOrder(
      id: 'DEL-001',
      orderId: 'MM-2835',
      status: DeliveryStatus.onTheWay,
      mode: DeliveryMode.localExpress,
      address: 'دمشق، المزة، شارع الجلاء، بناء 12',
      itemsSummary: 'مونة ومنتجات يومية',
      total: 3050,
      deliveryFee: 260,
      estimatedTime: '35 دقيقة',
      date: '22 مايو 2026',
      sellerGovernorate: DeliveryService.governorateById('damascus'),
      buyerGovernorate: DeliveryService.governorateById('damascus'),
      distanceKm: 5,
      driver: DeliveryService.drivers.first,
      progress: 0.72,
    ),
    DeliveryOrder(
      id: 'DEL-002',
      orderId: 'MM-2820',
      status: DeliveryStatus.awaitingCoordination,
      mode: DeliveryMode.crossGovernorate,
      address: 'دمشق، الشعلان، شارع بغداد',
      itemsSummary: 'طلب من بائع في محافظة أخرى',
      total: 130000,
      deliveryFee: 2405,
      estimatedTime: '2-3 ساعات (بعد التنسيق)',
      date: '22 مايو 2026',
      sellerGovernorate: DeliveryService.governorateById('daraa'),
      buyerGovernorate: DeliveryService.governorateById('damascus'),
      distanceKm: 98,
      needsCoordination: true,
      progress: 0.1,
    ),
  ];

  static final completedDeliveries = [
    DeliveryOrder(
      id: 'DEL-003',
      orderId: 'MM-2841',
      status: DeliveryStatus.delivered,
      mode: DeliveryMode.crossGovernorate,
      address: 'دمشق، أبو رمانة، شارع النصر',
      itemsSummary: 'طلب من بائع في محافظة أخرى',
      total: 117000,
      deliveryFee: 2860,
      estimatedTime: 'تم التسليم',
      date: '18 أبريل 2026',
      sellerGovernorate: DeliveryService.governorateById('aleppo'),
      buyerGovernorate: DeliveryService.governorateById('damascus'),
      distanceKm: 310,
      driver: DeliveryService.drivers[2],
      progress: 1.0,
    ),
  ];

  static DeliveryOrder? byId(String id) {
    for (final d in [...activeDeliveries, ...completedDeliveries]) {
      if (d.id == id) return d;
    }
    return null;
  }

  static DeliveryOrder? byOrderId(String orderId) {
    for (final d in [...activeDeliveries, ...completedDeliveries]) {
      if (d.orderId == orderId) return d;
    }
    return null;
  }
}

/// تفضيلات الشراء والتوصيل
abstract final class DeliverySession {
  static String buyerGovernorateId = 'damascus';
  static String city = '';
  static String areaName = '';
  static String homeDescription = '';
  static String paymentMethod = 'cash_on_delivery';
  static const double flatDeliveryFee = 260;
  static String? detectedAddress;
  static double? latitude;
  static double? longitude;
  static bool locationReady = false;
  static bool locationLoading = false;
  static bool locationDeniedForever = false;
  static bool locationServiceDisabled = false;
  static String? locationError;
  static CartDeliveryAnalysis? lastAnalysis;
  static bool interGovCoordinated = false;
  static String coordinatedTimeSlot = '10:00 - 12:00';
  static String coordinationNote = '';
  static DeliveryOrder? lastCreatedDelivery;

  static double checkoutSubtotal = 0;
  static double checkoutDeliveryFee = 0;
  static String? appliedCouponCode;
  static int? appliedCouponId;
  static int discountPercent = 0;
  static double discountAmount = 0;

  static bool get hasAppliedCoupon => appliedCouponCode != null && appliedCouponCode!.isNotEmpty;

  static double get checkoutTotal => (checkoutSubtotal + checkoutDeliveryFee - discountAmount).clamp(0, double.infinity);

  static void setCheckoutPricing({required double subtotal, required double deliveryFee}) {
    checkoutSubtotal = subtotal;
    checkoutDeliveryFee = deliveryFee;
  }

  static void applyCoupon({
    required String code,
    required int couponId,
    required int percent,
    required double discount,
  }) {
    appliedCouponCode = code;
    appliedCouponId = couponId;
    discountPercent = percent;
    discountAmount = discount;
  }

  static void clearCoupon() {
    appliedCouponCode = null;
    appliedCouponId = null;
    discountPercent = 0;
    discountAmount = 0;
  }

  static String get deliveryAddress {
    if (city.isNotEmpty || areaName.isNotEmpty) {
      final gov = DeliveryService.governorateById(buyerGovernorateId).name;
      return [gov, city, areaName, homeDescription].where((s) => s.isNotEmpty).join(' — ');
    }
    return detectedAddress ?? DeliveryService.governorateById(buyerGovernorateId).name;
  }

  static String get deliveryLocationSummary {
    if (city.isNotEmpty || areaName.isNotEmpty) {
      final gov = DeliveryService.governorateById(buyerGovernorateId).name;
      return [gov, city, areaName].where((s) => s.isNotEmpty).join(' — ');
    }
    return detectedAddress ?? DeliveryService.governorateById(buyerGovernorateId).name;
  }

  /// عنوان مُشتق تلقائياً من GPS أو الخريطة (للـ API).
  static bool get hasStructuredAddress =>
      hasSavedLocation &&
      city.trim().isNotEmpty &&
      areaName.trim().isNotEmpty &&
      homeDescription.trim().isNotEmpty;

  /// الموقع مُحدّد (GPS أو خريطة) خلال جلسة الشراء.
  static bool get hasSavedLocation =>
      locationReady && latitude != null && longitude != null;

  static bool get hasHomeDescription => homeDescription.trim().isNotEmpty;

  static void applyLocation(UserLocation location) {
    detectedAddress = location.address;
    latitude = location.latitude;
    longitude = location.longitude;
    buyerGovernorateId = location.governorateId;
    city = location.city;
    areaName = location.areaName;
    homeDescription = '';
    locationReady = true;
    locationLoading = false;
    locationDeniedForever = false;
    locationServiceDisabled = false;
    locationError = null;
  }

  static void resetCheckout() {
    city = '';
    areaName = '';
    homeDescription = '';
    paymentMethod = 'cash_on_delivery';
    interGovCoordinated = false;
    coordinationNote = '';
    lastAnalysis = null;
    lastCreatedDelivery = null;
    checkoutSubtotal = 0;
    checkoutDeliveryFee = 0;
    latitude = null;
    longitude = null;
    locationReady = false;
    locationLoading = false;
    locationDeniedForever = false;
    locationServiceDisabled = false;
    locationError = null;
    detectedAddress = null;
    clearCoupon();
  }
}
