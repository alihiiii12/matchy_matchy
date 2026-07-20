import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/config/api_config.dart';

abstract final class CatalogMeta {
  static Color colorFromHex(String hex) {
    final value = hex.replaceFirst('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }

  static IconData categoryIcon(String id) {
    switch (id) {
      case 'fashion':
        return Icons.checkroom;
      case 'electronics':
        return Icons.devices;
      case 'mobiles':
        return Icons.smartphone;
      case 'laptops':
        return Icons.laptop_mac;
      case 'groceries':
        return Icons.shopping_basket;
      case 'vegetables':
        return Icons.eco;
      case 'food':
        return Icons.restaurant;
      case 'beverages':
        return Icons.local_cafe;
      case 'home':
        return Icons.home;
      case 'beauty':
        return Icons.spa;
      case 'sports':
        return Icons.fitness_center;
      default:
        return Icons.category;
    }
  }

  static IconData subCategoryIcon(String id) {
    if (id.contains('fashion_men')) return Icons.man;
    if (id.contains('fashion_women')) return Icons.woman;
    if (id.contains('fashion_kids')) return Icons.child_care;
    if (id.contains('shoes')) return Icons.ice_skating;
    if (id.contains('tv')) return Icons.tv;
    if (id.contains('cameras')) return Icons.camera_alt;
    if (id.contains('gaming')) return Icons.sports_esports;
    if (id.contains('phones')) return Icons.smartphone;
    if (id.contains('tablets')) return Icons.tablet;
    if (id.contains('chargers')) return Icons.battery_charging_full;
    if (id.contains('laptops')) return Icons.laptop;
    if (id.contains('monitors')) return Icons.monitor;
    if (id.contains('rice')) return Icons.rice_bowl;
    if (id.contains('oil')) return Icons.water_drop;
    if (id.contains('snacks')) return Icons.cookie;
    if (id.contains('cleaners')) return Icons.cleaning_services;
    if (id.contains('veg_fresh')) return Icons.grass;
    if (id.contains('fruits')) return Icons.apple;
    if (id.contains('organic')) return Icons.spa;
    if (id.contains('ready')) return Icons.lunch_dining;
    if (id.contains('frozen')) return Icons.ac_unit;
    if (id.contains('bakery')) return Icons.bakery_dining;
    if (id.contains('cold')) return Icons.local_drink;
    if (id.contains('hot')) return Icons.coffee;
    if (id.contains('juice')) return Icons.emoji_food_beverage;
    if (id.contains('water')) return Icons.water;
    if (id.contains('furniture')) return Icons.chair;
    if (id.contains('kitchen')) return Icons.kitchen;
    if (id.contains('skincare')) return Icons.face;
    if (id.contains('makeup')) return Icons.brush;
    if (id.contains('fitness')) return Icons.fitness_center;
    if (id.contains('outdoor')) return Icons.park;
    return Icons.inventory_2;
  }

  static IconData productIcon(String categoryId, String subCategoryId) {
    return subCategoryIcon(subCategoryId);
  }

  static String categoryImageUrl(String id) {
    switch (id) {
      case 'fashion':
        return _unsplash('photo-1489987707025-afc232f7ea0f');
      case 'electronics':
        return _unsplash('photo-1498049794561-7780e7231661');
      case 'mobiles':
        return _unsplash('photo-1511707171634-5f897ff02aa9');
      case 'laptops':
        return _unsplash('photo-1496181133206-80ce9b88a853');
      case 'groceries':
        return _unsplash('photo-1542838132-92c533df9100');
      case 'vegetables':
        return _unsplash('photo-1610832958506-aa56368172cf');
      case 'food':
        return _unsplash('photo-1504674900557-b0730c444636');
      case 'beverages':
        return _unsplash('photo-1544145945-f90425354b97');
      case 'home':
        return _unsplash('photo-1556909114-f6e7ad7d3136');
      case 'beauty':
        return _unsplash('photo-1596462502278-27bfad403625');
      case 'sports':
        return _unsplash('photo-1571019614242-c5c5dee66274');
      default:
        return _unsplash('photo-1472851294608-062f824d29cc');
    }
  }

  static String subCategoryImageUrl(String id, {String? categoryId}) {
    switch (id) {
      case 'fashion_men':
        return _unsplash('photo-1617137968427-85924c800a23');
      case 'fashion_women':
        return _unsplash('photo-1515372039744-b8f02a3ae446');
      case 'fashion_kids':
        return _unsplash('photo-1503342217505-9912288e4278');
      case 'fashion_shoes':
        return _unsplash('photo-1549298916-b41d501d3772');
      case 'fashion_accessories':
        return _unsplash('photo-1524805447924-3ffb68941a04');
      case 'elec_tv':
        return _unsplash('photo-1593359675889-d4bed24f7820');
      case 'elec_cameras':
        return _unsplash('photo-1516035069371-29a1b244cc32');
      case 'elec_gaming':
        return _unsplash('photo-1542751371-adc34648b617');
      case 'elec_wearables':
        return _unsplash('photo-1579583875558-c905a085eda5');
      case 'mob_phones':
        return _unsplash('photo-1511707171634-5f897ff02aa9');
      case 'mob_tablets':
        return _unsplash('photo-1544244015-0df4b3ffc6b0');
      case 'mob_cases':
        return _unsplash('photo-1601784551445-20c9d5630a40');
      case 'mob_chargers':
        return _unsplash('photo-1598327107778-268c1ac1f89f');
      case 'lap_laptops':
        return _unsplash('photo-1496181133206-80ce9b88a853');
      case 'lap_desktops':
        return _unsplash('photo-1587831990711-49e4a2ed1a04');
      case 'lap_monitors':
        return _unsplash('photo-1527443221259-4cf0fd5a74a5');
      case 'lap_accessories':
        return _unsplash('photo-1587829741301-dc79878389c7');
      case 'groc_rice':
        return _unsplash('photo-1586201375761-83865001e76c');
      case 'groc_oil':
        return _unsplash('photo-1474979266404-6ea6e4836188');
      case 'groc_canned':
        return _unsplash('photo-1587049359867-3cd3cd3c4ea1');
      case 'groc_snacks':
        return _unsplash('photo-1621935691919-23e90371e57d');
      case 'groc_cleaners':
        return _unsplash('photo-1583947213043-c7845c668b65');
      case 'veg_fresh':
        return _unsplash('photo-1540427739711-67a87126837c');
      case 'veg_fruits':
        return _unsplash('photo-1619568698925-26a2a6f5d2f5');
      case 'veg_organic':
        return _unsplash('photo-1542838132-92c533df9100');
      case 'veg_herbs':
        return _unsplash('photo-1466693900071-900eea25b540');
      case 'food_ready':
        return _unsplash('photo-1504674900557-b0730c444636');
      case 'food_frozen':
        return _unsplash('photo-1626677733821-c9a554acde37');
      case 'food_bakery':
        return _unsplash('photo-1509447296470-7d092764f683');
      case 'food_meat':
        return _unsplash('photo-1607628309925-43cf3d50c02f');
      case 'bev_cold':
        return _unsplash('photo-1544145945-f90425354b97');
      case 'bev_hot':
        return _unsplash('photo-1495474472287-864d588e2b48');
      case 'bev_juice':
        return _unsplash('photo-1603569283848-1858ed9a9e24');
      case 'bev_water':
        return _unsplash('photo-1548839140-b0f2d4ce7fe3');
      case 'home_furniture':
        return _unsplash('photo-1555041469-a586c61ea9bc');
      case 'home_kitchen':
        return _unsplash('photo-1556909114-f6e7ad7d3136');
      case 'home_decor':
        return _unsplash('photo-1513694204233-34568a72b78a');
      case 'home_appliances':
        return _unsplash('photo-1584623450089-5b3ccae58d25');
      case 'beauty_skincare':
        return _unsplash('photo-1596462502278-27bfad403625');
      case 'beauty_makeup':
        return _unsplash('photo-1522335789203-a985b43899da');
      case 'beauty_hair':
        return _unsplash('photo-1522337367819-69166ea370ca');
      case 'beauty_health':
        return _unsplash('photo-1576091160399-112ba8d25d1f');
      case 'sport_fitness':
        return _unsplash('photo-1571019614242-c5c5dee66274');
      case 'sport_outdoor':
        return _unsplash('photo-1478131143081-14f2e45e66c8');
      case 'sport_team':
        return _unsplash('photo-1461896836934-ffe6072912c7');
      case 'sport_cycling':
        return _unsplash('photo-1485965120188-e220f721d981');
      default:
        if (categoryId != null) return categoryImageUrl(categoryId);
        return _unsplash('photo-1472851294608-062f824d29cc');
    }
  }

  static String? resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    if (url.contains('picsum.photos')) return null;

    final trimmed = url.trim();
    final apiOrigin = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api$'), '');

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null && uri.path.startsWith('/storage/')) {
        return '$apiOrigin${uri.path}';
      }
      if (uri != null && _isAuthenticatedApiPath(uri.path)) {
        return trimmed;
      }
      return trimmed;
    }

    if (_isAuthenticatedApiPath(trimmed)) {
      final path = trimmed.startsWith('/api/') ? trimmed : '/api$trimmed';
      return '$apiOrigin$path';
    }

    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    final storagePath = path.startsWith('/storage/') ? path : '/storage$path';

    return '$apiOrigin$storagePath';
  }

  static bool isAuthenticatedApiImage(String? url) {
    final apiPath = apiPathFromUrl(url);
    return apiPath != null && _isAuthenticatedApiPath(apiPath);
  }

  static String? apiPathFromUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;

    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);

    if (uri != null && uri.hasScheme) {
      if (!_isAuthenticatedApiPath(uri.path)) return null;
      final query = uri.query.isNotEmpty ? '?${uri.query}' : '';
      return '${uri.path.replaceFirst('/api', '')}$query';
    }

    if (trimmed.startsWith('/api/')) {
      return trimmed.replaceFirst('/api', '');
    }

    if (_isAuthenticatedApiPath(trimmed)) {
      return trimmed;
    }

    return null;
  }

  static bool _isAuthenticatedApiPath(String path) {
    return path.contains('/auth/avatar') ||
        path.contains('/id-front') ||
        path.contains('/id-back');
  }

  static String _unsplash(String photoId) =>
      'https://images.unsplash.com/$photoId?auto=format&fit=crop&w=400&h=400&q=80';
}
