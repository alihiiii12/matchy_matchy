import 'package:dio/dio.dart';

class _CacheEntry {
  _CacheEntry(this.response, this.expiresAt);

  final Response<Map<String, dynamic>> response;
  final DateTime expiresAt;

  bool get isValid => DateTime.now().isBefore(expiresAt);
}

/// In-memory GET cache + in-flight deduplication for faster UI with fewer server hits.
abstract final class ApiGetCache {
  static final _entries = <String, _CacheEntry>{};
  static final _inFlight = <String, Future<Response<Map<String, dynamic>>>>{};

  static const _defaultTtl = Duration(seconds: 20);

  static Duration ttlForPath(String path) {
    if (path.startsWith('/gifts')) return const Duration(seconds: 45);
    if (path.startsWith('/points/balance')) return const Duration(seconds: 15);
    if (path.startsWith('/categories') ||
        path.startsWith('/home-slides') ||
        path.startsWith('/home-advertisements') ||
        path.startsWith('/products') ||
        path.startsWith('/governorates')) {
      return const Duration(seconds: 60);
    }
    if (path.startsWith('/notifications/unread-count')) return const Duration(seconds: 10);
    return _defaultTtl;
  }

  static bool isCacheable(String path, {Map<String, dynamic>? query}) {
    if (query != null && query.isNotEmpty) return false;
    return path.startsWith('/gifts') ||
        path.startsWith('/points/balance') ||
        path.startsWith('/categories') ||
        path.startsWith('/home-slides') ||
        path.startsWith('/home-advertisements') ||
        path.startsWith('/products') ||
        path.startsWith('/governorates') ||
        path.startsWith('/notifications/unread-count');
  }

  static String _key(String path, Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return path;
    final sorted = query.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return '$path?${sorted.map((e) => '${e.key}=${e.value}').join('&')}';
  }

  static Future<Response<Map<String, dynamic>>> fetch(
    Dio dio,
    String path, {
    Map<String, dynamic>? query,
    bool force = false,
  }) async {
    final key = _key(path, query);
    final cacheable = isCacheable(path, query: query);

    if (cacheable && !force) {
      final cached = _entries[key];
      if (cached != null && cached.isValid) {
        return cached.response;
      }
      final pending = _inFlight[key];
      if (pending != null) return pending;
    } else if (force) {
      _entries.remove(key);
    }

    final future = dio.get<Map<String, dynamic>>(path, queryParameters: query);
    if (cacheable) {
      _inFlight[key] = future;
    }

    try {
      final response = await future;
      if (cacheable && response.statusCode == 200) {
        _entries[key] = _CacheEntry(response, DateTime.now().add(ttlForPath(path)));
      }
      return response;
    } finally {
      if (cacheable) {
        _inFlight.remove(key);
      }
    }
  }

  static void invalidatePrefix(String pathPrefix) {
    _entries.removeWhere((key, _) => key.startsWith(pathPrefix));
    _inFlight.removeWhere((key, _) => key.startsWith(pathPrefix));
  }

  static void clear() {
    _entries.clear();
    _inFlight.clear();
  }
}
