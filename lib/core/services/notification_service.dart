import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:matchy_matchy/core/controllers/admin_orders_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_product_submissions_controller.dart';
import 'package:matchy_matchy/core/controllers/driver_subscriptions_controller.dart';
import 'package:matchy_matchy/core/controllers/seller_subscriptions_controller.dart';
import 'package:matchy_matchy/core/services/notification_navigation.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/app_notification.dart';
import 'package:matchy_matchy/core/repositories/notification_repository.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:matchy_matchy/routing/app_routes.dart';
import 'package:matchy_matchy/screens/admin/admin_orders_screen.dart';

/// In-app alerts while open; FCM system tray when background/closed.
class NotificationService extends GetxService with WidgetsBindingObserver {
  static NotificationService get instance => Get.find<NotificationService>();

  final unreadCount = 0.obs;
  final items = <AppNotificationItem>[].obs;
  final loading = false.obs;
  final error = RxnString();
  final fcmReady = false.obs;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  FirebaseMessaging? _messagingOrNull;
  FirebaseMessaging get _messaging => _messagingOrNull ??= FirebaseMessaging.instance;
  final Set<String> _knownIds = {};
  Timer? _pollTimer;
  int _pollTick = 0;
  bool _primed = false;
  bool _isInForeground = true;
  String? _fcmToken;

  static const _androidChannel = AndroidNotificationChannel(
    'matchy_matchy_orders',
    'إشعارات روزي تاج',
    description: 'تحديثات الطلبات والمنتجات والتوصيل',
    importance: Importance.high,
  );

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<NotificationService> init() async {
    try {
      await _initPlugin().timeout(const Duration(seconds: 2));
    } catch (_) {}
    try {
      await requestPermission().timeout(const Duration(seconds: 2));
    } catch (_) {}
    try {
      await _initFirebaseMessaging().timeout(const Duration(seconds: 2));
    } catch (_) {
      fcmReady.value = false;
    }
    return this;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasForeground = _isInForeground;
    _isInForeground = state == AppLifecycleState.resumed || state == AppLifecycleState.inactive;

    if (_isInForeground && !wasForeground && AuthService.instance.isLoggedIn) {
      refresh(pushNew: false);
    }
  }

  Future<void> _initPlugin() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_androidChannel);
  }

  Future<void> _initFirebaseMessaging() async {
    if (kIsWeb) return;

    // بدون google-services.json لروزي تاج — إشعارات التطبيق عبر الـ API فقط
    try {
      if (Firebase.apps.isEmpty) {
        fcmReady.value = false;
        return;
      }
    } catch (_) {
      fcmReady.value = false;
      return;
    }

    try {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        unawaited(refresh(pushNew: false));
        _scheduleOpenFromRemoteData(initial.data);
      }

      _messaging.onTokenRefresh.listen((token) async {
        _fcmToken = token;
        await _registerDeviceToken(token);
      });

      fcmReady.value = true;
    } catch (_) {
      fcmReady.value = false;
    }
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      if (granted == true) return true;
      final status = await Permission.notification.request();
      return status.isGranted;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    return true;
  }

  Future<void> syncDeviceToken() async {
    if (kIsWeb || !fcmReady.value) return;
    if (!AuthService.instance.isLoggedIn) return;

    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      _fcmToken = token;
      await _registerDeviceToken(token);
    } catch (_) {}
  }

  Future<void> unregisterDevice() async {
    final token = _fcmToken;
    if (token == null || token.isEmpty) return;

    try {
      await NotificationRepository.instance.unregisterDeviceToken(token);
    } catch (_) {}

    try {
      await _messaging.deleteToken();
    } catch (_) {}

    _fcmToken = null;
  }

  Future<void> _registerDeviceToken(String token) async {
    if (!AuthService.instance.isLoggedIn) return;

    final platform = Platform.isIOS ? 'ios' : 'android';
    await NotificationRepository.instance.registerDeviceToken(token, platform: platform);
  }

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      if (!AuthService.instance.isLoggedIn) return;

      _pollTick++;
      if (_pollTick.isEven) {
        await refresh(pushNew: true);
      } else {
        await _refreshUnreadOnly();
      }
    });
  }

  Future<void> _refreshUnreadOnly() async {
    if (!AuthService.instance.isLoggedIn) return;

    try {
      final count = await NotificationRepository.instance.fetchUnreadCount();
      final previous = unreadCount.value;
      unreadCount.value = count;

      if (count > previous) {
        await refresh(pushNew: true);
      }
    } catch (_) {}
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> refresh({bool pushNew = true}) async {
    if (!AuthService.instance.isLoggedIn) {
      unreadCount.value = 0;
      items.clear();
      _knownIds.clear();
      _primed = false;
      return;
    }

    await syncDeviceToken();

    loading.value = true;
    error.value = null;
    try {
      final feed = await NotificationRepository.instance.fetchAll();
      items.value = feed.items;
      unreadCount.value = feed.unreadCount;

      _refreshRelatedScreens(feed.items);

      if (!_primed) {
        for (final notification in feed.items) {
          _knownIds.add(notification.id);
          if (pushNew &&
              !notification.isRead &&
              _isRecentNotification(notification) &&
              _isInForeground) {
            _showInAppAlert(notification);
          }
        }
        _primed = true;
        return;
      }

      if (!pushNew) {
        _knownIds.addAll(feed.items.map((e) => e.id));
        return;
      }

      for (final notification in feed.items) {
        if (_knownIds.contains(notification.id)) continue;
        _knownIds.add(notification.id);

        if (_isInForeground && !notification.isRead) {
          _showInAppAlert(notification);
        }
      }
    } catch (_) {
      error.value = 'تعذر تحميل الإشعارات';
    } finally {
      loading.value = false;
    }
  }

  Future<void> markRead(String id) async {
    await NotificationRepository.instance.markRead(id);
    final index = items.indexWhere((e) => e.id == id);
    if (index >= 0) {
      final current = items[index];
      items[index] = AppNotificationItem(
        id: current.id,
        type: current.type,
        title: current.title,
        body: current.body,
        isRead: true,
        createdAt: current.createdAt,
        data: current.data,
      );
      items.refresh();
    }
    if (unreadCount.value > 0) {
      unreadCount.value--;
    }
  }

  Future<void> markAllRead() async {
    await NotificationRepository.instance.markAllRead();
    items.value = items
        .map(
          (n) => AppNotificationItem(
            id: n.id,
            type: n.type,
            title: n.title,
            body: n.body,
            isRead: true,
            createdAt: n.createdAt,
            data: n.data,
          ),
        )
        .toList();
    unreadCount.value = 0;
  }

  Future<void> deleteNotification(String id) async {
    final unread = await NotificationRepository.instance.deleteNotification(id);
    items.removeWhere((e) => e.id == id);
    _knownIds.remove(id);
    unreadCount.value = unread;
  }

  Future<void> deleteAllNotifications() async {
    await NotificationRepository.instance.deleteAll();
    items.clear();
    _knownIds.clear();
    unreadCount.value = 0;
  }

  Future<void> handleNotificationTap({AppNotificationItem? notification, String? notificationId}) async {
    AppNotificationItem? item = notification;

    if (item == null && notificationId != null && notificationId.isNotEmpty) {
      item = items.firstWhereOrNull((e) => e.id == notificationId);
      if (item == null) {
        await refresh(pushNew: false);
        item = items.firstWhereOrNull((e) => e.id == notificationId);
      }
    }

    if (item == null) {
      await NotificationNavigation.openFromPayload(type: 'admin_broadcast', data: const {});
      return;
    }

    if (!item.isRead) {
      await markRead(item.id);
    }

    await openNotification(item);
  }

  Future<void> openNotification(AppNotificationItem notification) async {
    await NotificationNavigation.open(notification);
  }

  void _showInAppAlert(AppNotificationItem notification) {
    if (!_isInForeground || Get.key.currentState == null) return;
    if (Get.currentRoute == AppRoutes.notifications) return;

    _showTopBanner(
      title: notification.title,
      body: notification.body,
      onOpen: () => handleNotificationTap(notification: notification),
    );
  }

  void _showTopBanner({
    required String title,
    required String body,
    required VoidCallback onOpen,
  }) {
    showZadakSnackBar(
      title: title,
      message: body,
      duration: const Duration(seconds: 4),
      position: SnackPosition.TOP,
      aboveBottomNav: false,
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      onTap: onOpen,
      actionLabel: AppStrings.viewNotification,
      onAction: onOpen,
    );
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notificationId = message.data['notification_id']?.toString();
    if (notificationId != null && notificationId.isNotEmpty) {
      _knownIds.add(notificationId);
    }

    if (_isInForeground) {
      final title = message.notification?.title ??
          message.data['title']?.toString() ??
          '';
      final body = message.notification?.body ??
          message.data['body']?.toString() ??
          '';

      if (title.isNotEmpty || body.isNotEmpty) {
        _showTopBanner(
          title: title.isNotEmpty ? title : AppStrings.notifications,
          body: body.isNotEmpty ? body : title,
          onOpen: () {
            if (notificationId != null && notificationId.isNotEmpty) {
              handleNotificationTap(notificationId: notificationId);
              return;
            }
            _scheduleOpenFromRemoteData(message.data);
          },
        );
      }
    }

    unawaited(refresh(pushNew: false));
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    unawaited(_openFromRemoteMessage(message));
  }

  Future<void> _openFromRemoteMessage(RemoteMessage message) async {
    await NotificationNavigation.waitUntilReady();
    await refresh(pushNew: false);
    await _openFromRemoteData(message.data);
  }

  Future<void> _openFromRemoteData(Map<String, dynamic> data) async {
    if (Get.key.currentState == null) return;

    final notificationId = data['notification_id']?.toString();
    if (notificationId != null && notificationId.isNotEmpty) {
      await handleNotificationTap(notificationId: notificationId);
      return;
    }

    final type = data['type']?.toString() ?? '';
    final orderId = int.tryParse('${data['order_id'] ?? ''}');

    await NotificationNavigation.openFromPayload(
      type: type,
      data: data,
      orderId: orderId,
    );
  }

  void _scheduleOpenFromRemoteData(Map<String, dynamic> data) {
    unawaited(_openFromRemoteDataWhenReady(data));
  }

  Future<void> _openFromRemoteDataWhenReady(Map<String, dynamic> data) async {
    await NotificationNavigation.waitUntilReady();
    await refresh(pushNew: false);
    await _openFromRemoteData(data);
  }

  void _onNotificationTap(NotificationResponse response) {
    unawaited(_handleLocalNotificationTap(response));
  }

  Future<void> _handleLocalNotificationTap(NotificationResponse response) async {
    await NotificationNavigation.waitUntilReady();

    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      await NotificationNavigation.openFromPayload(
        type: 'admin_broadcast',
        data: const {},
      );
      return;
    }

    await handleNotificationTap(notificationId: payload);
  }

  void _refreshRelatedScreens(List<AppNotificationItem> notifications) {
    final user = AuthService.instance.user;
    if (user == null) return;

    final unread = notifications.where((n) => !n.isRead);

    if (user.isAdmin) {
      if (unread.any((n) => n.isAdminType && !n.isProductSubmission)) {
        if (Get.isRegistered<AdminOrdersController>(tag: AdminOrdersScreen.embeddedTagForRefresh)) {
          Get.find<AdminOrdersController>(tag: AdminOrdersScreen.embeddedTagForRefresh).load(silent: true);
        } else if (Get.isRegistered<AdminOrdersController>()) {
          Get.find<AdminOrdersController>().load(silent: true);
        }
      }
      if (unread.any((n) => n.isProductSubmission)) {
        if (Get.isRegistered<AdminProductSubmissionsController>()) {
          Get.find<AdminProductSubmissionsController>().load();
        }
      }
    }

    if (user.isSeller && unread.any((n) => n.isSellerAccountType)) {
      if (Get.isRegistered<SellerSubscriptionsController>()) {
        Get.find<SellerSubscriptionsController>().load();
      }
    }

    if (user.isDriver && unread.any((n) => n.isDriverAccountType)) {
      if (Get.isRegistered<DriverSubscriptionsController>()) {
        Get.find<DriverSubscriptionsController>().load();
      }
    }
  }

  bool _isRecentNotification(AppNotificationItem notification) {
    if (notification.createdAt.isEmpty) return true;
    try {
      final created = DateTime.parse(notification.createdAt).toLocal();
      return DateTime.now().difference(created) <= const Duration(hours: 24);
    } catch (_) {
      return true;
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    stopPolling();
    super.onClose();
  }
}
