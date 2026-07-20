import 'package:matchy_matchy/core/network/api_client.dart';

class ReviewsRepository {
  ReviewsRepository._();
  static final instance = ReviewsRepository._();

  Future<void> rateProduct({
    required int orderId,
    required String productId,
    required int rating,
    String? comment,
  }) async {
    await ApiClient.instance.postJson(
      '/reviews/product',
      data: {
        'order_id': orderId,
        'product_id': productId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
  }

  Future<void> rateDriver({
    required int orderId,
    required int rating,
    String? comment,
  }) async {
    await ApiClient.instance.postJson(
      '/reviews/driver',
      data: {
        'order_id': orderId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
  }
}
