import 'package:matchy_matchy/core/l10n/app_strings.dart';

abstract final class AuthValidation {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? email(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return AppStrings.emailRequired;
    if (!_emailRegex.hasMatch(input)) return AppStrings.emailInvalid;
    return null;
  }

  static String? password(String? value, {int minLength = 6, String? emptyMessage}) {
    final input = value ?? '';
    if (input.isEmpty) return emptyMessage ?? AppStrings.passwordRequired;
    if (input.length < minLength) return AppStrings.passwordMinLength;
    return null;
  }

  static String? phone(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return AppStrings.phoneRequired;
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9 || digits.length > 15) return AppStrings.phoneInvalid;
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final input = value ?? '';
    if (input.isEmpty) return AppStrings.confirmPasswordRequired;
    if (input != password) return AppStrings.passwordMismatch;
    return null;
  }

  static String? name(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return AppStrings.nameRequired;
    if (input.length < 2) return AppStrings.nameTooShort;
    return null;
  }
}
