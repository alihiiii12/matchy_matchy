import 'dart:io';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/services/delivery_service.dart';

class UserLocation {
  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.governorateId,
    required this.city,
    required this.areaName,
    required this.homeDescription,
  });

  final double latitude;
  final double longitude;
  final String address;
  final String governorateId;
  final String city;
  final String areaName;
  final String homeDescription;

  String get governorateName => DeliveryService.governorateById(governorateId).name;
}

enum LocationAccessStatus {
  granted,
  serviceDisabled,
  denied,
  deniedForever,
}

class LocationAccessResult {
  const LocationAccessResult({
    required this.status,
    this.location,
    this.debugDetail,
  });

  final LocationAccessStatus status;
  final UserLocation? location;
  final String? debugDetail;

  bool get isGranted => status == LocationAccessStatus.granted && location != null;
}

abstract final class LocationService {
  static Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  static Future<LocationAccessStatus> requestLocationPermission({bool isDriver = false}) async {
    if (!await isServiceEnabled()) {
      return LocationAccessStatus.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      if (isDriver) {
        await _requestDriverBackgroundIfNeeded();
      }
      return LocationAccessStatus.granted;
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationAccessStatus.deniedForever;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      var handlerStatus = await Permission.locationWhenInUse.status;
      if (!handlerStatus.isGranted) {
        handlerStatus = await Permission.locationWhenInUse.request();
      }
      if (handlerStatus.isPermanentlyDenied) {
        return LocationAccessStatus.deniedForever;
      }
      if (handlerStatus.isGranted) {
        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          if (isDriver) {
            await _requestDriverBackgroundIfNeeded();
          }
          return LocationAccessStatus.granted;
        }
      }

      handlerStatus = await Permission.location.status;
      if (!handlerStatus.isGranted) {
        handlerStatus = await Permission.location.request();
      }
      if (handlerStatus.isPermanentlyDenied) {
        return LocationAccessStatus.deniedForever;
      }
      if (handlerStatus.isGranted) {
        if (isDriver) {
          await _requestDriverBackgroundIfNeeded();
        }
        return LocationAccessStatus.granted;
      }
    }

    return LocationAccessStatus.denied;
  }

  static Future<void> _requestDriverBackgroundIfNeeded() async {
    if (!Platform.isAndroid) return;

    final always = await Permission.locationAlways.status;
    if (always.isGranted) return;

    final whenInUse = await Permission.locationWhenInUse.status;
    if (!whenInUse.isGranted) return;

    await Permission.locationAlways.request();
  }

  static LocationSettings _locationSettings({
    required LocationAccuracy accuracy,
    bool forceAndroidManager = false,
  }) {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: accuracy,
        timeLimit: const Duration(seconds: 30),
        forceLocationManager: forceAndroidManager,
      );
    }
    return LocationSettings(
      accuracy: accuracy,
      timeLimit: const Duration(seconds: 30),
    );
  }

  static Future<({Position? position, bool serviceDisabledHint})> _readPosition() async {
    var serviceDisabledHint = false;

    final attempts = <LocationSettings>[
      _locationSettings(accuracy: LocationAccuracy.high),
      if (Platform.isAndroid) _locationSettings(accuracy: LocationAccuracy.high, forceAndroidManager: true),
      _locationSettings(accuracy: LocationAccuracy.medium),
    ];

    for (final settings in attempts) {
      try {
        final position = await Geolocator.getCurrentPosition(locationSettings: settings);
        return (position: position, serviceDisabledHint: false);
      } on LocationServiceDisabledException {
        serviceDisabledHint = true;
      } on PermissionDeniedException {
        return (position: null, serviceDisabledHint: false);
      } catch (_) {}
    }

    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) {
      return (position: lastKnown, serviceDisabledHint: false);
    }

    return (position: null, serviceDisabledHint: serviceDisabledHint);
  }

  /// Builds a delivery location from coordinates without network (map pin confirm).
  static UserLocation buildFromCoordinates(double latitude, double longitude) {
    final governorateId = DeliveryService.nearestGovernorateId(latitude, longitude);
    final govName = DeliveryService.governorateById(governorateId).name;
    final coordsLabel =
        '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

    return UserLocation(
      latitude: latitude,
      longitude: longitude,
      address: '$govName — ${AppStrings.deliveryMapPoint} ($coordsLabel)',
      governorateId: governorateId,
      city: govName,
      areaName: AppStrings.deliveryMapPoint,
      homeDescription: '${AppStrings.deliveryFromMap} ($coordsLabel)',
    );
  }

  static Future<UserLocation> resolveAtCoordinates(double latitude, double longitude) async {
    final fallback = buildFromCoordinates(latitude, longitude);
    Placemark? placemark;

    try {
      final places = await placemarkFromCoordinates(latitude, longitude).timeout(const Duration(seconds: 6));
      if (places.isNotEmpty) {
        placemark = places.first;
      }
    } catch (_) {}

    if (placemark == null) {
      return fallback;
    }

    final governorateId = DeliveryService.nearestGovernorateId(latitude, longitude);
    final structured = _structuredFromPlacemark(placemark, governorateId);
    final address = _formatAddress(placemark, governorateId);

    return UserLocation(
      latitude: latitude,
      longitude: longitude,
      address: address,
      governorateId: governorateId,
      city: structured.city,
      areaName: structured.areaName,
      homeDescription: structured.homeDescription,
    );
  }

  static Future<LocationAccessResult> detectWithPermission({bool requestIfNeeded = true}) async {
    if (requestIfNeeded) {
      final access = await requestLocationPermission();
      if (access == LocationAccessStatus.denied) {
        return const LocationAccessResult(status: LocationAccessStatus.denied);
      }
      if (access == LocationAccessStatus.deniedForever) {
        return const LocationAccessResult(status: LocationAccessStatus.deniedForever);
      }
    } else {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
        final access = await _mapGeolocatorPermission(permission);
        return LocationAccessResult(status: access);
      }
    }

    final read = await _readPosition();
    final position = read.position;

    if (position == null) {
      final serviceOn = await isServiceEnabled();
      if (!serviceOn && read.serviceDisabledHint) {
        return const LocationAccessResult(status: LocationAccessStatus.serviceDisabled);
      }
      if (serviceOn) {
        return const LocationAccessResult(status: LocationAccessStatus.denied);
      }
      return const LocationAccessResult(status: LocationAccessStatus.serviceDisabled);
    }

    final location = await resolveAtCoordinates(position.latitude, position.longitude);

    return LocationAccessResult(
      status: LocationAccessStatus.granted,
      location: location,
    );
  }

  static Future<LocationAccessStatus> _mapGeolocatorPermission(LocationPermission permission) async {
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      return LocationAccessStatus.granted;
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationAccessStatus.deniedForever;
    }
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.locationWhenInUse.status;
      if (status.isPermanentlyDenied) return LocationAccessStatus.deniedForever;
    }
    return LocationAccessStatus.denied;
  }

  static Future<UserLocation?> detect() async {
    final result = await detectWithPermission();
    return result.location;
  }

  static String messageForStatus(LocationAccessStatus status) {
    switch (status) {
      case LocationAccessStatus.serviceDisabled:
        return AppStrings.locationDisabled;
      case LocationAccessStatus.deniedForever:
        return AppStrings.locationPermissionDeniedForever;
      case LocationAccessStatus.denied:
        return AppStrings.locationFixFailed;
      case LocationAccessStatus.granted:
        return '';
    }
  }

  static Future<bool> openLocationSettings() async {
    if (await Geolocator.openLocationSettings()) return true;
    return openAppSettings();
  }

  static ({String city, String areaName, String homeDescription}) _structuredFromPlacemark(
    Placemark? placemark,
    String governorateId,
  ) {
    final govName = DeliveryService.governorateById(governorateId).name;

    if (placemark == null) {
      return (
        city: govName,
        areaName: AppStrings.deliveryMapPoint,
        homeDescription: AppStrings.deliveryFromMap,
      );
    }

    final city = _firstNonEmpty([
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
      govName,
    ]);

    final areaName = _firstNonEmpty([
      placemark.street,
      placemark.subLocality,
      placemark.thoroughfare,
      AppStrings.deliveryMapPoint,
    ]);

    final homeDescription = _firstNonEmpty([
      placemark.name,
      placemark.street,
      '${placemark.subLocality ?? ''} ${placemark.locality ?? ''}'.trim(),
      AppStrings.deliveryFromMap,
    ]);

    return (city: city, areaName: areaName, homeDescription: homeDescription);
  }

  static String _formatAddress(Placemark? placemark, String governorateId) {
    if (placemark == null) {
      return DeliveryService.governorateById(governorateId).name;
    }

    final parts = [
      if (placemark.street?.trim().isNotEmpty == true) placemark.street!.trim(),
      if (placemark.subLocality?.trim().isNotEmpty == true) placemark.subLocality!.trim(),
      if (placemark.locality?.trim().isNotEmpty == true) placemark.locality!.trim(),
      DeliveryService.governorateById(governorateId).name,
    ];
    if (parts.isNotEmpty) return parts.join('، ');
    return DeliveryService.governorateById(governorateId).name;
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }
}
