import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:matchy_matchy/core/network/api_client.dart';

abstract final class AuthenticatedImageLoader {
  static Future<Uint8List?> loadBytes(String apiPath) async {
    final path = apiPath.startsWith('/') ? apiPath : '/$apiPath';

    try {
      final response = await ApiClient.instance.dio.get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data == null || data.isEmpty) return null;
      return Uint8List.fromList(data);
    } catch (_) {
      return null;
    }
  }
}
