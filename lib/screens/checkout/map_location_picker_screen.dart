import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:matchy_matchy/core/data/delivery_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/services/location_service.dart';
import 'package:matchy_matchy/core/services/nominatim_search_service.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

/// شاشة اختيار موقع التوصيل — OpenStreetMap مع بحث عن المنطقة.
class MapLocationPickerScreen extends StatefulWidget {
  const MapLocationPickerScreen({super.key});

  static const _defaultCenter = LatLng(33.5138, 36.2765);
  static const userAgentPackageName = 'com.zadak.zadak';

  @override
  State<MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  final _mapController = MapController();
  final _searchController = TextEditingController();

  LatLng _selectedPoint = MapLocationPickerScreen._defaultCenter;
  List<MapSearchPlace> _searchResults = [];
  MapSearchPlace? _selectedPlace;
  bool _resolving = false;
  bool _searching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (DeliverySession.latitude != null && DeliverySession.longitude != null) {
      _selectedPoint = LatLng(DeliverySession.latitude!, DeliverySession.longitude!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _moveToPoint(LatLng point, {MapSearchPlace? place, double zoom = 16}) {
    setState(() {
      _selectedPoint = point;
      _selectedPlace = place;
      _searchResults = [];
      _error = null;
    });
    _mapController.move(point, zoom);
  }

  Future<void> _searchArea() async {
    final query = _searchController.text.trim();
    if (query.length < 2) {
      setState(() => _error = AppStrings.mapSearchQueryTooShort);
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
      _searchResults = [];
    });

    try {
      final results = await NominatimSearchService.search(query);
      if (!mounted) return;

      if (results.isEmpty) {
        setState(() {
          _searchResults = [];
          _error = AppStrings.mapSearchNoResults;
        });
        return;
      }

      setState(() => _searchResults = results);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = AppStrings.mapSearchFailed);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _useMyPositionOnMap() async {
    setState(() {
      _resolving = true;
      _error = null;
    });

    try {
      final result = await LocationService.detectWithPermission(requestIfNeeded: true);
      if (!result.isGranted || result.location == null) {
        setState(() {
          _error = LocationService.messageForStatus(result.status).isNotEmpty
              ? LocationService.messageForStatus(result.status)
              : AppStrings.locationFixFailed;
        });
        return;
      }

      final loc = result.location!;
      _moveToPoint(LatLng(loc.latitude, loc.longitude), zoom: 15);
    } catch (_) {
      setState(() => _error = AppStrings.locationFixFailed);
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  UserLocation _locationFromSelection(UserLocation base) {
    final place = _selectedPlace;
    if (place == null) return base;

    final govName = base.governorateName;
    final city = base.city.isNotEmpty ? base.city : govName;
    final area = place.shortLabel;

    return UserLocation(
      latitude: base.latitude,
      longitude: base.longitude,
      governorateId: base.governorateId,
      city: city,
      areaName: area,
      homeDescription: base.homeDescription,
      address: [govName, city, area].where((s) => s.isNotEmpty).join(' — '),
    );
  }

  Future<void> _confirm() async {
    if (_resolving) return;

    setState(() {
      _resolving = true;
      _error = null;
    });

    try {
      final point = _selectedPoint;

      UserLocation location;
      try {
        location = await LocationService.resolveAtCoordinates(
          point.latitude,
          point.longitude,
        ).timeout(const Duration(seconds: 6));
      } catch (_) {
        location = LocationService.buildFromCoordinates(point.latitude, point.longitude);
      }

      location = _locationFromSelection(location);
      DeliverySession.applyLocation(location);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      setState(() => _error = AppStrings.locationFixFailed);
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedLabel = _selectedPlace?.shortLabel ?? _selectedPlace?.displayName;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.mapPickerTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.mapPickerHintSearch,
                  style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _searchArea(),
                        decoration: InputDecoration(
                          hintText: AppStrings.mapSearchHint,
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: AppColors.inputFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _searching ? null : _searchArea,
                      child: _searching
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(AppStrings.mapSearch),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _resolving ? null : _useMyPositionOnMap,
                  icon: const Icon(Icons.my_location, size: 18),
                  label: Text(AppStrings.useMyLocation),
                ),
                if (selectedLabel != null && selectedLabel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.place, color: AppColors.success, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedLabel,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_error != null && _error!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 13)),
                  ),
                if (_searchResults.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final place = _searchResults[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_outlined, color: AppColors.accent),
                            title: Text(
                              place.shortLabel,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            subtitle: Text(
                              place.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            onTap: () => _moveToPoint(
                              LatLng(place.latitude, place.longitude),
                              place: place,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedPoint,
                initialZoom: 14,
                onTap: (_, point) => _moveToPoint(point),
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: MapLocationPickerScreen.userAgentPackageName,
                  maxNativeZoom: 19,
                  keepBuffer: 3,
                  retinaMode: false,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint,
                      width: 48,
                      height: 48,
                      child: const Icon(Icons.location_on, color: AppColors.accent, size: 48),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GradientButton(
              label: _resolving ? AppStrings.detectingLocation : AppStrings.confirmMapLocation,
              onPressed: _resolving ? null : _confirm,
            ),
          ),
        ],
      ),
    );
  }
}
