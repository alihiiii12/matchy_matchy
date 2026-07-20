import 'package:intl/intl.dart';

abstract final class CurrencyFormatter {
  static const symbol = 'ل.س';

  static final NumberFormat _formatter = NumberFormat('#,##0', 'en_US');

  static String format(num amount) {
    return '${_formatter.format(amount.round())} $symbol';
  }

  static String formatWithUnit(num amount, String? unit) {
    final price = format(amount);
    if (unit == null || unit.isEmpty) return price;
    return '$price / $unit';
  }
}
