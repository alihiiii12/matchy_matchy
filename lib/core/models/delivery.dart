/// نوع التوصيل حسب المنتج والموقع
enum DeliveryMode {
  /// بقالة/خضار/مونة — أقرب مندوب، أقل من ساعة
  localExpress,

  /// نفس المحافظة — أقصى 24 ساعة
  sameGovernorate,

  /// بين محافظتين — تنسيق مع فريق زادك
  crossGovernorate,
}

enum DeliveryStatus {
  preparing,
  pickedUp,
  onTheWay,
  arrived,
  delivered,
  awaitingCoordination,
}

class Governorate {
  const Governorate({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String name;
  final double lat;
  final double lng;
}

class DeliveryDriver {
  const DeliveryDriver({
    required this.name,
    required this.phone,
    required this.vehicle,
    required this.plateNumber,
    required this.rating,
    required this.governorateId,
  });

  final String name;
  final String phone;
  final String vehicle;
  final String plateNumber;
  final double rating;
  final String governorateId;
}

class ProductDeliveryInfo {
  const ProductDeliveryInfo({
    required this.productId,
    required this.productName,
    required this.mode,
    required this.sellerGovernorate,
    required this.buyerGovernorate,
    required this.distanceKm,
    required this.etaLabel,
    required this.fee,
    required this.needsCoordination,
  });

  final String productId;
  final String productName;
  final DeliveryMode mode;
  final Governorate sellerGovernorate;
  final Governorate buyerGovernorate;
  final double distanceKm;
  final String etaLabel;
  final double fee;
  final bool needsCoordination;
}

class CartDeliveryAnalysis {
  const CartDeliveryAnalysis({
    required this.items,
    required this.localDriver,
    required this.totalFee,
  });

  final List<ProductDeliveryInfo> items;
  final DeliveryDriver? localDriver;
  final double totalFee;

  bool get hasLocal => items.any((i) => i.mode == DeliveryMode.localExpress);
  bool get hasCrossGovernorate => items.any((i) => i.mode == DeliveryMode.crossGovernorate);
  bool get needsCoordination => items.any((i) => i.needsCoordination);
  List<ProductDeliveryInfo> get localItems =>
      items.where((i) => i.mode == DeliveryMode.localExpress).toList();
  List<ProductDeliveryInfo> get marketplaceItems =>
      items.where((i) => i.mode != DeliveryMode.localExpress).toList();
}

class DeliveryOrder {
  const DeliveryOrder({
    required this.id,
    required this.orderId,
    required this.status,
    required this.mode,
    required this.address,
    required this.itemsSummary,
    required this.total,
    required this.deliveryFee,
    required this.estimatedTime,
    required this.date,
    this.sellerGovernorate,
    this.buyerGovernorate,
    this.distanceKm,
    this.driver,
    this.progress = 0,
    this.needsCoordination = false,
    this.canConfirmReceipt = false,
  });

  final String id;
  final String orderId;
  final DeliveryStatus status;
  final DeliveryMode mode;
  final String address;
  final String itemsSummary;
  final double total;
  final double deliveryFee;
  final String estimatedTime;
  final String date;
  final Governorate? sellerGovernorate;
  final Governorate? buyerGovernorate;
  final double? distanceKm;
  final DeliveryDriver? driver;
  final double progress;
  final bool needsCoordination;
  final bool canConfirmReceipt;

  bool get awaitingCustomerConfirmation =>
      status == DeliveryStatus.arrived || canConfirmReceipt;

  String get statusLabel {
    switch (status) {
      case DeliveryStatus.awaitingCoordination:
        return 'بانتظار تنسيق التوصيل';
      case DeliveryStatus.preparing:
        return 'قيد التجهيز';
      case DeliveryStatus.pickedUp:
        return 'تم الاستلام من البائع';
      case DeliveryStatus.onTheWay:
        return 'في الطريق إليك';
      case DeliveryStatus.arrived:
        return 'وصل الطلب — أكّد الاستلام';
      case DeliveryStatus.delivered:
        return 'تم التسليم';
    }
  }

  String get modeLabel {
    switch (mode) {
      case DeliveryMode.localExpress:
        return 'توصيل محلي سريع';
      case DeliveryMode.sameGovernorate:
        return 'توصيل داخل المحافظة';
      case DeliveryMode.crossGovernorate:
        return 'توصيل بين المحافظات';
    }
  }
}
