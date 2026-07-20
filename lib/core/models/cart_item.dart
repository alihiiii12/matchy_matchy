import 'package:matchy_matchy/core/data/body_measurements.dart';
import 'package:matchy_matchy/core/models/product.dart';

class CartItem {
  CartItem({
    required this.product,
    this.quantity = 1,
    this.options,
  });

  final Product product;
  int quantity;

  /// Family set selection: piece_role, gender, age, color, size, unit_price, measurements.
  final Map<String, dynamic>? options;

  double get unitPrice {
    final raw = options?['unit_price'];
    if (raw is num) return raw.toDouble();
    if (raw is String) {
      final parsed = double.tryParse(raw);
      if (parsed != null) return parsed;
    }
    return product.price;
  }

  double get lineTotal => unitPrice * quantity;

  String get cartKey {
    final opts = options;
    if (opts == null || opts.isEmpty) return product.id;
    final role = opts['piece_role']?.toString() ?? '';
    final age = opts['age']?.toString() ?? '';
    final color = opts['color']?.toString() ?? '';
    final size = opts['size']?.toString() ?? '';
    final measures = BodyMeasurements.keys.map((k) => '${opts[k] ?? ''}').join('|');
    return '${product.id}|$role|$age|$color|$size|$measures';
  }

  String? get optionsLabel {
    final opts = options;
    if (opts == null || opts.isEmpty) return null;
    final label = BodyMeasurements.formatMemberOptions(opts);
    return label.isEmpty ? null : label;
  }

  Map<String, dynamic> toOrderItemJson() {
    final map = <String, dynamic>{
      'product_id': product.id,
      'quantity': quantity,
    };
    if (options != null && options!.isNotEmpty) {
      map['options'] = options;
    }
    return map;
  }
}
