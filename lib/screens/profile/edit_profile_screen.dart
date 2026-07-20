import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/edit_profile_controller.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/app_text_field.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';
import 'package:matchy_matchy/core/widgets/profile_avatar.dart';

class EditProfileScreen extends GetView<EditProfileController> {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.editProfile)),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Obx(
                () => ProfileAvatar(
                  radius: 52,
                  imageUrl: AuthService.instance.userRx.value?.avatarUrl ?? controller.existingAvatarUrl,
                  imageFile: controller.avatarFile.value,
                  showEditBadge: true,
                  onTap: controller.submitting.value ? null : controller.pickAvatar,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: controller.pickAvatar,
                child: Text(AppStrings.changeProfilePhoto),
              ),
            ),
            const SizedBox(height: 24),
            Obx(
              () => AppTextField(
                label: AppStrings.fullName,
                hint: AppStrings.enterFullName,
                icon: Icons.person_outline,
                controller: controller.nameController,
                textInputAction: TextInputAction.next,
                errorText: controller.nameError.value,
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => AppTextField(
                label: AppStrings.phone,
                hint: controller.isContactLocked ? controller.lockedPhoneDisplay : AppStrings.enterPhone,
                icon: Icons.phone_outlined,
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                readOnly: controller.isContactLocked,
                errorText: controller.phoneError.value,
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => AppTextField(
                label: AppStrings.email,
                hint: AppStrings.email,
                icon: Icons.email_outlined,
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                readOnly: controller.isContactLocked,
                errorText: controller.emailError.value,
              ),
            ),
            if (controller.isContactLocked)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  AppStrings.sellerProfileContactLockedHint,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              )
            else if (controller.isAdmin)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  AppStrings.adminProfileContactHint,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  AppStrings.profileContactChangeHint,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            const SizedBox(height: 28),
            Obx(
              () => GradientButton(
                label: controller.submitting.value ? AppStrings.saving : AppStrings.saveChanges,
                onPressed: controller.submitting.value ? null : controller.submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
