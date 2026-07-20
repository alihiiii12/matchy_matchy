import 'dart:io';

import 'package:dio/dio.dart';
import 'package:matchy_matchy/core/network/api_client.dart';

class CustomOutfitRepository {
  CustomOutfitRepository._();
  static final instance = CustomOutfitRepository._();

  Future<List<Map<String, dynamic>>> fetchMine() async {
    final res = await ApiClient.instance.getJson('/custom-outfit-requests', force: true);
    return (res.data!['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> create({
    required String fabricDescription,
    required String sizesDescription,
    double? budget,
    String? notes,
    File? image,
  }) async {
    if (image != null) {
      final res = await ApiClient.instance.postMultipart(
        '/custom-outfit-requests',
        fields: {
          'fabric_description': fabricDescription,
          'sizes_description': sizesDescription,
          if (budget != null) 'budget': budget.toString(),
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
        files: {
          'image': await MultipartFile.fromFile(
            image.path,
            filename: image.path.split(Platform.pathSeparator).last,
          ),
        },
      );
      return res.data!['data'] as Map<String, dynamic>;
    }

    final res = await ApiClient.instance.postJson(
      '/custom-outfit-requests',
      data: {
        'fabric_description': fabricDescription,
        'sizes_description': sizesDescription,
        if (budget != null) 'budget': budget,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return res.data!['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> adminFetch({String? status}) async {
    final res = await ApiClient.instance.getJson(
      '/admin/custom-outfit-requests',
      query: status != null ? {'status': status} : null,
      force: true,
    );
    return (res.data!['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> adminSetPrice({
    required int id,
    required double quotedPrice,
    String? adminNotes,
  }) async {
    final res = await ApiClient.instance.postJson(
      '/admin/custom-outfit-requests/$id/set-price',
      data: {
        'quoted_price': quotedPrice,
        if (adminNotes != null && adminNotes.isNotEmpty) 'admin_notes': adminNotes,
      },
    );
    return res.data!['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> adminReject({required int id, String? adminNotes}) async {
    final res = await ApiClient.instance.postJson(
      '/admin/custom-outfit-requests/$id/reject',
      data: {
        if (adminNotes != null && adminNotes.isNotEmpty) 'admin_notes': adminNotes,
      },
    );
    return res.data!['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> adminConvertToOrder(int id) async {
    final res = await ApiClient.instance.postJson(
      '/admin/custom-outfit-requests/$id/convert-to-order',
      data: {},
    );
    return res.data! as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> pay({
    required int id,
    required String paymentMethod,
    String? address,
    String? city,
    String? areaName,
  }) async {
    final res = await ApiClient.instance.postJson(
      '/custom-outfit-requests/$id/pay',
      data: {
        'payment_method': paymentMethod,
        if (address != null && address.isNotEmpty) 'address': address,
        if (city != null && city.isNotEmpty) 'city': city,
        if (areaName != null && areaName.isNotEmpty) 'area_name': areaName,
      },
    );
    return res.data! as Map<String, dynamic>;
  }
}
