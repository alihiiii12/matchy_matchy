import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/services/driver_jobs_pdf_exporter.dart';
import 'package:matchy_matchy/core/services/driver_location_tracker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class DriverJobsController extends GetxController with GetSingleTickerProviderStateMixin {
  final loading = true.obs;
  final archiving = false.obs;
  final actionLoadingId = RxnString();
  final activeJobs = <Map<String, dynamic>>[].obs;
  final rejectedJobs = <Map<String, dynamic>>[].obs;
  final completedJobs = <Map<String, dynamic>>[].obs;
  final error = RxnString();
  final selectedTab = 0.obs;
  late final TabController tabController;

  List<Map<String, dynamic>> get jobs => activeJobs;

  List<Map<String, dynamic>> get currentJobs {
    switch (selectedTab.value) {
      case 1:
        return rejectedJobs;
      case 2:
        return completedJobs;
      default:
        return activeJobs;
    }
  }

  String get emptyMessage {
    switch (selectedTab.value) {
      case 1:
        return AppStrings.noRejectedDriverJobs;
      case 2:
        return AppStrings.noCompletedDriverJobs;
      default:
        return AppStrings.noDriverJobsYet;
    }
  }

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        selectedTab.value = tabController.index;
      }
    });
    load();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final results = await Future.wait([
        _fetchScope('active'),
        _fetchScope('rejected'),
        _fetchScope('completed'),
      ]);
      activeJobs.value = results[0];
      rejectedJobs.value = results[1];
      completedJobs.value = results[2];
      if (Get.isRegistered<DriverLocationTracker>()) {
        await Get.find<DriverLocationTracker>().syncFromJobs(activeJobs);
      }
    } on DioException catch (e) {
      error.value = apiFriendlyError(e, fallback: AppStrings.loadDriverJobsFailed);
    } finally {
      loading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchScope(String scope) async {
    final res = await ApiClient.instance.getJson('/driver/delivery-jobs', query: {'scope': scope});
    final list = res.data!['data'] as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> archiveJobs() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.archiveDriverJobs),
        content: Text(AppStrings.archiveDriverJobsConfirm),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(AppStrings.archiveDriverJobs, style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    archiving.value = true;
    try {
      final history = await _fetchScope('history');
      if (history.isEmpty) {
        _showMessage(AppStrings.noDriverJobsToArchive, success: false);
        return;
      }
      final path = await DriverJobsPdfExporter.exportAndSave(history);
      await OpenFilex.open(path);
      _showMessage(AppStrings.archiveDriverJobsSaved, success: true);
    } catch (_) {
      _showMessage(AppStrings.archiveDriverJobsFailed, success: false);
    } finally {
      archiving.value = false;
    }
  }

  bool isActionLoading(String id) => actionLoadingId.value == id;

  Future<String?> _askRejectReason() async {
    final reasonController = TextEditingController();
    final result = await Get.dialog<String>(
      AlertDialog(
        title: Text(AppStrings.rejectDeliveryJob),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.rejectDeliveryJobConfirm),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: AppStrings.rejectDeliveryJobReason,
                hintText: AppStrings.rejectDeliveryJobReasonHint,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.length < 3) {
                _showMessage(AppStrings.rejectDeliveryJobReasonRequired, success: false);
                return;
              }
              Get.back(result: reason);
            },
            child: Text(AppStrings.rejectDeliveryJob, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    reasonController.dispose();
    return result;
  }

  Future<void> rejectJob(Map<String, dynamic> job) async {
    final reason = await _askRejectReason();
    if (reason == null || reason.trim().isEmpty) return;

    final id = _jobId(job);
    actionLoadingId.value = id;
    try {
      await ApiClient.instance.postJson(
        '/driver/delivery-jobs/$id/reject',
        data: {'reason': reason.trim()},
      );
      if (Get.isRegistered<DriverLocationTracker>()) {
        await Get.find<DriverLocationTracker>().stop();
      }
      _showMessage(AppStrings.deliveryJobRejected, success: true);
      await load();
      if (Get.currentRoute == AppRoutes.driverJobDetail) {
        Get.back();
      }
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    } finally {
      actionLoadingId.value = null;
    }
  }

  Future<void> acceptJob(Map<String, dynamic> job) async {
    final id = _jobId(job);
    actionLoadingId.value = id;
    try {
      await ApiClient.instance.postJson('/driver/delivery-jobs/$id/accept');
      _showMessage(AppStrings.deliveryJobAccepted, success: true);
      await load();
      Get.toNamed(AppRoutes.driverJobDetail, arguments: id);
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    } finally {
      actionLoadingId.value = null;
    }
  }

  Future<void> startTransit(Map<String, dynamic> job) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.startDeliveryTrip),
        content: Text(AppStrings.startDeliveryTripConfirm),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(AppStrings.startDeliveryTrip, style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final id = _jobId(job);
    actionLoadingId.value = id;
    try {
      await ApiClient.instance.postJson('/driver/delivery-jobs/$id/start-transit');
      if (Get.isRegistered<DriverLocationTracker>()) {
        await Get.find<DriverLocationTracker>().start(id);
      }
      _showMessage(AppStrings.deliveryTripStarted, success: true);
      await load();
      if (Get.isRegistered<DriverJobDetailController>()) {
        await Get.find<DriverJobDetailController>().load();
      }
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    } finally {
      actionLoadingId.value = null;
    }
  }

  Future<void> confirmPaymentCollected(Map<String, dynamic> job) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('تأكيد قبض المبلغ'),
        content: const Text('هل قبضت مبلغ الطلب من الزبون (كاش أو إلكتروني)؟'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('تم القبض', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final id = _jobId(job);
    actionLoadingId.value = id;
    try {
      await ApiClient.instance.postJson(
        '/driver/delivery-jobs/$id/confirm-payment',
        data: {'method': 'cash'},
      );
      _showMessage('تم تأكيد قبض المبلغ', success: true);
      await load();
      if (Get.isRegistered<DriverJobDetailController>()) {
        await Get.find<DriverJobDetailController>().load();
      }
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    } finally {
      actionLoadingId.value = null;
    }
  }

  Future<void> markDelivered(Map<String, dynamic> job) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.driverMarkDelivered),
        content: Text(AppStrings.driverMarkDeliveredConfirm),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(AppStrings.driverMarkDelivered, style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final id = _jobId(job);
    actionLoadingId.value = id;
    try {
      await ApiClient.instance.postJson('/driver/delivery-jobs/$id/mark-delivered');
      if (Get.isRegistered<DriverLocationTracker>()) {
        await Get.find<DriverLocationTracker>().stop();
      }
      _showMessage(AppStrings.driverDeliveryReported, success: true);
      await load();
      if (Get.currentRoute == AppRoutes.driverJobDetail) {
        Get.back();
      }
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    } finally {
      actionLoadingId.value = null;
    }
  }

  String _jobId(Map<String, dynamic> job) => job['id']?.toString() ?? '';

  void _showMessage(String message, {required bool success}) {
    showMatchySnackBar(
      message: message,
      type: success ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }
}

class DriverJobsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(DriverJobsController());
  }
}

class DriverJobDetailController extends GetxController {
  final loading = true.obs;
  final job = Rxn<Map<String, dynamic>>();
  final error = RxnString();
  late final String jobId;
  Timer? _pollTimer;

  @override
  void onInit() {
    super.onInit();
    jobId = Get.arguments?.toString() ?? '';
    load();
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      refreshQuietly();
    });
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final res = await ApiClient.instance.getJson('/driver/delivery-jobs/$jobId');
      job.value = res.data!['data'] as Map<String, dynamic>;
      final data = job.value;
      if (data != null && Get.isRegistered<DriverLocationTracker>()) {
        await Get.find<DriverLocationTracker>().syncFromJobs([data]);
      }
    } on DioException catch (e) {
      error.value = apiFriendlyError(e);
    } finally {
      loading.value = false;
    }
  }

  /// Refresh job (customer pin + details) without full-screen spinner.
  Future<void> refreshQuietly() async {
    if (jobId.isEmpty) return;
    try {
      final res = await ApiClient.instance.getJson('/driver/delivery-jobs/$jobId');
      job.value = res.data!['data'] as Map<String, dynamic>;
    } catch (_) {}
  }

  Future<void> accept() async {
    if (!Get.isRegistered<DriverJobsController>()) {
      Get.put(DriverJobsController());
    }
    final data = job.value;
    if (data == null) return;
    await Get.find<DriverJobsController>().acceptJob(data);
    await load();
  }

  Future<void> startTrip() async {
    final data = job.value;
    if (data == null) return;
    if (!Get.isRegistered<DriverJobsController>()) {
      Get.put(DriverJobsController());
    }
    await Get.find<DriverJobsController>().startTransit(data);
    await load();
  }

  Future<void> markDelivered() async {
    final data = job.value;
    if (data == null) return;
    if (!Get.isRegistered<DriverJobsController>()) {
      Get.put(DriverJobsController());
    }
    await Get.find<DriverJobsController>().markDelivered(data);
    await load();
  }

  Future<void> confirmPayment() async {
    final data = job.value;
    if (data == null) return;
    if (!Get.isRegistered<DriverJobsController>()) {
      Get.put(DriverJobsController());
    }
    await Get.find<DriverJobsController>().confirmPaymentCollected(data);
    await load();
  }

  Future<void> reject() async {
    final data = job.value;
    if (data == null) return;
    if (!Get.isRegistered<DriverJobsController>()) {
      Get.put(DriverJobsController());
    }
    await Get.find<DriverJobsController>().rejectJob(data);
    await load();
  }
}

class DriverJobDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(DriverJobDetailController());
  }
}
