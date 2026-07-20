import 'dart:async';

import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/driver_jobs_controller.dart';
import 'package:matchy_matchy/core/controllers/my_orders_controller.dart';
import 'package:matchy_matchy/core/repositories/catalog_repository.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/core/services/location_access_service.dart';
import 'package:matchy_matchy/core/widgets/welcome_dialog.dart';
import 'package:matchy_matchy/routing/app_routes.dart';
import 'package:matchy_matchy/screens/driver/driver_jobs_screen.dart';

class MainShellController extends GetxController {
  static const adminOrdersTabIndex = 2;
  static const customerOrdersTabIndex = 2;

  final currentIndex = 0.obs;

  void setIndex(int index) {
    if (Get.isSnackbarOpen == true) {
      Get.closeAllSnackbars();
    }

    final user = AuthService.instance.user;
    final maxIndex = (user?.isDriver == true) ? 1 : 4;
    final next = index.clamp(0, maxIndex);
    currentIndex.value = next;

    if (next == 0 && user != null && (user.isCustomer || user.isAdmin)) {
      unawaited(CatalogRepository.instance.reload());
    }

    if (next == 0 && user != null && user.isDriver) {
      unawaited(_reloadDriverJobs());
    }

    if (next == customerOrdersTabIndex && user != null && user.isCustomer) {
      unawaited(_reloadMyOrders());
    }
  }

  Future<void> _reloadDriverJobs() async {
    if (Get.isRegistered<DriverJobsController>(tag: DriverJobsScreen.embeddedTag)) {
      await Get.find<DriverJobsController>(tag: DriverJobsScreen.embeddedTag).load();
      return;
    }
    if (Get.isRegistered<DriverJobsController>()) {
      await Get.find<DriverJobsController>().load();
    }
  }

  Future<void> _reloadMyOrders() async {
    for (final tag in const ['my_orders_true', 'my_orders_false']) {
      if (Get.isRegistered<MyOrdersController>(tag: tag)) {
        await Get.find<MyOrdersController>(tag: tag).load();
        return;
      }
    }
    if (Get.isRegistered<MyOrdersController>()) {
      await Get.find<MyOrdersController>().load();
    }
  }

  @override
  void onReady() {
    super.onReady();
    unawaited(_prepareLocationAccess());
    _maybeShowWelcome();
  }

  Future<void> _prepareLocationAccess() async {
    final user = AuthService.instance.user;
    if (user == null) return;
    if (!user.isCustomer && !user.isDriver) return;
    if (!Get.isRegistered<LocationAccessService>()) return;

    await Get.find<LocationAccessService>().prepareForUser(isDriver: user.isDriver);
  }

  Future<void> _maybeShowWelcome() async {
    final user = AuthService.instance.user;
    if (user != null && user.isCustomer && user.requiresPhone) {
      Get.offNamed(AppRoutes.googlePhone);
      return;
    }

    if (!AuthService.instance.pendingWelcome.value) return;
    if (user == null) return;

    AuthService.instance.clearPendingWelcome();
    await showWelcomeDialog(Get.context!, user);
  }
}

class MainShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(MainShellController());
  }
}
