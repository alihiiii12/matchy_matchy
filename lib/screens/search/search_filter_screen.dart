import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/search_filter_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class SearchFilterScreen extends GetView<SearchFilterController> {
  const SearchFilterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.filter),
        actions: [
          TextButton(
            onPressed: controller.clearAll,
            child: Text(AppStrings.clearFilter),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.selectSection, style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                key: ValueKey('category-${controller.selectedCategoryId.value}-${controller.categories.length}'),
                initialValue: controller.selectedCategoryId.value,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                hint: Text(AppStrings.allSections),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(AppStrings.allSections),
                  ),
                  ...controller.categories.map(
                    (cat) => DropdownMenuItem<String?>(
                      value: cat.id,
                      child: Text(cat.localizedName),
                    ),
                  ),
                ],
                onChanged: controller.selectCategory,
              ),
              const Spacer(),
              GradientButton(label: AppStrings.applyFilter, onPressed: controller.applyFilter),
            ],
          ),
        );
      }),
    );
  }
}
