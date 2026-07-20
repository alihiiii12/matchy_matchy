import 'package:get/get.dart';
import 'package:matchy_matchy/core/models/home_slide.dart';
import 'package:matchy_matchy/core/network/api_client.dart';

class HomeSlideRepository {
  HomeSlideRepository._();

  static final instance = HomeSlideRepository._();

  final version = 0.obs;
  List<HomeSlide> _slides = const [];
  bool _loaded = false;

  List<HomeSlide> get slides => _slides;

  List<HomeSlide> slidesByType(String type) => _slides
      .where((slide) => slide.type == type && slide.isActive)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<HomeSlide> get categorySlides => slidesByType('category');
  List<HomeSlide> get brandSlides => slidesByType('brand');

  Future<void> load() async {
    if (_loaded) return;
    await reload();
  }

  Future<void> reload() async {
    try {
      final response = await ApiClient.instance.getJson('/home-slides');
      final list = response.data!['data'] as List<dynamic>;
      _slides = list
          .map((json) => HomeSlide.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Keep previous slides or empty list when API is unavailable.
    } finally {
      _loaded = true;
      version.value++;
    }
  }
}
