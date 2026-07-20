import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:matchy_matchy/core/controllers/admin_create_driver_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class AdminCreateDriverScreen extends GetView<AdminCreateDriverController> {
  const AdminCreateDriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.createDriverAccount)),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _FieldLabel(AppStrings.driverFullName),
            TextFormField(
              controller: controller.nameController,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم الكامل مطلوب' : null,
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.vehicleType),
            TextFormField(controller: controller.vehicleTypeController),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.plateNumber),
            TextFormField(controller: controller.plateNumberController),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.birthRegion),
            TextFormField(
              controller: controller.birthRegionController,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'منطقة التولد مطلوبة' : null,
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.birthDate),
            Obx(
              () => InkWell(
                onTap: () => controller.pickBirthDate(context),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.inputFill,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    suffixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    controller.birthDate.value == null
                        ? 'اختر تاريخ التولد'
                        : DateFormat('yyyy/MM/dd').format(controller.birthDate.value!),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.fatherName),
            TextFormField(
              controller: controller.fatherNameController,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم الأب مطلوب' : null,
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.motherName),
            TextFormField(
              controller: controller.motherNameController,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم الأم مطلوب' : null,
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.nationalId),
            TextFormField(
              controller: controller.nationalIdController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => (v == null || v.trim().length < 5) ? 'الرقم الوطني مطلوب' : null,
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.phone),
            TextFormField(
              controller: controller.phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]'))],
              validator: (v) => (v == null || (v.trim().length < 9)) ? AppStrings.phoneRequired : null,
            ),
            const SizedBox(height: 16),
            const _FieldLabel('نظام ربح الكابتن'),
            Obx(
              () => Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('اشتراك شهري ثابت'),
                    value: 'subscription',
                    groupValue: controller.payModel.value,
                    onChanged: (v) => controller.payModel.value = v ?? 'subscription',
                  ),
                  RadioListTile<String>(
                    title: const Text('نسبة من كل توصيل'),
                    value: 'percentage',
                    groupValue: controller.payModel.value,
                    onChanged: (v) => controller.payModel.value = v ?? 'percentage',
                  ),
                ],
              ),
            ),
            Obx(() {
              if (controller.payModel.value == 'percentage') {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const _FieldLabel('نسبة العمولة %'),
                    TextFormField(
                      controller: controller.commissionPercentController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final n = double.tryParse(v?.trim() ?? '');
                        if (n == null || n <= 0 || n > 100) return 'أدخل نسبة بين 1 و 100';
                        return null;
                      },
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _FieldLabel(AppStrings.subscriptionMonths),
                  TextFormField(
                    controller: controller.subscriptionMonthsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      if (n == null || n < 1) return 'أدخل مدة صحيحة بالأشهر';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel(AppStrings.driverSubscriptionAmountPaid),
                  TextFormField(
                    controller: controller.subscriptionAmountPaidController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      suffixText: AppStrings.currencySymbol,
                    ),
                    validator: (v) {
                      final value = double.tryParse(v?.trim() ?? '');
                      if (value == null || value < 0) return AppStrings.driverSubscriptionAmountPaidRequired;
                      return null;
                    },
                  ),
                ],
              );
            }),
            const SizedBox(height: 20),
            _IdPhotoPicker(
              label: AppStrings.idFrontPhoto,
              fileName: controller.idFrontName,
              onPick: () => controller.pickIdPhoto(front: true),
            ),
            const SizedBox(height: 12),
            _IdPhotoPicker(
              label: AppStrings.idBackPhoto,
              fileName: controller.idBackName,
              onPick: () => controller.pickIdPhoto(front: false),
            ),
            const SizedBox(height: 28),
            Obx(
              () => GradientButton(
                label: controller.submitting.value ? AppStrings.creatingDriver : AppStrings.createDriver,
                onPressed: controller.submitting.value ? null : controller.submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _IdPhotoPicker extends StatelessWidget {
  const _IdPhotoPicker({required this.label, required this.fileName, required this.onPick});

  final String label;
  final RxnString fileName;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => OutlinedButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.upload_file_outlined),
        label: Text(fileName.value ?? label),
        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52), alignment: Alignment.centerLeft),
      ),
    );
  }
}
