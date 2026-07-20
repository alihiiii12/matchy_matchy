import 'package:intl/intl.dart';

abstract final class PointsFormat {
  static final _formatter = NumberFormat.decimalPattern('ar');

  static String display(int value) => _formatter.format(value);
}
