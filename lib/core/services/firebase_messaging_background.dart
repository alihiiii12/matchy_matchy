import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // FCM already shows tray notifications when `notification` payload exists.
  if (message.notification != null) {
    return;
  }

  final title = message.data['title']?.toString() ?? '';
  final body = message.data['body']?.toString() ?? '';
  if (title.isEmpty && body.isEmpty) return;

  final plugin = FlutterLocalNotificationsPlugin();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(const InitializationSettings(android: android));

  final notificationId = message.data['notification_id']?.toString();

  await plugin.show(
    message.hashCode,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'matchy_matchy_orders',
        'إشعارات روزي تاج',
        channelDescription: 'تحديثات الطلبات والمنتجات والتوصيل',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    payload: notificationId,
  );
}
