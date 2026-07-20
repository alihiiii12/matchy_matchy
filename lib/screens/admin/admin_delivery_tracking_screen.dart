import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/admin_delivery_tracking_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class AdminDeliveryTrackingScreen extends GetView<AdminDeliveryTrackingController> {
  const AdminDeliveryTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.adminDriverTracking),
        actions: [
          Obx(() {
            if (controller.refreshing.value) {
              return const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return IconButton(
              onPressed: () => controller.load(),
              icon: const Icon(Icons.refresh),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value && controller.tracking.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null && controller.tracking.value == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(controller.error.value!, style: TextStyle(color: AppColors.error)),
            ),
          );
        }

        final data = controller.tracking.value;
        if (data == null) {
          return Center(child: Text(AppStrings.noTrackingData));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TrackingHeader(controller: controller, data: data),
            Expanded(child: _TrackingMap(controller: controller)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _legend(AppColors.accent, AppStrings.driverOnMap),
                  _legend(AppColors.primary, AppStrings.routeOnMap),
                  _legend(AppColors.error, AppStrings.customerOnMap),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _TrackingHeader extends StatelessWidget {
  const _TrackingHeader({required this.controller, required this.data});

  final AdminDeliveryTrackingController controller;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final driver = data['driver'] as Map<String, dynamic>?;
    final dest = data['destination'] as Map<String, dynamic>?;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['order_code'] as String? ?? '',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                controller.isTrackingActive ? Icons.gps_fixed : Icons.gps_off,
                size: 18,
                color: controller.isTrackingActive ? AppColors.success : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  controller.statusLabel,
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (driver != null) ...[
            const SizedBox(height: 4),
            Text(
              '${AppStrings.driverOnMap}: ${driver['name']} — ${driver['phone'] ?? ''}',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ] else if (controller.isCustomerOnly) ...[
            const SizedBox(height: 4),
            Text(
              AppStrings.customerLocation,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ],
          if (dest?['address'] != null) ...[
            const SizedBox(height: 4),
            Text(
              dest!['address'] as String,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}

/// الخريطة ثابتة — تُحدَّث الطبقات فقط بدون إعادة تحميل البلاطات.
class _TrackingMap extends StatelessWidget {
  const _TrackingMap({required this.controller});

  final AdminDeliveryTrackingController controller;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FlutterMap(
        key: const ValueKey('admin_delivery_tracking_map'),
        mapController: controller.mapController,
        options: MapOptions(
          initialCenter: controller.mapCenter,
          initialZoom: controller.mapZoom,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.matchymatchy.app',
            maxNativeZoom: 19,
            keepBuffer: 3,
            panBuffer: 1,
            retinaMode: false,
          ),
          Obx(() {
            final trail = controller.trailPoints;
            if (trail.length < 2) return const SizedBox.shrink();
            return PolylineLayer(
              polylines: [
                Polyline(
                  points: trail,
                  color: AppColors.primary,
                  strokeWidth: 4,
                ),
              ],
            );
          }),
          Obx(() {
            final dest = controller.destinationPoint;
            final driver = controller.driverPoint;
            final markers = <Marker>[];
            if (dest != null) {
              markers.add(
                Marker(
                  point: dest,
                  width: 44,
                  height: 44,
                  child: const Icon(Icons.home, color: AppColors.error, size: 36),
                ),
              );
            }
            if (driver != null) {
              markers.add(
                Marker(
                  point: driver,
                  width: 48,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.local_shipping, color: Colors.white, size: 22),
                  ),
                ),
              );
            }
            if (markers.isEmpty) return const SizedBox.shrink();
            return MarkerLayer(markers: markers);
          }),
        ],
      ),
    );
  }
}
