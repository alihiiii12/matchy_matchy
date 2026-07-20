import 'package:dio/dio.dart';

class MapSearchPlace {
  const MapSearchPlace({
    required this.displayName,
    required this.shortLabel,
    required this.latitude,
    required this.longitude,
  });

  final String displayName;
  final String shortLabel;
  final double latitude;
  final double longitude;
}

/// بحث عن المناطق عبر OpenStreetMap Nominatim (مجاني).
class NominatimSearchService {
  NominatimSearchService._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://nominatim.openstreetmap.org',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'User-Agent': 'MatchyMatchy/1.0 (com.matchymatchy.app; delivery-location-picker)',
        'Accept-Language': 'ar,en',
      },
    ),
  );

  static Future<List<MapSearchPlace>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    final response = await _dio.get<List<dynamic>>(
      '/search',
      queryParameters: {
        'q': '$trimmed, سوريا',
        'format': 'json',
        'limit': 8,
        'countrycodes': 'sy',
        'addressdetails': 1,
      },
    );

    final list = response.data ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(_parsePlace)
        .whereType<MapSearchPlace>()
        .toList();
  }

  static MapSearchPlace? _parsePlace(Map<String, dynamic> json) {
    final lat = double.tryParse(json['lat']?.toString() ?? '');
    final lon = double.tryParse(json['lon']?.toString() ?? '');
    if (lat == null || lon == null) return null;

    final displayName = json['display_name'] as String? ?? '';
    if (displayName.isEmpty) return null;

    final address = json['address'] as Map<String, dynamic>?;
    final shortLabel = _shortLabel(address, displayName);

    return MapSearchPlace(
      displayName: displayName,
      shortLabel: shortLabel,
      latitude: lat,
      longitude: lon,
    );
  }

  static String _shortLabel(Map<String, dynamic>? address, String fallback) {
    if (address == null) {
      return fallback.split(',').first.trim();
    }

    final parts = [
      address['neighbourhood'],
      address['suburb'],
      address['quarter'],
      address['city_district'],
      address['district'],
      address['town'],
      address['city'],
      address['village'],
      address['state'],
    ];

    for (final part in parts) {
      if (part is String && part.trim().isNotEmpty) {
        return part.trim();
      }
    }

    return fallback.split(',').first.trim();
  }
}
