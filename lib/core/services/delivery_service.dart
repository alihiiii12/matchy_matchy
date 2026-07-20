import 'dart:math';

import 'package:matchy_matchy/core/models/delivery.dart';
import 'package:matchy_matchy/core/models/product.dart';

abstract final class DeliveryService {
  static const localCategoryIds = {'groceries', 'vegetables', 'food', 'beverages', 'home'};

  static const governorates = [
    Governorate(id: 'damascus', name: 'دمشق', lat: 33.5138, lng: 36.2765),
    Governorate(id: 'rif_damascus', name: 'ريف دمشق', lat: 33.45, lng: 36.35),
    Governorate(id: 'daraa', name: 'درعا', lat: 32.6189, lng: 36.1021),
    Governorate(id: 'aleppo', name: 'حلب', lat: 36.2021, lng: 37.1343),
    Governorate(id: 'homs', name: 'حمص', lat: 34.7324, lng: 36.7138),
    Governorate(id: 'latakia', name: 'اللاذقية', lat: 35.5317, lng: 35.7908),
  ];

  static const drivers = [
    DeliveryDriver(
      name: 'محمد العلي',
      phone: '+963 944 123 456',
      vehicle: 'دراجة نارية',
      plateNumber: 'دمشق 4521',
      rating: 4.9,
      governorateId: 'damascus',
    ),
    DeliveryDriver(
      name: 'سامر الحلبي',
      phone: '+963 955 987 654',
      vehicle: 'سيارة صغيرة',
      plateNumber: 'دمشق 8832',
      rating: 4.7,
      governorateId: 'damascus',
    ),
    DeliveryDriver(
      name: 'كريم درعاوي',
      phone: '+963 933 456 789',
      vehicle: 'فان توصيل',
      plateNumber: 'درعا 1120',
      rating: 4.8,
      governorateId: 'daraa',
    ),
  ];

  static Governorate governorateById(String id) {
    return governorates.firstWhere(
      (g) => g.id == id,
      orElse: () => governorates.first,
    );
  }

  static bool isLocalProduct(Product product) => localCategoryIds.contains(product.categoryId);

  static double distanceKm(Governorate from, Governorate to) {
    if (from.id == to.id) return 5;
    const earthRadius = 6371.0;
    final dLat = _rad(to.lat - from.lat);
    final dLng = _rad(to.lng - from.lng);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(from.lat)) * cos(_rad(to.lat)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return (earthRadius * c).roundToDouble();
  }

  static double _rad(double deg) => deg * pi / 180;

  static String nearestGovernorateId(double lat, double lng) {
    var nearest = governorates.first;
    var minKm = double.infinity;
    for (final g in governorates) {
      const earthRadius = 6371.0;
      final dLat = _rad(g.lat - lat);
      final dLng = _rad(g.lng - lng);
      final a = sin(dLat / 2) * sin(dLat / 2) +
          cos(_rad(lat)) * cos(_rad(g.lat)) * sin(dLng / 2) * sin(dLng / 2);
      final c = 2 * atan2(sqrt(a), sqrt(1 - a));
      final km = earthRadius * c;
      if (km < minKm) {
        minKm = km;
        nearest = g;
      }
    }
    return nearest.id;
  }

  static DeliveryDriver nearestDriver(String buyerGovernorateId) {
    final same = drivers.where((d) => d.governorateId == buyerGovernorateId).toList();
    if (same.isNotEmpty) return same.first;
    return drivers.first;
  }

  static ProductDeliveryInfo analyzeProduct({
    required Product product,
    required String buyerGovernorateId,
  }) {
    final seller = governorateById(product.sellerGovernorateId);
    final buyer = governorateById(buyerGovernorateId);
    final km = distanceKm(seller, buyer);

    if (isLocalProduct(product)) {
      final minutes = 20 + (km * 2).round().clamp(0, 35);
      return ProductDeliveryInfo(
        productId: product.id,
        productName: product.name,
        mode: DeliveryMode.localExpress,
        sellerGovernorate: seller,
        buyerGovernorate: buyer,
        distanceKm: km,
        etaLabel: 'حوالي $minutes دقيقة',
        fee: 1.99,
        needsCoordination: false,
      );
    }

    if (seller.id == buyer.id) {
      final hours = (km / 15 + 1).round().clamp(1, 24);
      return ProductDeliveryInfo(
        productId: product.id,
        productName: product.name,
        mode: DeliveryMode.sameGovernorate,
        sellerGovernorate: seller,
        buyerGovernorate: buyer,
        distanceKm: km,
        etaLabel: hours <= 3 ? 'حوالي $hours ساعات' : 'حتى 24 ساعة',
        fee: 3.99 + (km * 0.1),
        needsCoordination: false,
      );
    }

    final travelHours = (km / 50).ceil();
    final eta = travelHours <= 24
        ? 'حوالي $travelHours-${travelHours + 4} ساعات'
        : '${(travelHours / 24).ceil()}-${(travelHours / 24).ceil() + 1} أيام';

    return ProductDeliveryInfo(
      productId: product.id,
      productName: product.name,
      mode: DeliveryMode.crossGovernorate,
      sellerGovernorate: seller,
      buyerGovernorate: buyer,
      distanceKm: km,
      etaLabel: eta,
      fee: 5.99 + (km * 0.15),
      needsCoordination: true,
    );
  }

  static CartDeliveryAnalysis analyzeCart({
    required List<Product> products,
    required String buyerGovernorateId,
  }) {
    final items = products
        .map((p) => analyzeProduct(product: p, buyerGovernorateId: buyerGovernorateId))
        .toList();
    final localDriver = items.any((i) => i.mode == DeliveryMode.localExpress)
        ? nearestDriver(buyerGovernorateId)
        : null;
    final totalFee = items.fold<double>(0, (s, i) => s + i.fee);
    return CartDeliveryAnalysis(items: items, localDriver: localDriver, totalFee: totalFee);
  }
}
