import 'package:get/get.dart';

import 'package:matchy_matchy/core/services/auth_service.dart';

import 'package:matchy_matchy/core/services/points_balance_service.dart';



class HomePointsController extends GetxController {

  int get pointsBalance => PointsBalanceService.balance.value;



  RxInt get pointsBalanceRx => PointsBalanceService.balance;



  final loading = false.obs;



  int? _watchedUserId;



  @override

  void onInit() {

    super.onInit();

    _watchedUserId = AuthService.instance.user?.id;

    refreshBalance();

    ever(AuthService.instance.userRx, (user) {

      final id = user?.id;

      if (id == _watchedUserId) return;

      _watchedUserId = id;

      if (id == null) {

        PointsBalanceService.reset();

      } else {

        refreshBalance(force: true);

      }

    });

  }



  Future<void> refreshBalance({bool force = false}) async {

    if (!AuthService.instance.isLoggedIn) {

      PointsBalanceService.reset();

      return;

    }



    if (AuthService.instance.user?.isDriver == true) {

      loading.value = false;

      return;

    }



    loading.value = true;

    try {

      await PointsBalanceService.resolve(force: force);

    } finally {

      loading.value = false;

    }

  }

}


