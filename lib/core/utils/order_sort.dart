import 'package:matchy_matchy/core/repositories/order_repository.dart';

abstract final class OrderSort {
  /// 0 = قيد المعالجة، 1 = مُسلَّم، 2 = مرفوض
  static int orderStatusPriority(String status) {
    if (status == 'cancelled') return 2;
    if (status == 'delivered') return 1;
    return 0;
  }

  /// 0 = معلّقة، 1 = مقبولة، 2 = مرفوضة
  static int manualInvoiceStatusPriority(String status) {
    if (status == 'rejected') return 2;
    if (status == 'approved') return 1;
    return 0;
  }

  static int deliveryStatusPriority(String status) {
    if (status == 'cancelled') return 2;
    if (status == 'delivered') return 1;
    return 0;
  }

  static List<OrderSummary> sortOrders(List<OrderSummary> orders) {
    final copy = List<OrderSummary>.from(orders);
    copy.sort((a, b) {
      final priority = orderStatusPriority(a.status).compareTo(orderStatusPriority(b.status));
      if (priority != 0) return priority;
      return b.id.compareTo(a.id);
    });
    return copy;
  }

  static List<Map<String, dynamic>> sortAdminOrders(List<Map<String, dynamic>> orders) {
    final copy = List<Map<String, dynamic>>.from(orders);
    copy.sort((a, b) {
      final statusA = a['status'] as String? ?? '';
      final statusB = b['status'] as String? ?? '';
      final priority = orderStatusPriority(statusA).compareTo(orderStatusPriority(statusB));
      if (priority != 0) return priority;

      final idA = a['id'] as int? ?? 0;
      final idB = b['id'] as int? ?? 0;
      return idB.compareTo(idA);
    });
    return copy;
  }

  static List<Map<String, dynamic>> sortManualInvoices(List<Map<String, dynamic>> invoices) {
    final copy = List<Map<String, dynamic>>.from(invoices);
    copy.sort((a, b) {
      final statusA = a['status'] as String? ?? '';
      final statusB = b['status'] as String? ?? '';
      final priority = manualInvoiceStatusPriority(statusA).compareTo(manualInvoiceStatusPriority(statusB));
      if (priority != 0) return priority;

      final idA = a['id'] as int? ?? 0;
      final idB = b['id'] as int? ?? 0;
      return idB.compareTo(idA);
    });
    return copy;
  }

  static List<Map<String, dynamic>> sortDeliveryJson(List<Map<String, dynamic>> deliveries) {
    final copy = List<Map<String, dynamic>>.from(deliveries);
    copy.sort((a, b) {
      final statusA = a['status'] as String? ?? '';
      final statusB = b['status'] as String? ?? '';
      final priority = deliveryStatusPriority(statusA).compareTo(deliveryStatusPriority(statusB));
      if (priority != 0) return priority;

      final idA = a['id'] as String? ?? '';
      final idB = b['id'] as String? ?? '';
      return idB.compareTo(idA);
    });
    return copy;
  }
}
