import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/services/location_access_service.dart';
import 'package:matchy_matchy/core/services/location_service.dart';

/// يرسل موقع السائق للسيرفر أثناء التوصيل (من الانطلاق حتى التسليم).
class DriverLocationTracker extends GetxService {
  StreamSubscription<Position>? _subscription;
  String? _activeDeliveryId;
  DateTime? _lastSentAt;
  Position? _lastSentPosition;

  static const _trackableStatuses = {'assigned', 'accepted', 'in_transit'};

  Future<void> syncFromJobs(List<Map<String, dynamic>> jobs) async {
    final active = jobs.where((job) {
      final status = job['status'] as String?;
      return status != null && _trackableStatuses.contains(status);
    }).toList();

    if (active.isEmpty) {
      await stop();
      return;
    }

    await start(active.first['id']?.toString() ?? '');
  }

  Future<void> retryAfterPermissionGranted() async {
    final deliveryId = _activeDeliveryId;
    if (deliveryId == null || deliveryId.isEmpty) return;
    await start(deliveryId, requestPermission: false);
  }

  Future<void> start(String deliveryId, {bool requestPermission = true}) async {
    if (_activeDeliveryId == deliveryId && _subscription != null) {
      return;
    }

    await stop();
    _activeDeliveryId = deliveryId;

    if (requestPermission && Get.isRegistered<LocationAccessService>()) {
      final granted = await Get.find<LocationAccessService>().ensureForTracking();
      if (!granted) return;
    } else {
      final status = await LocationService.requestLocationPermission(isDriver: true);
      if (status != LocationAccessStatus.granted) return;
    }

    final settings = Platform.isAndroid
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 20,
            intervalDuration: const Duration(seconds: 15),
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 20,
          );

    _subscription = Geolocator.getPositionStream(locationSettings: settings).listen(
      _onPosition,
      onError: (_) {},
    );

    try {
      final pos = await Geolocator.getCurrentPosition();
      await _sendPosition(pos);
    } catch (_) {}
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _activeDeliveryId = null;
    _lastSentAt = null;
    _lastSentPosition = null;
  }

  Future<void> _onPosition(Position position) async {
    if (_activeDeliveryId == null) return;

    final now = DateTime.now();
    if (_lastSentAt != null && _lastSentPosition != null) {
      final elapsed = now.difference(_lastSentAt!);
      if (elapsed.inSeconds < 12) {
        final moved = Geolocator.distanceBetween(
          _lastSentPosition!.latitude,
          _lastSentPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        if (moved < 15) return;
      }
    }

    await _sendPosition(position);
  }

  Future<void> _sendPosition(Position position) async {
    final deliveryId = _activeDeliveryId;
    if (deliveryId == null) return;

    try {
      await ApiClient.instance.postJson(
        '/driver/delivery-jobs/$deliveryId/location',
        data: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      );
      _lastSentAt = DateTime.now();
      _lastSentPosition = position;
    } catch (_) {}
  }
}
