/// إعدادات الدعم الفني وخدمة العملاء
abstract final class SupportConfig {
  /// رقم واتساب بصيغة دولية بدون + أو 00 (محلي: 0967257907)
  static const String whatsappPhone = '963967257907';

  static const String whatsappDefaultMessage = 'مرحباً، أحتاج دعم فني من تطبيق rozetaj';

  static const List<({String display, String tel})> customerPhones = [
    (display: '+90 538 714 44 80', tel: '+905387144480'),
    (display: '+963954 377 428', tel: '+963954377428'),
  ];
}
