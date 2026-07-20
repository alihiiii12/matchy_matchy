import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/points_gifts_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/points_format.dart';

class PointsGiftsScreen extends GetView<PointsGiftsController> {
  const PointsGiftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.convertPointsToGifts)),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    controller.error.value!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.error, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => controller.load(force: true),
                    child: Text(AppStrings.retryAction),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.load(force: true),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${AppStrings.pointsBalance}: ${PointsFormat.display(controller.balance.value)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (controller.gifts.isEmpty)
                Center(child: Text(AppStrings.noGiftsYet))
              else
                ...controller.gifts.map((gift) {
                  final id = gift['id'] as int;
                  final cost = gift['points_cost'] as int? ?? 0;
                  final redeeming = controller.redeemingId.value == id;
                  final canRedeem = controller.balance.value >= cost;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(gift['title'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          if ((gift['reward_summary'] as String?)?.isNotEmpty == true ||
                              (gift['description'] as String?)?.isNotEmpty == true) ...[
                            const SizedBox(height: 6),
                            Text(
                              (gift['reward_summary'] as String?)?.isNotEmpty == true
                                  ? gift['reward_summary'] as String
                                  : gift['description'] as String,
                              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text('$cost ${AppStrings.pointsUnit}', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
                              const Spacer(),
                              FilledButton(
                                onPressed: redeeming || !canRedeem ? null : () => controller.redeem(gift),
                                child: redeeming
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : Text(AppStrings.redeemGift),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      }),
    );
  }
}
