import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/data/delivery_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/services/delivery_service.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

/// اختيار موقع التوصيل: موقعي الحالي أو موقع آخر على الخريطة، ثم وصف البيت إجباري.
class DeliveryLocationChooser extends StatefulWidget {
  const DeliveryLocationChooser({
    super.key,
    required this.locationReady,
    required this.locationLoading,
    required this.onUseMyLocation,
    required this.onPickOtherLocation,
    this.selectedAddress,
    this.governorateLabel,
    this.compact = false,
    this.locationRevision = 0,
    this.homeDescriptionError,
    this.onHomeDescriptionChanged,
  });

  final bool locationReady;
  final bool locationLoading;
  final VoidCallback onUseMyLocation;
  final VoidCallback onPickOtherLocation;
  final String? selectedAddress;
  final String? governorateLabel;
  final bool compact;
  final int locationRevision;
  final String? homeDescriptionError;
  final VoidCallback? onHomeDescriptionChanged;

  @override
  State<DeliveryLocationChooser> createState() => _DeliveryLocationChooserState();
}

class _DeliveryLocationChooserState extends State<DeliveryLocationChooser> {
  late final TextEditingController _homeController;
  int _lastRevision = -1;

  @override
  void initState() {
    super.initState();
    _homeController = TextEditingController(text: DeliverySession.homeDescription);
    _homeController.addListener(_syncHomeDescription);
    _lastRevision = widget.locationRevision;
  }

  @override
  void didUpdateWidget(DeliveryLocationChooser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.locationRevision != _lastRevision) {
      _lastRevision = widget.locationRevision;
      final next = DeliverySession.homeDescription;
      if (_homeController.text != next) {
        _homeController.text = next;
      }
    }
  }

  @override
  void dispose() {
    _homeController.removeListener(_syncHomeDescription);
    _homeController.dispose();
    super.dispose();
  }

  void _syncHomeDescription() {
    DeliverySession.homeDescription = _homeController.text;
    widget.onHomeDescriptionChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return _box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.deliveryLocationChoose,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: widget.compact ? 13 : 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.locationReady) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.deliveryLocationSelected,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.selectedAddress ?? DeliverySession.deliveryLocationSummary,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: widget.compact ? 12 : 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppStrings.yourGovernorate}: ${widget.governorateLabel ?? DeliveryService.governorateById(DeliverySession.buyerGovernorateId).name}',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              AppStrings.homeDescription,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: widget.compact ? 13 : 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _homeController,
              maxLines: 3,
              minLines: 2,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: AppStrings.enterHomeDescription,
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                errorText: widget.homeDescriptionError,
              ),
            ),
            const SizedBox(height: 14),
          ],
          GradientButton(
            label: widget.locationLoading ? AppStrings.detectingLocation : AppStrings.useMyLocation,
            height: widget.compact ? 44 : 48,
            onPressed: widget.locationLoading ? null : widget.onUseMyLocation,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: widget.onPickOtherLocation,
            icon: const Icon(Icons.map_outlined),
            label: Text(AppStrings.pickOtherLocation),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(double.infinity, widget.compact ? 44 : 48),
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              AppStrings.pickOtherLocationHint,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: widget.compact ? 11 : 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _box({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
