import 'package:matchy_matchy/core/services/points_balance_service.dart';

class PointsRepository {
  PointsRepository._();
  static final instance = PointsRepository._();

  Future<int> fetchBalance({bool force = false}) => PointsBalanceService.resolve(force: force);
}
