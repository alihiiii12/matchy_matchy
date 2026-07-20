import 'package:matchy_matchy/core/services/points_balance_service.dart';

class ConfirmReceiptPoints {
  ConfirmReceiptPoints._();

  static void applyFromResult({required int pointsEarned, required int pointsBalance}) {
    if (pointsBalance > 0) {
      PointsBalanceService.apply(pointsBalance);
      return;
    }
    if (pointsEarned > 0) {
      PointsBalanceService.apply(PointsBalanceService.balance.value + pointsEarned);
    }
  }
}
