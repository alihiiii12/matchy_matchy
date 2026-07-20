import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';

class AdminDeliveryTrackingController extends GetxController {
  late final int orderId;
  final loading = true.obs;
  final refreshing = false.obs;
  final error = RxnString();
  final tracking = Rxn<Map<String, dynamic>>();
  final mapController = MapController();

  final _trailPoints = <LatLng>[].obs;
  final _driverPoint = Rxn<LatLng>();
  final _destinationPoint = Rxn<LatLng>();
  final _mapCenter = const LatLng(33.5138, 36.2765).obs;
  final _mapZoom = 13.0.obs;

  Timer? _pollTimer;
  bool _initialFitDone = false;
  bool _loadInFlight = false;
  int _trailPointCount = 0;

  List<LatLng> get trailPoints => _trailPoints;
  LatLng? get driverPoint => _driverPoint.value;
  LatLng? get destinationPoint => _destinationPoint.value;
  LatLng get mapCenter => _mapCenter.value;
  double get mapZoom => _mapZoom.value;

  @override
  void onInit() {
    super.onInit();
    orderId = Get.arguments as int;
    load();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (tracking.value != null) {
        load(silent: true);
      }
    });
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }

  Future<void> load({bool silent = false}) async {
    if (_loadInFlight) return;
    _loadInFlight = true;

    if (!silent) {
      loading.value = true;
      error.value = null;
    } else {
      refreshing.value = true;
    }

    try {
      final res = await ApiClient.instance.getJson('/admin/orders/$orderId/delivery-tracking');
      final data = res.data!['data'] as Map<String, dynamic>;
      tracking.value = data;
      _applyTrackingData(data, refitMap: !_initialFitDone);
    } on DioException catch (e) {
      if (!silent) {
        error.value = apiFriendlyError(e, fallback: 'تعذر تحميل التتبع');
      }
    } finally {
      _loadInFlight = false;
      if (!silent) {
        loading.value = false;
      }
      refreshing.value = false;
    }
  }

  void _applyTrackingData(Map<String, dynamic> data, {required bool refitMap}) {
    final trail = data['trail'] as List<dynamic>? ?? [];
    final points = <LatLng>[];
    for (final item in trail) {
      final m = item as Map<String, dynamic>;
      final lat = m['latitude'] as num?;
      final lng = m['longitude'] as num?;
      if (lat != null && lng != null) {
        points.add(LatLng(lat.toDouble(), lng.toDouble()));
      }
    }

    LatLng? driver;
    final current = data['current'] as Map<String, dynamic>?;
    if (current != null) {
      final lat = current['latitude'] as num?;
      final lng = current['longitude'] as num?;
      if (lat != null && lng != null) {
        driver = LatLng(lat.toDouble(), lng.toDouble());
      }
    }
    driver ??= points.isNotEmpty ? points.last : null;

    LatLng? dest;
    final destination = data['destination'] as Map<String, dynamic>?;
    if (destination != null) {
      final lat = destination['latitude'] as num?;
      final lng = destination['longitude'] as num?;
      if (lat != null && lng != null) {
        dest = LatLng(lat.toDouble(), lng.toDouble());
      }
    }

    final trailChanged = points.length != _trailPointCount;
    _trailPointCount = points.length;
    _trailPoints.value = points;
    _driverPoint.value = driver;
    _destinationPoint.value = dest;

    if (refitMap) {
      _fitMapOnce(driver: driver, dest: dest, trail: points);
      _initialFitDone = true;
    } else if (trailChanged && driver != null) {
      _moveDriverMarker(driver);
    }
  }

  bool get isTrackingActive => tracking.value?['tracking_active'] as bool? ?? false;

  bool get isCustomerOnly => tracking.value?['customer_only'] as bool? ?? false;

  String get statusLabel {
    if (isCustomerOnly) {
      return 'موقع الزبون — بانتظار تعيين سائق';
    }

    final status = tracking.value?['delivery_status'] as String? ?? '';
    switch (status) {
      case 'assigned':
        return 'معيّن — بانتظار الانطلاق';
      case 'accepted':
        return 'قبل السائق المهمة';
      case 'in_transit':
        return 'السائق في الطريق';
      case 'driver_delivered':
        return 'أبلغ السائق بالتسليم';
      default:
        return status;
    }
  }

  void _fitMapOnce({
    required LatLng? driver,
    required LatLng? dest,
    required List<LatLng> trail,
  }) {
    final points = <LatLng>[...trail];
    if (driver != null) points.add(driver);
    if (dest != null) points.add(dest);

    if (points.isEmpty) return;

    final center = driver ?? dest ?? points.first;
    _mapCenter.value = center;
    _mapZoom.value = points.length == 1 ? 14 : 13;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isClosed && points.length == 1) {
        mapController.move(center, _mapZoom.value);
        return;
      }
      if (!isClosed && points.length > 1) {
        mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.all(48),
          ),
        );
      }
    });
  }

  void _moveDriverMarker(LatLng driver) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isClosed) {
        mapController.move(driver, mapController.camera.zoom);
      }
    });
  }
}

class AdminDeliveryTrackingBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AdminDeliveryTrackingController());
  }
}
