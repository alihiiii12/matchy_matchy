import 'category_catalog.dart';

export 'category_catalog.dart';

/// Backward-compatible alias for existing screens.
abstract final class MockData {
  static const userName = CategoryCatalog.userName;
  static const userEmail = CategoryCatalog.userEmail;
  static List get products => CategoryCatalog.products;
  static const notifications = CategoryCatalog.notifications;
  static const messages = CategoryCatalog.messages;
  static const orders = CategoryCatalog.orders;
}
