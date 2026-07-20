class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final String createdAt;
  final Map<String, dynamic>? data;

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    return AppNotificationItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at']?.toString() ?? '',
      data: _parseData(json['data']),
    );
  }

  static Map<String, dynamic>? _parseData(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  String get timeLabel {
    if (createdAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'الآن';
      if (diff.inHours < 1) return 'منذ ${diff.inMinutes} د';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return createdAt;
    }
  }

  int? get orderId {
    final raw = data?['order_id'];
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  String? get deliveryId {
    final raw = data?['delivery_id'];
    if (raw == null) return null;
    return raw.toString();
  }

  bool get canConfirmArrival => type == 'awaiting_receipt';

  int? get submissionId {
    final raw = data?['submission_id'];
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  bool get isProductSubmission => type == 'admin_product_submission';

  bool get isSellerProductType =>
      type == 'seller_product_approved' || type == 'seller_product_rejected';

  bool get isSellerOrderType =>
      type == 'seller_new_order' || type == 'seller_prepare_order';

  bool get isSellerAccountType =>
      type.startsWith('seller_subscription_') || type == 'seller_account_blocked';

  bool get isDriverAccountType =>
      type.startsWith('driver_subscription_') || type == 'driver_account_blocked';

  bool get isSellerType => type.startsWith('seller_');

  bool get isDriverType => type.startsWith('driver_');

  bool get isAdminType => type.startsWith('admin_');
}

class NotificationFeed {
  const NotificationFeed({required this.items, required this.unreadCount});

  final List<AppNotificationItem> items;
  final int unreadCount;
}
