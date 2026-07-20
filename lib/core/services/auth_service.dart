import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart' show DioException, MultipartFile, Response;
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide MultipartFile, Response;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:matchy_matchy/core/data/catalog_meta.dart';
import 'package:matchy_matchy/core/controllers/cart_controller.dart';
import 'package:matchy_matchy/core/controllers/favorites_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/services/points_balance_service.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/network/multipart_image.dart';
import 'package:matchy_matchy/core/services/driver_location_tracker.dart';
import 'package:matchy_matchy/core/services/notification_service.dart';

class ChangePasswordResult {
  const ChangePasswordResult({
    this.changed = false,
    this.requiresOtp = false,
    this.currentPasswordIncorrect = false,
    this.email,
    this.message,
  });

  final bool changed;
  final bool requiresOtp;
  final bool currentPasswordIncorrect;
  final String? email;
  final String? message;
}

class ForgotPasswordResult {
  const ForgotPasswordResult({
    required this.email,
    this.directReset = false,
    this.resetToken,
  });

  final String email;
  final bool directReset;
  final String? resetToken;
}

class UpdateProfileResult {
  const UpdateProfileResult({
    this.updated = false,
    this.requiresOtp = false,
    this.email,
    this.message,
    this.user,
    this.changesEmail = false,
    this.changesPhone = false,
    this.avatarUploadFailed = false,
  });

  final bool updated;
  final bool requiresOtp;
  final String? email;
  final String? message;
  final AuthUser? user;
  final bool changesEmail;
  final bool changesPhone;
  final bool avatarUploadFailed;
}

class SellerPasswordResetDenied implements Exception {
  SellerPasswordResetDenied([String? message]) : message = message ?? AppStrings.sellerPasswordResetDenied;

  final String message;
}

class AuthPendingVerification implements Exception {
  AuthPendingVerification(this.email);
  final String email;
}

/// الأدمن يدخل من الموقع فقط، وليس من تطبيق الجوال.
class AdminMobileBlockedException implements Exception {
  AdminMobileBlockedException([String? message]) : message = message ?? AppStrings.adminMobileBlocked;

  final String message;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.role = 'customer',
    this.emailVerified = false,
    this.requiresPhone = false,
    this.pointsBalance = 0,
    this.walletBalance = 0,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final bool emailVerified;
  final bool requiresPhone;
  final int pointsBalance;
  final double walletBalance;

  bool get isAdmin => role == 'admin';
  bool get isSeller => role == 'seller';
  bool get isDriver => role == 'driver';
  bool get isCustomer => role == 'customer';
  bool get isStaff => isDriver || isAdmin;

  String get roleLabel {
    switch (role) {
      case 'admin':
        return 'مدير';
      case 'seller':
        return 'بائع';
      case 'driver':
        return 'كابتن';
      default:
        return 'زبون';
    }
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      avatarUrl: CatalogMeta.resolveImageUrl(json['avatar_url'] as String?),
      role: json['role'] as String? ?? 'customer',
      emailVerified: json['email_verified'] as bool? ?? false,
      requiresPhone: json['requires_phone'] as bool? ??
          ((json['role'] as String? ?? 'customer') == 'customer' &&
              ((json['phone'] as String?)?.isEmpty ?? true)),
      pointsBalance: json['points_balance'] as int? ?? 0,
      walletBalance: (json['wallet_balance'] as num?)?.toDouble() ?? 0,
    );
  }

  AuthUser copyWith({int? pointsBalance, double? walletBalance}) {
    return AuthUser(
      id: id,
      name: name,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
      role: role,
      emailVerified: emailVerified,
      requiresPhone: requiresPhone,
      pointsBalance: pointsBalance ?? this.pointsBalance,
      walletBalance: walletBalance ?? this.walletBalance,
    );
  }
}

class GoogleSignInCanceled implements Exception {}

class GoogleSignInResult {
  const GoogleSignInResult({required this.user, required this.requiresPhone});

  final AuthUser user;
  final bool requiresPhone;
}

class AuthService extends GetxService {
  static AuthService get instance => Get.find<AuthService>();

  final _user = Rxn<AuthUser>();
  final pendingWelcome = false.obs;

  AuthUser? get user => _user.value;
  Rxn<AuthUser> get userRx => _user;
  bool get isLoggedIn => _user.value != null;

  void clearPendingWelcome() => pendingWelcome.value = false;

  static String welcomeMessage(AuthUser user) {
    if (user.isAdmin) return AppStrings.welcomeAdmin;
    if (user.isSeller) return AppStrings.welcomeSeller(user.name);
    if (user.isDriver) return AppStrings.welcomeDriver(user.name);
    return AppStrings.welcomeCustomer(user.name);
  }

  Future<void> restoreSession() async {
    final token = await ApiClient.instance.getToken();
    if (token == null || token.isEmpty) {
      await Future.wait([_syncCart(), _syncFavorites()]);
      unawaited(_syncNotifications());
      return;
    }
    try {
      final res = await ApiClient.instance.getJson('/auth/me');
      _user.value = AuthUser.fromJson(res.data!);
    } catch (_) {
      await ApiClient.instance.clearToken();
      _user.value = null;
    }
    await Future.wait([_syncCart(), _syncFavorites()]);
    unawaited(_syncNotifications());
  }

  Future<void> _schedulePostAuthSync() async {
    await Future.wait([_syncCart(), _syncFavorites()]);
    unawaited(_syncNotifications());
  }

  Future<void> _syncCart() async {
    if (Get.isRegistered<CartController>()) {
      await CartController.instance.switchUser(_user.value);
    }
  }

  Future<void> _syncFavorites() async {
    if (Get.isRegistered<FavoritesController>()) {
      await FavoritesController.instance.switchUser(_user.value);
    }
  }

  Future<void> _syncNotifications() async {
    for (var attempt = 0; attempt < 15; attempt++) {
      if (Get.isRegistered<NotificationService>()) break;
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (!Get.isRegistered<NotificationService>()) return;
    final notifications = NotificationService.instance;
    if (_user.value == null) {
      if (Get.isRegistered<DriverLocationTracker>()) {
        await Get.find<DriverLocationTracker>().stop();
      }
      await notifications.unregisterDevice();
      notifications.stopPolling();
      await notifications.refresh(pushNew: false);
      return;
    }
    await notifications.syncDeviceToken();
    await notifications.refresh(pushNew: false);
    notifications.startPolling();
  }

  Future<AuthUser> login({required String email, required String password}) async {
    try {
      final res = await ApiClient.instance.postJson('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = res.data!;
      final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
      if (user.isAdmin) {
        await ApiClient.instance.clearToken();
        throw AdminMobileBlockedException();
      }
      await ApiClient.instance.saveToken(data['token'] as String);
      _user.value = user;
      pendingWelcome.value = true;
      unawaited(_schedulePostAuthSync());
      return _user.value!;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (e.response?.statusCode == 403 && data is Map<String, dynamic> && data['requires_verification'] == true) {
        throw AuthPendingVerification(data['email'] as String? ?? email);
      }
      rethrow;
    }
  }

  /// يخرج حساب الأدمن من التطبيق ويُفرّغ الجلسة (الإدارة من الويب فقط).
  Future<void> rejectAdminMobileAccess() async {
    await logout();
  }

  Future<({String email, String? debugOtp})> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final res = await ApiClient.instance.postJson('/auth/register', data: {
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    final data = res.data!;
    return (
      email: data['email'] as String,
      debugOtp: data['debug_otp']?.toString(),
    );
  }

  Future<AuthUser> verifyOtp({required String email, required String code}) async {
    final res = await ApiClient.instance.postJson('/auth/verify-otp', data: {
      'email': email,
      'code': code,
    });
    final data = res.data!;
    await ApiClient.instance.saveToken(data['token'] as String);
    _user.value = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    pendingWelcome.value = true;
    unawaited(_schedulePostAuthSync());
    return _user.value!;
  }

  Future<String?> resendOtp({required String email}) async {
    final res = await ApiClient.instance.postJson('/auth/resend-otp', data: {'email': email});
    return res.data?['debug_otp']?.toString();
  }

  Future<ForgotPasswordResult> requestForgotPassword({required String email}) async {
    try {
      final res = await ApiClient.instance.postJson('/auth/forgot-password/request', data: {
        'email': email,
      });
      final data = res.data!;
      return ForgotPasswordResult(
        email: data['email'] as String,
        directReset: data['direct_reset'] == true,
        resetToken: data['reset_token'] as String?,
      );
    } on DioException catch (e) {
      _throwIfSellerPasswordResetDenied(e);
      rethrow;
    }
  }

  Future<String> verifyForgotPasswordOtp({
    required String email,
    required String code,
  }) async {
    try {
      final res = await ApiClient.instance.postJson('/auth/forgot-password/verify-otp', data: {
        'email': email,
        'code': code,
      });
      return res.data!['reset_token'] as String;
    } on DioException catch (e) {
      _throwIfSellerPasswordResetDenied(e);
      rethrow;
    }
  }

  Future<void> resetForgotPassword({
    required String email,
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await ApiClient.instance.postJson('/auth/forgot-password/reset', data: {
        'email': email,
        'reset_token': resetToken,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
    } on DioException catch (e) {
      _throwIfSellerPasswordResetDenied(e);
      rethrow;
    }
  }

  Future<void> resendForgotPasswordOtp({required String email}) async {
    try {
      await ApiClient.instance.postJson('/auth/forgot-password/resend-otp', data: {
        'email': email,
      });
    } on DioException catch (e) {
      _throwIfSellerPasswordResetDenied(e);
      rethrow;
    }
  }

  Future<ChangePasswordResult> changePassword({
    String? currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    final payload = <String, dynamic>{
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
    if (currentPassword != null) {
      payload['current_password'] = currentPassword;
    }

    final res = await ApiClient.instance.postJson('/auth/change-password', data: payload);
    final data = res.data!;
    if (data['requires_otp'] == true) {
      return ChangePasswordResult(
        requiresOtp: true,
        currentPasswordIncorrect: data['current_password_incorrect'] == true,
        email: data['email'] as String?,
        message: data['message'] as String?,
      );
    }
    return const ChangePasswordResult(changed: true);
  }

  Future<String> verifyProfileChangeOtp({required String code}) async {
    final res = await ApiClient.instance.postJson('/auth/change-password/verify-otp', data: {
      'code': code,
    });
    return res.data!['reset_token'] as String;
  }

  Future<void> resetProfilePassword({
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    await ApiClient.instance.postJson('/auth/change-password/reset', data: {
      'reset_token': resetToken,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  Future<void> resendProfileChangeOtp() async {
    await ApiClient.instance.postJson('/auth/change-password/resend-otp');
  }

  Future<GoogleSignInResult> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(scopes: const ['email', 'profile']);

    await googleSignIn.signOut();
    GoogleSignInAccount? account;
    try {
      account = await googleSignIn.signIn();
    } on PlatformException catch (e) {
      throw StateError(googlePlatformError(e));
    }
    if (account == null) throw GoogleSignInCanceled();

    final auth = await account.authentication;
    final Map<String, String> body;
    if (auth.idToken != null && auth.idToken!.isNotEmpty) {
      body = {'id_token': auth.idToken!};
    } else if (auth.accessToken != null && auth.accessToken!.isNotEmpty) {
      body = {'access_token': auth.accessToken!};
    } else {
      throw StateError(AppStrings.googleSignInFailed);
    }

    final res = await ApiClient.instance.postJson('/auth/google', data: body);
    final data = res.data!;
    final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    if (user.isAdmin) {
      await ApiClient.instance.clearToken();
      throw AdminMobileBlockedException();
    }
    await ApiClient.instance.saveToken(data['token'] as String);
    _user.value = user;
    final requiresPhone = data['requires_phone'] as bool? ?? _user.value!.requiresPhone;
    if (!requiresPhone) pendingWelcome.value = true;
    unawaited(_schedulePostAuthSync());

    return GoogleSignInResult(user: _user.value!, requiresPhone: requiresPhone);
  }

  Future<AuthUser> completePhone(String phone) async {
    final res = await ApiClient.instance.postJson('/auth/phone', data: {'phone': phone});
    final user = AuthUser.fromJson(res.data!['user'] as Map<String, dynamic>);
    if (user.isAdmin) {
      await rejectAdminMobileAccess();
    }
    _user.value = user;
    pendingWelcome.value = true;
    unawaited(_schedulePostAuthSync());
    return _user.value!;
  }

  Future<UpdateProfileResult> updateProfile({
    required String name,
    required String phone,
    required String email,
    File? avatar,
    String? avatarFileName,
    Uint8List? avatarBytes,
  }) async {
    final role = _user.value?.role;
    final contactLocked = role == 'seller' || role == 'driver';
    final fields = <String, dynamic>{
      'name': name,
    };
    if (!contactLocked) {
      fields['phone'] = phone;
      fields['email'] = email.trim();
    }

    Map<String, MultipartFile>? files;
    if (avatar != null) {
      fields['has_avatar_upload'] = '1';
      files = {
        'avatar': await MultipartImage.fromPickedFile(
          file: avatar,
          filename: avatarFileName,
          bytes: avatarBytes,
        ),
      };
    }

    final Response<Map<String, dynamic>> res;
    if (files != null) {
      res = await ApiClient.instance.postMultipart('/auth/profile', fields: fields, files: files);
    } else {
      res = await ApiClient.instance.patchJson('/auth/profile', data: fields);
    }

    final data = res.data!;
    if (data['requires_otp'] == true) {
      return UpdateProfileResult(
        requiresOtp: true,
        email: data['email'] as String?,
        message: data['message'] as String?,
        changesEmail: data['changes_email'] as bool? ?? false,
        changesPhone: data['changes_phone'] as bool? ?? false,
      );
    }

    if (data['user'] is Map<String, dynamic>) {
      _user.value = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    }
    await _refreshUserFromServer();
    return UpdateProfileResult(
      updated: true,
      user: _user.value,
      message: data['message'] as String?,
      avatarUploadFailed: data['avatar_upload_failed'] == true,
    );
  }

  Future<void> refreshProfile() => _refreshUserFromServer();

  void updatePointsBalance(int balance) {
    final current = _user.value;
    if (current == null) return;
    _user.value = current.copyWith(pointsBalance: balance);
    _user.refresh();
  }

  Future<void> _refreshUserFromServer() async {
    try {
      final res = await ApiClient.instance.getJson('/auth/me');
      _user.value = AuthUser.fromJson(res.data!);
      _user.refresh();
    } catch (_) {}
  }

  Future<AuthUser> verifyProfileUpdateOtp({required String code}) async {
    final res = await ApiClient.instance.postJson('/auth/profile/verify-otp', data: {'code': code});
    _user.value = AuthUser.fromJson(res.data!['user'] as Map<String, dynamic>);
    return _user.value!;
  }

  Future<void> resendProfileUpdateOtp() async {
    await ApiClient.instance.postJson('/auth/profile/resend-otp');
  }

  Future<void> logout() async {
    try {
      await ApiClient.instance.postJson('/auth/logout');
    } catch (_) {}
    await ApiClient.instance.clearToken();
    ApiClient.instance.clearGetCache();
    PointsBalanceService.reset();
    _user.value = null;
    pendingWelcome.value = false;
    await _syncCart();
    await _syncFavorites();
    await _syncNotifications();
  }

  String friendlyError(DioException error) => apiFriendlyError(error);

  void _throwIfSellerPasswordResetDenied(DioException error) {
    if (isSellerPasswordResetDenied(error)) {
      throw SellerPasswordResetDenied(sellerPasswordResetDeniedMessage(error));
    }
  }
}

String googlePlatformError(PlatformException error) {
  final details = '${error.message ?? ''} ${error.details ?? ''}';
  if (details.contains('10')) {
    return 'خطأ إعداد Google: أنشئ Android OAuth client مع Package و SHA-1 الصحيحين';
  }
  if (details.contains('12500') || details.contains('12501')) {
    return 'تعذر Google Sign-In: أضف إيميلك في Test users داخل Google Console';
  }
  return AppStrings.googleSignInFailed;
}
