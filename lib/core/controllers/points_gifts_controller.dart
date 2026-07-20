import 'package:dio/dio.dart';

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:matchy_matchy/core/l10n/app_strings.dart';

import 'package:matchy_matchy/core/network/api_client.dart';

import 'package:matchy_matchy/core/network/api_error.dart';

import 'package:matchy_matchy/core/services/points_balance_service.dart';

import 'package:matchy_matchy/core/widgets/app_snackbar.dart';



class PointsGiftsController extends GetxController {

  final loading = true.obs;

  final redeemingId = RxnInt();

  final gifts = <Map<String, dynamic>>[].obs;

  final error = RxnString();



  bool _loadInFlight = false;

  DateTime? _lastLoadedAt;



  RxInt get balance => PointsBalanceService.balance;



  @override

  void onInit() {

    super.onInit();

    load();

  }



  Future<void> load({bool force = false}) async {

    if (_loadInFlight) return;

    if (!force &&

        _lastLoadedAt != null &&

        DateTime.now().difference(_lastLoadedAt!) < const Duration(seconds: 3)) {

      return;

    }



    _loadInFlight = true;

    loading.value = true;

    error.value = null;

    try {

      final res = await ApiClient.instance.getJson('/gifts', force: force);

      gifts.value = (res.data!['data'] as List<dynamic>).cast<Map<String, dynamic>>();

      final fromGifts = (res.data!['points_balance'] as num?)?.toInt();

      if (fromGifts != null) {

        PointsBalanceService.apply(fromGifts);

      } else {

        await PointsBalanceService.resolve(force: force);

      }

      _lastLoadedAt = DateTime.now();

    } on DioException catch (e) {

      error.value = apiFriendlyError(e, fallback: AppStrings.giftsLoadFailed);

    } finally {

      loading.value = false;

      _loadInFlight = false;

    }

  }



  Future<void> redeem(Map<String, dynamic> gift) async {

    final id = gift['id'] as int;

    final cost = gift['points_cost'] as int? ?? 0;

    if (balance.value < cost) {

      _showMessage(AppStrings.notEnoughPoints, success: false);

      return;

    }



    final confirmed = await Get.dialog<bool>(

      AlertDialog(

        title: Text(AppStrings.redeemGift),

        content: Text('${AppStrings.redeemGiftConfirm}\n${gift['title']} ($cost ${AppStrings.pointsUnit})'),

        actions: [

          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),

          TextButton(onPressed: () => Get.back(result: true), child: Text(AppStrings.confirm)),

        ],

      ),

    );

    if (confirmed != true) return;



    redeemingId.value = id;

    try {

      final res = await ApiClient.instance.postJson('/gifts/$id/redeem');

      ApiClient.instance.invalidateGetCache('/gifts');

      ApiClient.instance.invalidateGetCache('/points/balance');

      final newBalance = (res.data!['points_balance'] as num?)?.toInt();

      if (newBalance != null) {

        PointsBalanceService.apply(newBalance);

      }

      final fulfillmentMessage = res.data!['message'] as String?;
      _showMessage(fulfillmentMessage ?? AppStrings.giftRedeemedSuccess, success: true);

      await load(force: true);

    } on DioException catch (e) {

      _showMessage(apiFriendlyError(e), success: false);

    } finally {

      redeemingId.value = null;

    }

  }



  void _showMessage(String message, {required bool success}) {

    showMatchySnackBar(

      message: message,

      type: success ? AppSnackBarType.success : AppSnackBarType.error,

    );

  }

}



class PointsGiftsBinding extends Bindings {

  @override

  void dependencies() {

    Get.put(PointsGiftsController());

  }

}


