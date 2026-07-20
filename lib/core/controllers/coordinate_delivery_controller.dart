import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/data/delivery_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/delivery.dart';

class CoordinateDeliveryController extends GetxController {
  static const timeSlots = ['09:00 - 11:00', '10:00 - 12:00', '14:00 - 16:00', '16:00 - 18:00'];

  late final CartDeliveryAnalysis analysis;
  final timeSlot = DeliverySession.coordinatedTimeSlot.obs;
  final noteController = TextEditingController(text: DeliverySession.coordinationNote);

  List<ProductDeliveryInfo> get crossItems =>
      analysis.items.where((i) => i.mode == DeliveryMode.crossGovernorate).toList();

  @override
  void onInit() {
    super.onInit();
    analysis = Get.arguments as CartDeliveryAnalysis;
    timeSlot.value = DeliverySession.coordinatedTimeSlot;
  }

  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }

  void selectTimeSlot(String slot) => timeSlot.value = slot;

  void contactDeliveryTeam() {
    Get.snackbar('', '${AppStrings.contactDeliveryTeam}: ${AppStrings.deliveryTeamPhone}');
  }

  void confirm() {
    DeliverySession.interGovCoordinated = true;
    DeliverySession.coordinatedTimeSlot = timeSlot.value;
    DeliverySession.coordinationNote = noteController.text.trim();
    Get.back(result: true);
  }
}

class CoordinateDeliveryBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(CoordinateDeliveryController());
  }
}
