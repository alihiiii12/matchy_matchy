import 'package:matchy_matchy/core/models/app_notification.dart';
import 'package:matchy_matchy/core/network/api_client.dart';

class NotificationRepository {
  NotificationRepository._();
  static final instance = NotificationRepository._();

  Future<NotificationFeed> fetchAll() async {
    final res = await ApiClient.instance.getJson('/notifications');
    final list = res.data!['data'] as List<dynamic>;
    final items = <AppNotificationItem>[];

    for (final entry in list) {
      if (entry is! Map<String, dynamic>) continue;
      try {
        final item = AppNotificationItem.fromJson(entry);
        if (item.id.isNotEmpty) {
          items.add(item);
        }
      } catch (_) {}
    }

    return NotificationFeed(
      items: items,
      unreadCount: (res.data!['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<int> fetchUnreadCount() async {
    final res = await ApiClient.instance.getJson('/notifications/unread-count');
    return (res.data!['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(String id) async {
    await ApiClient.instance.postJson('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await ApiClient.instance.postJson('/notifications/read-all');
  }

  Future<int> deleteNotification(String id) async {
    final res = await ApiClient.instance.deleteJson('/notifications/$id');
    ApiClient.instance.invalidateGetCache('/notifications');
    ApiClient.instance.invalidateGetCache('/notifications/unread-count');
    return (res.data!['unread_count'] as num?)?.toInt() ?? 0;
  }

  Future<void> deleteAll() async {
    await ApiClient.instance.postJson('/notifications/delete-all');
    ApiClient.instance.invalidateGetCache('/notifications');
    ApiClient.instance.invalidateGetCache('/notifications/unread-count');
  }

  Future<void> registerDeviceToken(String token, {String platform = 'android'}) async {
    await ApiClient.instance.postJson('/device-tokens', data: {
      'token': token,
      'platform': platform,
    });
  }

  Future<void> unregisterDeviceToken(String token) async {
    await ApiClient.instance.deleteJson('/device-tokens', data: {'token': token});
  }
}
