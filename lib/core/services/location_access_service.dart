import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/services/driver_location_tracker.dart';
import 'package:matchy_matchy/core/services/location_service.dart';

/// يطلب صلاحية الموقع تلقائياً ويعيد المحاولة بعد العودة من إعدادات الجهاز/التطبيق.
class LocationAccessService extends GetxService with WidgetsBindingObserver {
  bool _resumeRetry = false;
  bool? _pendingIsDriver;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_resumeRetry) return;
    _resumeRetry = false;
    final isDriver = _pendingIsDriver ?? false;
    unawaited(_ensureAccess(isDriver: isDriver, interactive: false));
  }

  Future<void> prepareForUser({required bool isDriver}) async {
    _pendingIsDriver = isDriver;
    await _ensureAccess(isDriver: isDriver, interactive: true);
  }

  Future<bool> ensureForTracking({bool interactive = true}) async {
    _pendingIsDriver = true;
    final status = await _ensureAccess(isDriver: true, interactive: interactive);
    return status == LocationAccessStatus.granted;
  }

  Future<LocationAccessStatus> _ensureAccess({
    required bool isDriver,
    bool interactive = true,
  }) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (interactive) {
        final enable = await _ask(
          title: AppStrings.locationPermissionDialogTitle,
          body: AppStrings.locationGpsDialogBody,
          action: AppStrings.enableGpsService,
        );
        if (enable) {
          _resumeRetry = true;
          _pendingIsDriver = isDriver;
          await Geolocator.openLocationSettings();
        }
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationAccessStatus.serviceDisabled;
      }
    }

    var status = await LocationService.requestLocationPermission(isDriver: isDriver);

    if (status == LocationAccessStatus.denied && interactive) {
      status = await LocationService.requestLocationPermission(isDriver: isDriver);
    }

    if (status == LocationAccessStatus.deniedForever && interactive) {
      final open = await _ask(
        title: AppStrings.locationPermissionDialogTitle,
        body: isDriver
            ? AppStrings.locationPermissionDialogBodyDriverSettings
            : AppStrings.locationPermissionDialogBodyCustomerSettings,
        action: AppStrings.openAppPermissionSettings,
      );
      if (open) {
        _resumeRetry = true;
        _pendingIsDriver = isDriver;
        await openAppSettings();
      }
      return status;
    }

    if (status == LocationAccessStatus.granted && isDriver && Get.isRegistered<DriverLocationTracker>()) {
      unawaited(_retryDriverTracker());
    }

    return status;
  }

  Future<void> _retryDriverTracker() async {
    if (!Get.isRegistered<DriverLocationTracker>()) return;
    final tracker = Get.find<DriverLocationTracker>();
    await tracker.retryAfterPermissionGranted();
  }

  Future<bool> _ask({
    required String title,
    required String body,
    required String action,
  }) async {
    final context = Get.context ?? Get.key.currentContext;
    if (context == null) return false;

    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(body, style: const TextStyle(height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(AppStrings.later),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(action),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    return result == true;
  }
}
