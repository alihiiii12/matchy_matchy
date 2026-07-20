import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:matchy_matchy/core/models/product.dart';
import 'package:matchy_matchy/core/network/api_client.dart';

class AdminProductsRepository {
  AdminProductsRepository._();
  static final instance = AdminProductsRepository._();

  Future<List<Product>> fetchAll({String? categoryId, String? q}) async {
    final res = await ApiClient.instance.getJson(
      '/admin/products',
      query: {
        if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
        if (q != null && q.isNotEmpty) 'q': q,
      },
      force: true,
    );
    final list = res.data!['data'] as List<dynamic>;
    return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Product> fetchById(String id) async {
    final res = await ApiClient.instance.getJson('/admin/products/$id', force: true);
    return Product.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<Product> create({
    required String name,
    String? nameEn,
    required String categoryId,
    required String subCategoryId,
    required String sellerGovernorateId,
    required double price,
    required File image,
    String? unit,
    int? points,
    bool freeDelivery = false,
    List<Map<String, dynamic>>? pieces,
    Map<String, double>? rolePrices,
  }) async {
    final fields = <String, dynamic>{
      'name': name,
      if (nameEn != null) 'name_en': nameEn,
      'category_id': categoryId,
      'sub_category_id': subCategoryId,
      'seller_governorate_id': sellerGovernorateId,
      'price': price.toString(),
      if (unit != null) 'unit': unit,
      if (points != null) 'points': points.toString(),
      'free_delivery': freeDelivery ? '1' : '0',
      if (pieces != null) 'pieces': jsonEncode(pieces),
      if (rolePrices != null) 'role_prices': jsonEncode(rolePrices),
    };

    final res = await ApiClient.instance.postMultipart(
      '/admin/products',
      fields: fields,
      files: {
        'image': await MultipartFile.fromFile(
          image.path,
          filename: image.path.split(Platform.pathSeparator).last,
        ),
      },
    );

    ApiClient.instance.invalidateGetCache('/products');
    ApiClient.instance.invalidateGetCache('/admin/products');
    return Product.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<Product> update({
    required String id,
    required String name,
    String? nameEn,
    required String categoryId,
    required String subCategoryId,
    required String sellerGovernorateId,
    required double price,
    String? unit,
    int? points,
    bool freeDelivery = false,
    File? image,
    List<Map<String, dynamic>>? pieces,
    Map<String, double>? rolePrices,
  }) async {
    final jsonBody = <String, dynamic>{
      'name': name,
      if (nameEn != null) 'name_en': nameEn,
      'category_id': categoryId,
      'sub_category_id': subCategoryId,
      'seller_governorate_id': sellerGovernorateId,
      'price': price,
      if (unit != null) 'unit': unit,
      if (points != null) 'points': points,
      'free_delivery': freeDelivery,
      if (pieces != null) 'pieces': pieces,
      if (rolePrices != null) 'role_prices': rolePrices,
    };

    final Response<Map<String, dynamic>> res;
    if (image != null) {
      res = await ApiClient.instance.patchMultipart(
        '/admin/products/$id',
        fields: {
          'name': name,
          if (nameEn != null) 'name_en': nameEn,
          'category_id': categoryId,
          'sub_category_id': subCategoryId,
          'seller_governorate_id': sellerGovernorateId,
          'price': price.toString(),
          if (unit != null) 'unit': unit,
          if (points != null) 'points': points.toString(),
          'free_delivery': freeDelivery ? '1' : '0',
          if (pieces != null) 'pieces': jsonEncode(pieces),
          if (rolePrices != null) 'role_prices': jsonEncode(rolePrices),
        },
        files: {
          'image': await MultipartFile.fromFile(
            image.path,
            filename: image.path.split(Platform.pathSeparator).last,
          ),
        },
      );
    } else {
      res = await ApiClient.instance.patchJson('/admin/products/$id', data: jsonBody);
    }

    ApiClient.instance.invalidateGetCache('/products');
    ApiClient.instance.invalidateGetCache('/admin/products');
    return Product.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await ApiClient.instance.deleteJson('/admin/products/$id');
    ApiClient.instance.invalidateGetCache('/products');
    ApiClient.instance.invalidateGetCache('/admin/products');
  }
}