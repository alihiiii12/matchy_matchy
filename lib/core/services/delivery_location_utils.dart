import 'package:matchy_matchy/core/data/delivery_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/services/location_access_service.dart';
import 'package:matchy_matchy/core/services/location_service.dart';

LocationAccessResult _cachedLocationResult() {
  return LocationAccessResult(
    status: LocationAccessStatus.granted,
    location: UserLocation(
      latitude: DeliverySession.latitude!,
      longitude: DeliverySession.longitude!,
      address: DeliverySession.detectedAddress ?? DeliverySession.deliveryAddress,
      governorateId: DeliverySession.buyerGovernorateId,
      city: DeliverySession.city,
      areaName: DeliverySession.areaName,
      homeDescription: DeliverySession.homeDescription,
    ),
  );
}

/// يحدّث الجلسة عند اختيار «موقعي» (GPS).
Future<LocationAccessResult> ensureDeliveryLocation({bool force = false}) async {
  if (!force && DeliverySession.hasSavedLocation) {
    return _cachedLocationResult();
  }

  if (DeliverySession.locationLoading) {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (DeliverySession.hasSavedLocation) {
      return _cachedLocationResult();
    }
  }

  DeliverySession.locationLoading = true;
  DeliverySession.locationError = null;
  DeliverySession.locationDeniedForever = false;
  DeliverySession.locationServiceDisabled = false;

  try {
    final result = await LocationService.detectWithPermission(requestIfNeeded: true);

    if (result.isGranted && result.location != null) {
      DeliverySession.applyLocation(result.location!);
      return result;
    }

    DeliverySession.locationDeniedForever = result.status == LocationAccessStatus.deniedForever;
    DeliverySession.locationServiceDisabled = result.status == LocationAccessStatus.serviceDisabled;
    DeliverySession.locationError = LocationService.messageForStatus(result.status);
    if (DeliverySession.locationError!.isEmpty) {
      DeliverySession.locationError = AppStrings.locationRequired;
    }

    if (!result.isGranted &&
        Get.isRegistered<LocationAccessService>() &&
        (result.status == LocationAccessStatus.deniedForever ||
            result.status == LocationAccessStatus.serviceDisabled)) {
      await Get.find<LocationAccessService>().prepareForUser(isDriver: false);
    }

    return result;
  } finally {
    DeliverySession.locationLoading = false;
  }
}
