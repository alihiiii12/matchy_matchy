import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:matchy_matchy/core/config/api_config.dart';
import 'package:matchy_matchy/core/network/api_get_cache.dart';
import 'package:matchy_matchy/core/network/connectivity_interceptor.dart';

class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(ConnectivityInterceptor());

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            // أبقِ العنوان متزامناً مع ApiConfig (مثلاً بعد تغيير IP / adb reverse).
            options.baseUrl = ApiConfig.baseUrl;
            final token = await _readTokenSafe();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            if (options.data is FormData) {
              options.headers.remove('Content-Type');
            }
            handler.next(options);
          } catch (e, st) {
            if (kDebugMode) {
              debugPrint('ApiClient onRequest error: $e\n$st');
            }
            // لا تعلّق الطلب أبداً — حتى لو فشل التخزين الآمن.
            handler.next(options);
          }
        },
      ),
    );
  }

  static final instance = ApiClient._();

  static const _tokenKey = 'auth_token';
  final _storage = const FlutterSecureStorage();
  late final Dio _dio;
  bool _clearedCorruptStorage = false;

  Dio get dio => _dio;

  Future<String?> _readTokenSafe() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecureStorage token read failed: $e');
      }
      await _resetCorruptStorage();
      return null;
    }
  }

  Future<void> _resetCorruptStorage() async {
    if (_clearedCorruptStorage) return;
    _clearedCorruptStorage = true;
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {}
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }

  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecureStorage token write failed: $e');
      }
      await _resetCorruptStorage();
      try {
        await _storage.write(key: _tokenKey, value: token);
      } catch (_) {}
    }
  }

  Future<void> clearToken() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {
      await _resetCorruptStorage();
    }
  }

  Future<String?> getToken() => _readTokenSafe();

  Future<Response<Map<String, dynamic>>> getJson(
    String path, {
    Map<String, dynamic>? query,
    bool force = false,
  }) async {
    if (ApiGetCache.isCacheable(path, query: query)) {
      return ApiGetCache.fetch(_dio, path, query: query, force: force);
    }
    final response = await _dio.get<Map<String, dynamic>>(path, queryParameters: query);
    return response;
  }

  void invalidateGetCache(String pathPrefix) => ApiGetCache.invalidatePrefix(pathPrefix);

  void clearGetCache() => ApiGetCache.clear();

  Future<Response<Map<String, dynamic>>> postJson(
    String path, {
    Map<String, dynamic>? data,
    Duration? receiveTimeout,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: data,
      options: receiveTimeout == null
          ? null
          : Options(receiveTimeout: receiveTimeout, sendTimeout: receiveTimeout),
    );
    return response;
  }

  Future<Response<Map<String, dynamic>>> postMultipart(
    String path, {
    required Map<String, dynamic> fields,
    Map<String, MultipartFile>? files,
  }) async {
    final formData = FormData.fromMap({...fields, ...?files});
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: formData,
      options: Options(
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 120),
      ),
    );
    return response;
  }

  Future<Response<Map<String, dynamic>>> patchMultipart(
    String path, {
    required Map<String, dynamic> fields,
    Map<String, MultipartFile>? files,
  }) async {
    // PHP only parses multipart bodies on POST, not PATCH.
    final formData = FormData.fromMap({
      '_method': 'PATCH',
      ...fields,
      ...?files,
    });
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: formData,
      options: Options(
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 120),
      ),
    );
    return response;
  }

  Future<Response<Map<String, dynamic>>> patchJson(String path, {Map<String, dynamic>? data}) async {
    final response = await _dio.patch<Map<String, dynamic>>(path, data: data);
    return response;
  }

  Future<Response<Map<String, dynamic>>> deleteJson(String path, {Map<String, dynamic>? data}) async {
    final response = await _dio.delete<Map<String, dynamic>>(path, data: data);
    return response;
  }
}
