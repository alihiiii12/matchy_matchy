import 'package:matchy_matchy/core/network/api_client.dart';

class SizeGuideRepository {
  SizeGuideRepository._();
  static final instance = SizeGuideRepository._();

  Future<List<Map<String, dynamic>>> fetchPublic({bool force = false}) async {
    final res = await ApiClient.instance.getJson('/size-guide', force: force);
    return (res.data!['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchAdmin({bool force = false}) async {
    final res = await ApiClient.instance.getJson('/admin/size-guide', force: force);
    return (res.data!['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> create({
    required String ageLabel,
    required String suggestedSize,
    int? heightCmMin,
    int? heightCmMax,
    int? sortOrder,
  }) async {
    final res = await ApiClient.instance.postJson(
      '/admin/size-guide',
      data: {
        'age_label': ageLabel,
        'suggested_size': suggestedSize,
        if (heightCmMin != null) 'height_cm_min': heightCmMin,
        if (heightCmMax != null) 'height_cm_max': heightCmMax,
        if (sortOrder != null) 'sort_order': sortOrder,
      },
    );
    ApiClient.instance.invalidateGetCache('/size-guide');
    return res.data!['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update({
    required int id,
    required String ageLabel,
    required String suggestedSize,
    int? heightCmMin,
    int? heightCmMax,
    int? sortOrder,
  }) async {
    final res = await ApiClient.instance.patchJson(
      '/admin/size-guide/$id',
      data: {
        'age_label': ageLabel,
        'suggested_size': suggestedSize,
        if (heightCmMin != null) 'height_cm_min': heightCmMin,
        if (heightCmMax != null) 'height_cm_max': heightCmMax,
        if (sortOrder != null) 'sort_order': sortOrder,
      },
    );
    ApiClient.instance.invalidateGetCache('/size-guide');
    return res.data!['data'] as Map<String, dynamic>;
  }

  Future<void> delete(int id) async {
    await ApiClient.instance.deleteJson('/admin/size-guide/$id');
    ApiClient.instance.invalidateGetCache('/size-guide');
  }
}
