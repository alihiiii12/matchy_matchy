import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:matchy_matchy/core/controllers/driver_jobs_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/driver_job_pricing.dart';
import 'package:matchy_matchy/core/widgets/driver_job_products.dart';
import 'package:matchy_matchy/core/widgets/driver_manual_invoice_card.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';
import 'package:matchy_matchy/screens/checkout/map_location_picker_screen.dart';

class DriverJobDetailScreen extends GetView<DriverJobDetailController> {
  const DriverJobDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.viewDeliveryJob)),
      body: Obx(() {
        if (controller.loading.value && controller.job.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null && controller.job.value == null) {
          return Center(child: Text(controller.error.value!, style: TextStyle(color: AppColors.error)));
        }

        final job = controller.job.value;
        if (job == null) {
          return Center(child: Text(AppStrings.noDriverJobsYet));
        }

        final customer = job['customer'] as Map<String, dynamic>?;
        final canAccept = job['can_accept'] as bool? ?? false;
        final canReject = job['can_reject'] as bool? ?? canAccept;
        final canStartTransit = job['can_start_transit'] as bool? ?? false;
        final canMarkDelivered = job['can_mark_delivered'] as bool? ?? false;
        final canConfirmPayment = job['can_confirm_payment'] as bool? ?? false;
        final paymentCollected = job['payment_collected'] as bool? ?? false;
        final lat = job['destination_latitude'] as num?;
        final lng = job['destination_longitude'] as num?;
        final homeDescription = (job['home_description'] as String?)?.trim() ?? '';
        final city = (job['city'] as String?)?.trim() ?? '';
        final area = (job['area_name'] as String?)?.trim() ?? '';
        final paymentLabel = (job['payment_method_label'] as String?)?.trim() ?? '';

        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              Text(job['order_code'] as String? ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  job['status_label'] as String? ?? '',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Text(job['address'] as String? ?? '', style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
              if (city.isNotEmpty || area.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  [if (city.isNotEmpty) city, if (area.isNotEmpty) area].join(' · '),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
              if (paymentLabel.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${AppStrings.paymentMethod}: $paymentLabel',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
              if (DriverManualInvoiceCard.isManualJob(job)) ...[
                const SizedBox(height: 12),
                DriverManualInvoiceCard(content: DriverManualInvoiceCard.contentOf(job) ?? ''),
              ],
              const SizedBox(height: 12),
              DriverJobProducts(job: job),
              const SizedBox(height: 12),
              DriverJobPricing(job: job),
              if (customer != null) ...[
                const SizedBox(height: 16),
                Text('${AppStrings.customer}: ${customer['name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                if ((customer['phone'] as String?)?.isNotEmpty == true)
                  Text('${AppStrings.phone}: ${customer['phone']}', style: TextStyle(color: AppColors.textSecondary)),
              ],
              if (job['estimated_time'] != null) ...[
                const SizedBox(height: 12),
                Text('${AppStrings.expectedDelivery}: ${job['estimated_time']}'),
              ],
              if ((job['rejection_reason'] as String?)?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    '${AppStrings.rejectDeliveryJobReason}: ${job['rejection_reason']}',
                    style: TextStyle(color: AppColors.error, height: 1.5),
                  ),
                ),
              ],
              if (lat != null && lng != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.customerLocation,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    Text(
                      'يتحدّث تلقائياً',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    key: ValueKey('cust-map-${lat}_$lng'),
                    height: 220,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(lat.toDouble(), lng.toDouble()),
                        initialZoom: 15,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: MapLocationPickerScreen.userAgentPackageName,
                          maxNativeZoom: 19,
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(lat.toDouble(), lng.toDouble()),
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_on, color: AppColors.accent, size: 40),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Text(
                  AppStrings.customerLocationUnavailable,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
              if (homeDescription.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.homeDescription,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        homeDescription,
                        style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              if (canAccept) ...[
                GradientButton(label: AppStrings.acceptDeliveryJob, onPressed: controller.accept),
                if (canReject) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: controller.reject,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                    ),
                    child: Text(AppStrings.rejectDeliveryJob),
                  ),
                ],
              ],
              if (canStartTransit) ...[
                const SizedBox(height: 12),
                GradientButton(label: AppStrings.startDeliveryTrip, onPressed: controller.startTrip),
              ],
              if (canConfirmPayment) ...[
                const SizedBox(height: 12),
                GradientButton(
                  label: 'تأكيد قبض المبلغ',
                  onPressed: controller.confirmPayment,
                ),
              ],
              if (paymentCollected && !canMarkDelivered) ...[
                const SizedBox(height: 8),
                Text(
                  'تم تأكيد القبض — أكّد التسليم لإكمال الطلب',
                  style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                ),
              ],
              if (canMarkDelivered) ...[
                const SizedBox(height: 12),
                GradientButton(
                  label: AppStrings.driverMarkDelivered,
                  onPressed: controller.markDelivered,
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}
