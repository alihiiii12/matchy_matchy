import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/services/admin_credit_points_service.dart';

class AdminCreditPointsController extends GetxController {
  final loading = true.obs;
  final creditingUserId = RxnInt();
  final users = <Map<String, dynamic>>[].obs;
  final filteredUsers = <Map<String, dynamic>>[].obs;
  final error = RxnString();
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
    ever(searchQuery, (_) => _applyFilter());
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final res = await ApiClient.instance.getJson('/admin/users');
      final list = res.data!['data'] as List<dynamic>;
      users.value = list.cast<Map<String, dynamic>>();
      _applyFilter();
    } on DioException catch (e) {
      error.value = apiFriendlyError(e, fallback: AppStrings.creditPointsLoadFailed);
    } finally {
      loading.value = false;
    }
  }

  void setSearch(String value) {
    searchQuery.value = value.trim();
  }

  void _applyFilter() {
    final q = searchQuery.value.toLowerCase();
    if (q.isEmpty) {
      filteredUsers.value = users.toList();
      return;
    }

    filteredUsers.value = users.where((user) {
      final name = (user['name'] as String? ?? '').toLowerCase();
      final phone = (user['phone'] as String? ?? '').toLowerCase();
      final email = (user['email'] as String? ?? '').toLowerCase();
      return name.contains(q) || phone.contains(q) || email.contains(q);
    }).toList();
  }

  Future<void> creditUser(Map<String, dynamic> user) async {
    final id = user['id'] as int?;
    if (id == null) return;

    creditingUserId.value = id;
    try {
      final ok = await AdminCreditPointsService.creditUser(user);
      if (ok) await load();
    } finally {
      creditingUserId.value = null;
    }
  }
}

class AdminCreditPointsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AdminCreditPointsController());
  }
}
