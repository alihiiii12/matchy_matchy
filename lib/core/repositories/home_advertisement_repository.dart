import 'package:get/get.dart';
import 'package:matchy_matchy/core/models/home_advertisement.dart';
import 'package:matchy_matchy/core/network/api_client.dart';

class HomeAdvertisementRepository {
  HomeAdvertisementRepository._();

  static final instance = HomeAdvertisementRepository._();

  final version = 0.obs;
  List<HomeAdvertisement> _ads = const [];
  bool _loaded = false;

  List<HomeAdvertisement> get ads => _ads;

  List<HomeAdvertisement> get activeAds => _ads
      .where((ad) => ad.isActive)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  Future<void> load() async {
    if (_loaded) return;
    await reload();
  }

  Future<void> reload() async {
    try {
      final response = await ApiClient.instance.getJson('/home-advertisements');
      final list = response.data!['data'] as List<dynamic>;
      _ads = list
          .map((json) => HomeAdvertisement.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Keep previous ads or empty list when API is unavailable.
    } finally {
      _loaded = true;
      version.value++;
    }
  }
}
