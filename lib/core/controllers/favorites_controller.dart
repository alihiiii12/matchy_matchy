import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/data/category_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/product.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';

class FavoritesController extends GetxController {
  static FavoritesController get instance => Get.find<FavoritesController>();

  static const _storage = FlutterSecureStorage();

  final favoriteIds = <String>{}.obs;
  final _snapshots = <String, Product>{};
  int? _activeUserId;

  bool get canFavorite {
    final user = AuthService.instance.user;
    return user != null && !user.isSeller;
  }

  bool isFavorite(String productId) => favoriteIds.contains(productId);

  Product withFavorite(Product product) => product.copyWith(isFavorite: isFavorite(product.id));

  List<Product> get favorites {
    return favoriteIds
        .map((id) => _resolveProduct(id))
        .whereType<Product>()
        .map((product) => product.copyWith(isFavorite: true))
        .toList();
  }

  Future<void> switchUser(AuthUser? user) async {
    favoriteIds.clear();
    _snapshots.clear();
    favoriteIds.refresh();
    _activeUserId = user != null && !user.isSeller ? user.id : null;
    if (_activeUserId != null) {
      await _loadFromStorage(_activeUserId!);
    }
  }

  Future<void> toggle(Product product, {BuildContext? context}) async {
    if (!canFavorite) {
      _showMessage(
        context,
        AppStrings.loginToFavorite,
        success: false,
      );
      return;
    }

    final id = product.id;
    if (favoriteIds.contains(id)) {
      favoriteIds.remove(id);
      _snapshots.remove(id);
      _showMessage(context, AppStrings.removedFromFavorites, success: true);
    } else {
      favoriteIds.add(id);
      _snapshots[id] = product;
      _showMessage(context, AppStrings.addedToFavorites, success: true);
    }
    favoriteIds.refresh();
    await _persist();
  }

  Product? _resolveProduct(String productId) {
    final snapshot = _snapshots[productId];
    for (final product in CategoryCatalog.products) {
      if (product.id == productId) {
        return Product(
          id: product.id,
          name: product.name,
          brand: product.brand,
          price: product.price,
          categoryId: product.categoryId,
          subCategoryId: product.subCategoryId,
          sellerGovernorateId: product.sellerGovernorateId,
          imageUrl: product.imageUrl ?? snapshot?.imageUrl,
          icon: product.icon ?? snapshot?.icon,
          rating: product.rating,
          unit: product.unit ?? snapshot?.unit,
          freeDelivery: product.freeDelivery,
        );
      }
    }
    return snapshot;
  }

  Future<void> _persist() async {
    final userId = _activeUserId;
    if (userId == null) return;

    final payload = jsonEncode({
      'ids': favoriteIds.toList(),
      'products': favoriteIds
          .map((id) => _snapshots[id]?.toJson())
          .whereType<Map<String, dynamic>>()
          .toList(),
    });
    await _storage.write(key: _storageKey(userId), value: payload);
  }

  String _storageKey(int userId) => 'matchy_favorites_$userId';

  Future<void> _loadFromStorage(int userId) async {
    String? raw;
    try {
      raw = await _storage.read(key: _storageKey(userId));
    } catch (_) {
      try {
        await _storage.delete(key: _storageKey(userId));
      } catch (_) {}
      return;
    }
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ids = (decoded['ids'] as List<dynamic>? ?? []).cast<String>();
      final products = decoded['products'] as List<dynamic>? ?? [];

      favoriteIds
        ..clear()
        ..addAll(ids);
      _snapshots.clear();

      for (final item in products) {
        final map = item as Map<String, dynamic>;
        final product = Product.fromJson(map);
        _snapshots[product.id] = product;
      }

      for (final id in ids) {
        _snapshots.putIfAbsent(id, () {
          Product? resolved;
          for (final product in CategoryCatalog.products) {
            if (product.id == id) {
              resolved = product;
              break;
            }
          }
          return resolved ?? Product(
            id: id,
            name: AppStrings.product,
            brand: AppStrings.appName,
            price: 0,
            categoryId: 'groceries',
            subCategoryId: 'groc_snacks',
            sellerGovernorateId: 'damascus',
          );
        });
      }

      favoriteIds.refresh();
    } catch (_) {
      favoriteIds.clear();
      _snapshots.clear();
      favoriteIds.refresh();
    }
  }

  void _showMessage(BuildContext? context, String message, {required bool success}) {
    final ctx = context ?? Get.context;
    if (ctx == null) return;
    showAppSnackBar(
      ctx,
      message: message,
      type: success ? AppSnackBarType.success : AppSnackBarType.error,
      aboveBottomNav: true,
    );
  }
}
