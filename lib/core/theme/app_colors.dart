import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/theme_controller.dart';

/// ماتشي ماتشي — هوية بوتيك عائلية (وردي ترابي + نعناع + أزرق فاتح + أصفر خفيف).
/// متعمّد الابتعاد عن بنفسج/كحلي زادك.
abstract final class AppColors {
  // —— ألوان الهوية ——
  static const blush = Color(0xFFE8C4C8);
  static const softBlush = Color(0xFFF3DDDF);
  static const rose = Color(0xFFC4878F);
  static const dustyRose = Color(0xFFA66B74);
  static const mint = Color(0xFF9DCEC0);
  static const softMint = Color(0xFFD0EBE3);
  static const softBlue = Color(0xFFB9D6E8);
  static const skyMist = Color(0xFFD7E8F2);
  static const softYellow = Color(0xFFF3E4B0);
  static const paleYellow = Color(0xFFFBF6DF);
  static const champagne = Color(0xFFE8D9C8);

  /// توافق خلفي مع الأسماء القديمة في الشاشات
  static const lavender = blush;
  static const softLavender = softBlush;
  static const roseMist = softBlush;
  static const deepBrand = dustyRose;
  static const primary = dustyRose;
  static const secondary = softBlue;
  static const accent = Color(0xFF6FAE9E);

  // —— فاتح ——
  static const backgroundLight = Color(0xFFF7F5F2);
  static const surfaceLight = Color(0xFFFFFCFB);
  static const inputFillLight = Color(0xFFF1ECE8);
  static const textPrimaryLight = Color(0xFF3A3032);
  static const textSecondaryLight = Color(0xFF8A7E80);
  static const textHintLight = Color(0xFFB5AAA8);
  static const borderLight = Color(0xFFE6DEDA);
  static const dividerLight = Color(0xFFF0EAE6);

  // —— داكن (دافئ رمادي-وردي، بدون بنفسج زادك) ——
  static const darkBackground = Color(0xFF1C1918);
  static const darkSurface = Color(0xFF2A2524);
  static const darkInputFill = Color(0xFF352F2E);
  static const darkTextPrimary = Color(0xFFF7F2F0);
  static const darkTextSecondary = Color(0xFFB8ADA9);
  static const darkTextHint = Color(0xFF857A76);
  static const darkBorder = Color(0xFF433C3A);
  static const darkDivider = Color(0xFF352F2E);

  static bool get _isDark =>
      Get.isRegistered<ThemeController>() && Get.find<ThemeController>().isDarkMode;

  static Color get background => _isDark ? darkBackground : backgroundLight;
  static Color get surface => _isDark ? darkSurface : surfaceLight;
  static Color get inputFill => _isDark ? darkInputFill : inputFillLight;
  static Color get textPrimary => _isDark ? darkTextPrimary : textPrimaryLight;
  static Color get textSecondary => _isDark ? darkTextSecondary : textSecondaryLight;
  static Color get textHint => _isDark ? darkTextHint : textHintLight;
  static Color get border => _isDark ? darkBorder : borderLight;
  static Color get divider => _isDark ? darkDivider : dividerLight;

  static const error = Color(0xFFD64545);
  static const success = Color(0xFF4C9A7A);
  static const warning = Color(0xFFE0A84A);

  /// تدرج هوية اللوغو: أزرق فاتح → نعناع → وردي خفيف
  static const brandGradient = LinearGradient(
    colors: [skyMist, softMint, softBlush],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const brandGradientVertical = LinearGradient(
    colors: [softBlue, softMint, paleYellow],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// أزرار: وردي ترابي → نعناع (بدون بنفسج)
  static const buttonGradient = LinearGradient(
    colors: [dustyRose, accent],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
