import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/data/category_catalog.dart';
import 'package:matchy_matchy/core/data/delivery_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/cart_item.dart';
import 'package:matchy_matchy/core/models/product.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/repositories/catalog_repository.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class CartController extends GetxController {
  static CartController get instance => Get.find<CartController>();

  static const _storage = FlutterSecureStorage();

  final cartItems = <CartItem>[].obs;
  final _map = <String, CartItem>{};
  int? _activeUserId;

  List<CartItem> get items => cartItems;

  bool get canShop {
    final user = AuthService.instance.user;
    return user != null && user.isCustomer;
  }

  bool get isEmpty => _map.isEmpty;

  int get totalCount => cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => cartItems.fold(0.0, (sum, item) => sum + item.lineTotal);

  int quantityOf(String productId) {
    var total = 0;
    for (final item in _map.values) {
      if (item.product.id == productId) total += item.quantity;
    }
    return total;
  }

  Future<void> switchUser(AuthUser? user) async {
    _map.clear();
    _sync();
    _activeUserId = user != null && user.isCustomer ? user.id : null;
    if (_activeUserId != null) {
      await _loadFromStorage(_activeUserId!);
      if (CatalogRepository.instance.isFromApi) {
        unawaited(pruneUnavailableItems());
      }
    }
  }

  void _sync() => cartItems.assignAll(_map.values);

  Future<void> _persist() async {
    final userId = _activeUserId;
    if (userId == null) return;

    final payload = jsonEncode({
      'items': _map.values
          .map((item) => {
                'product_id': item.product.id,
                'quantity': item.quantity,
                if (item.options != null) 'options': item.options,
              })
          .toList(),
    });
    await _storage.write(key: _cartStorageKey(userId), value: payload);
  }

  String _cartStorageKey(int userId) => 'matchy_cart_$userId';

  Future<void> _loadFromStorage(int userId) async {
    String? raw;
    try {
      raw = await _storage.read(key: _cartStorageKey(userId));
    } catch (_) {
      try {
        await _storage.delete(key: _cartStorageKey(userId));
      } catch (_) {}
      return;
    }
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final items = decoded['items'] as List<dynamic>? ?? [];
      for (final item in items) {
        final map = item as Map<String, dynamic>;
        final productId = map['product_id'] as String?;
        final quantity = map['quantity'] as int? ?? 1;
        if (productId == null || quantity <= 0) continue;

        final product = await _resolveProduct(productId);
        if (product == null) continue;
        final options = map['options'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(map['options'] as Map)
            : null;
        final cartItem = CartItem(product: product, quantity: quantity, options: options);
        _map[cartItem.cartKey] = cartItem;
      }
      _sync();
    } catch (_) {
      await _storage.delete(key: _cartStorageKey(userId));
    }
  }

  Future<Product?> _resolveProduct(String productId) async {
    final cached = CategoryCatalog.productById(productId);
    if (cached != null) return cached;

    try {
      final res = await ApiClient.instance.getJson('/products/$productId');
      return Product.fromJson(res.data!['data'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Removes cart lines whose product no longer exists on the server.
  Future<int> pruneUnavailableItems() async {
    if (!canShop || _map.isEmpty) return 0;

    final toRemove = <String>[];
    for (final entry in _map.entries) {
      final productId = entry.value.product.id;
      if (CatalogRepository.instance.isFromApi) {
        if (CategoryCatalog.productById(productId) == null) {
          toRemove.add(entry.key);
        }
      } else if (!await _productExistsOnServer(productId)) {
        toRemove.add(entry.key);
      }
    }

    for (final key in toRemove) {
      _map.remove(key);
    }

    if (toRemove.isNotEmpty) {
      _sync();
      await _persist();
    }
    return toRemove.length;
  }

  Future<bool> _productExistsOnServer(String productId) async {
    try {
      await ApiClient.instance.getJson('/products/$productId');
      return true;
    } catch (_) {
      return false;
    }
  }

  bool add(Product product, {int quantity = 1, Map<String, dynamic>? options}) {
    if (!canShop) return false;
    if (!CatalogRepository.instance.isFromApi) {
      showZadakSnackBar(
        message: 'تعذر الاتصال بالمتجر. تحقق من الشبكة ثم أعد فتح التطبيق.',
        type: AppSnackBarType.error,
      );
      return false;
    }

    final item = CartItem(product: product, quantity: quantity, options: options);
    final key = item.cartKey;
    final existing = _map[key];
    if (existing != null) {
      existing.quantity += quantity;
    } else {
      _map[key] = item;
    }
    _sync();
    _persist();
    return true;
  }

  void setQuantity(String cartKey, int quantity) {
    if (!canShop) return;
    if (!_map.containsKey(cartKey)) return;
    if (quantity <= 0) {
      remove(cartKey);
      return;
    }
    _map[cartKey]!.quantity = quantity;
    _sync();
    _persist();
  }

  void increment(String cartKey) {
    if (!canShop) return;
    final item = _map[cartKey];
    if (item == null) return;
    item.quantity++;
    _sync();
    _persist();
  }

  void decrement(String cartKey) {
    if (!canShop) return;
    final item = _map[cartKey];
    if (item == null) return;
    if (item.quantity <= 1) {
      remove(cartKey);
    } else {
      item.quantity--;
      _sync();
      _persist();
    }
  }

  void remove(String cartKey) {
    if (!canShop) return;
    if (_map.remove(cartKey) != null) {
      _sync();
      _persist();
    }
  }

  void removeItem(String cartKey, {String? productName}) {
    if (!_map.containsKey(cartKey)) return;
    remove(cartKey);
    if (productName != null && productName.isNotEmpty) {
      showZadakSnackBar(
        title: AppStrings.myCart,
        message: AppStrings.itemRemovedFromCart,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> clear() async {
    if (_map.isEmpty) return;
    _map.clear();
    _sync();
    await _persist();
  }

  List<Product> productsForDelivery() {
    return items.expand((item) => List<Product>.filled(item.quantity, item.product)).toList();
  }

  void continueShopping() => Get.offAllNamed(AppRoutes.main);

  void checkout() {
    if (!canShop || isEmpty) return;
    DeliverySession.resetCheckout();
    Get.toNamed(AppRoutes.checkoutAddress, arguments: subtotal);
  }
}

class CartBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController(), permanent: true);
    }
  }
}
