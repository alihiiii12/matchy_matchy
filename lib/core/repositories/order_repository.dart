import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:matchy_matchy/core/data/body_measurements.dart';
import 'package:matchy_matchy/core/models/delivery.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/services/delivery_service.dart';
import 'package:matchy_matchy/core/utils/order_sort.dart';

class OrderLineItem {
  const OrderLineItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.imageUrl,
    this.options,
  });

  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String? imageUrl;
  final Map<String, dynamic>? options;

  String? get optionsLabel {
    final label = BodyMeasurements.formatMemberOptions(options);
    return label.isEmpty ? null : label;
  }
}

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.orderCode,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.discountAmount,
    required this.total,
    required this.date,
    this.estimatedTime,
    this.delivery,
    this.items = const [],
  });

  final int id;
  final String orderCode;
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double discountAmount;
  final double total;
  final String date;
  final String? estimatedTime;
  final DeliveryOrder? delivery;
  final List<OrderLineItem> items;

  String get itemsLabel {
    if (items.isEmpty) {
      final summary = delivery?.itemsSummary.trim() ?? '';
      return summary;
    }
    return items.map((i) {
      final name = i.quantity > 1 ? '${i.productName} ×${i.quantity}' : i.productName;
      final opts = i.optionsLabel;
      return opts == null ? name : '$name ($opts)';
    }).join(' · ');
  }

  String get statusLabel {
    switch (status) {
      case 'delivered':
        return 'مكتمل';
      case 'shipped':
        return 'قيد الشحن';
      case 'cancelled':
        return 'مرفوض / ملغي';
      case 'pending_review':
        return 'بانتظار موافقة الإدارة';
      case 'approved':
        return 'تمت الموافقة';
      case 'payment_confirmed':
        return 'تم تأكيد الدفع';
      case 'out_for_delivery':
        return 'الكابتن في الطريق إليك';
      case 'awaiting_payment':
        return 'بانتظار تأكيد الدفع';
      case 'awaiting_receipt':
        return 'بانتظار تأكيد الاستلام';
      default:
        return 'قيد المعالجة';
    }
  }
}

class OrderRepository {
  OrderRepository._();
  static final instance = OrderRepository._();

  Future<List<OrderSummary>> fetchOrders() async {
    final res = await ApiClient.instance.getJson('/orders');
    final list = res.data!['data'] as List<dynamic>? ?? const [];
    final orders = <OrderSummary>[];
    for (final json in list) {
      if (json is! Map<String, dynamic>) continue;
      try {
        orders.add(_orderFromJson(json));
      } catch (_) {
        // تجاهل عنصر تالف حتى لا تختفي بقية الطلبات
      }
    }
    return OrderSort.sortOrders(orders);
  }

  Future<OrderSummary> fetchOrderById(int id) async {
    final res = await ApiClient.instance.getJson('/orders/$id');
    return _orderFromJson(res.data!['data'] as Map<String, dynamic>);
  }

  OrderSummary _orderFromJson(Map<String, dynamic> json) {
    final deliveryJson = json['delivery'] as Map<String, dynamic>?;
    DeliveryOrder? delivery;
    if (deliveryJson != null) {
      try {
        delivery = DeliveryRepository.instance.parseDelivery(deliveryJson);
      } catch (_) {
        delivery = null;
      }
    }
    final deliveryFee = (json['delivery_fee'] as num?)?.toDouble() ?? delivery?.deliveryFee ?? 0;

    final id = (json['id'] as num?)?.toInt() ?? 0;
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    final items = <OrderLineItem>[];
    for (final raw in itemsJson) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final name = (map['product_name'] ?? map['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      Map<String, dynamic>? options;
      final rawOpts = map['options'];
      if (rawOpts is Map) {
        options = Map<String, dynamic>.from(rawOpts);
      }
      items.add(
        OrderLineItem(
          productId: map['product_id']?.toString() ?? '',
          productName: name,
          quantity: (map['quantity'] as num?)?.toInt() ?? 1,
          price: (map['price'] as num?)?.toDouble() ?? 0,
          imageUrl: map['image_url']?.toString(),
          options: options,
        ),
      );
    }

    return OrderSummary(
      id: id,
      orderCode: json['order_code']?.toString() ?? 'MM-$id',
      status: json['status']?.toString() ?? 'processing',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: deliveryFee,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      date: _formatDate(json['created_at']?.toString()),
      estimatedTime: deliveryJson?['estimated_time']?.toString() ?? delivery?.estimatedTime,
      delivery: delivery,
      items: items,
    );
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double deliveryFee,
    required double total,
    required String buyerGovernorateId,
    required String city,
    required String areaName,
    required String homeDescription,
    required String paymentMethod,
    File? paymentProof,
    String? paymentProofName,
    String? couponCode,
    double? walletAmount,
    required double latitude,
    required double longitude,
  }) async {
    final fields = <String, dynamic>{
      'items': jsonEncode(items),
      'subtotal': subtotal.toString(),
      'delivery_fee': deliveryFee.toString(),
      'total': total.toString(),
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'buyer_governorate_id': buyerGovernorateId,
      'city': city,
      'area_name': areaName,
      'home_description': homeDescription,
      'payment_method': paymentMethod,
    };
    if (couponCode != null && couponCode.trim().isNotEmpty) {
      fields['coupon_code'] = couponCode.trim();
    }
    if (walletAmount != null && walletAmount > 0) {
      fields['wallet_amount'] = walletAmount.toString();
    }

    final Response<Map<String, dynamic>> res;
    if (paymentProof != null) {
      final filename = paymentProofName ?? paymentProof.path.split(Platform.pathSeparator).last;
      res = await ApiClient.instance.postMultipart(
        '/orders',
        fields: fields,
        files: {
          'payment_proof': await MultipartFile.fromFile(
            paymentProof.path,
            filename: filename,
          ),
        },
      );
    } else {
      res = await ApiClient.instance.postJson(
        '/orders',
        data: {
          'items': items,
          'subtotal': subtotal,
          'delivery_fee': deliveryFee,
          'total': total,
          'buyer_governorate_id': buyerGovernorateId,
          'city': city,
          'area_name': areaName,
          'home_description': homeDescription,
          'payment_method': paymentMethod,
          'latitude': latitude,
          'longitude': longitude,
          if (couponCode != null && couponCode.trim().isNotEmpty) 'coupon_code': couponCode.trim(),
          if (walletAmount != null && walletAmount > 0) 'wallet_amount': walletAmount,
        },
        receiveTimeout: const Duration(seconds: 45),
      );
    }

    return res.data!['data'] as Map<String, dynamic>;
  }
}

class ConfirmReceiptResult {
  const ConfirmReceiptResult({
    required this.delivery,
    required this.pointsEarned,
    required this.pointsBalance,
    required this.message,
  });

  final DeliveryOrder delivery;
  final int pointsEarned;
  final int pointsBalance;
  final String message;
}

class DeliveryRepository {
  DeliveryRepository._();
  static final instance = DeliveryRepository._();

  Future<List<DeliveryOrder>> fetchDeliveries() async {
    final res = await ApiClient.instance.getJson('/deliveries');
    final list = res.data!['data'] as List<dynamic>;
    final sorted = OrderSort.sortDeliveryJson(list.cast<Map<String, dynamic>>());
    return sorted.map((json) => parseDelivery(json)).toList();
  }

  Future<ConfirmReceiptResult> confirmReceipt(String deliveryId) async {
    final res = await ApiClient.instance.postJson('/deliveries/$deliveryId/confirm-receipt');
    final body = res.data!;
    return ConfirmReceiptResult(
      delivery: parseDelivery(body['data'] as Map<String, dynamic>),
      pointsEarned: (body['points_earned'] as num?)?.toInt() ?? 0,
      pointsBalance: (body['points_balance'] as num?)?.toInt() ?? 0,
      message: body['message'] as String? ?? '',
    );
  }

  DeliveryOrder parseDelivery(Map<String, dynamic> json) => _fromJson(json);

  String _orderId(dynamic value) {
    final raw = value?.toString() ?? '';
    if (raw.startsWith('MM-') || raw.startsWith('ZDK-')) return raw;
    if (raw.isNotEmpty) return 'MM-$raw';
    return raw;
  }

  DeliveryOrder _fromJson(Map<String, dynamic> json) {
    final driverJson = json['driver'] as Map<String, dynamic>?;
    // قد يأتي الاسم/الهاتف أيضاً مباشرة على كائن التوصيل
    final driverName = (driverJson?['name'] ?? json['driver_name'])?.toString().trim() ?? '';
    final driverPhone = (driverJson?['phone'] ?? json['driver_phone'])?.toString().trim() ?? '';

    DeliveryDriver? driver;
    if (driverName.isNotEmpty || driverPhone.isNotEmpty) {
      driver = DeliveryDriver(
        name: driverName.isNotEmpty ? driverName : 'كابتن روزي تاج',
        phone: driverPhone,
        vehicle: (driverJson?['vehicle'] ?? json['driver_vehicle'])?.toString() ?? '',
        plateNumber: driverJson?['plate_number']?.toString() ?? '',
        rating: (driverJson?['rating'] as num?)?.toDouble() ?? 4.8,
        governorateId: driverJson?['governorate_id']?.toString() ??
            json['buyer_governorate_id']?.toString() ??
            'damascus',
      );
    }

    return DeliveryOrder(
      id: json['id']?.toString() ?? '',
      orderId: _orderId(json['order_id']),
      status: _status(json['status']?.toString() ?? 'preparing'),
      mode: _mode(json['mode']?.toString() ?? 'same_governorate'),
      address: json['address']?.toString() ?? '',
      itemsSummary: json['items_summary']?.toString() ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      estimatedTime: json['estimated_time']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      sellerGovernorate: json['seller_governorate_id'] != null
          ? DeliveryService.governorateById(json['seller_governorate_id'].toString())
          : null,
      buyerGovernorate: json['buyer_governorate_id'] != null
          ? DeliveryService.governorateById(json['buyer_governorate_id'].toString())
          : null,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      needsCoordination: json['needs_coordination'] == true || json['needs_coordination'] == 1,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      canConfirmReceipt: json['can_confirm_receipt'] == true || json['can_confirm_receipt'] == 1,
      driver: driver,
    );
  }

  DeliveryStatus _status(String value) {
    switch (value) {
      case 'awaiting_coordination':
        return DeliveryStatus.awaitingCoordination;
      case 'preparing':
        return DeliveryStatus.preparing;
      case 'picked_up':
        return DeliveryStatus.pickedUp;
      case 'on_the_way':
        return DeliveryStatus.onTheWay;
      case 'arrived':
        return DeliveryStatus.arrived;
      case 'delivered':
        return DeliveryStatus.delivered;
      default:
        return DeliveryStatus.preparing;
    }
  }

  DeliveryMode _mode(String value) {
    switch (value) {
      case 'local_express':
        return DeliveryMode.localExpress;
      case 'cross_governorate':
        return DeliveryMode.crossGovernorate;
      default:
        return DeliveryMode.sameGovernorate;
    }
  }
}
