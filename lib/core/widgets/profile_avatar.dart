import 'dart:io';

import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/data/catalog_meta.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/authenticated_image.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.imageFile,
    this.radius = 36,
    this.onTap,
    this.showEditBadge = false,
  });

  final String? imageUrl;
  final File? imageFile;
  final double radius;
  final VoidCallback? onTap;
  final bool showEditBadge;

  Widget _fallback() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.inputFill,
      child: Icon(Icons.person, size: radius, color: AppColors.primary),
    );
  }

  Widget _avatarContent() {
    if (imageFile != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(imageFile!),
      );
    }

    final apiPath = CatalogMeta.apiPathFromUrl(imageUrl);
    if (apiPath != null && CatalogMeta.isAuthenticatedApiImage(imageUrl)) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.inputFill,
        child: ClipOval(
          child: AuthenticatedImage(
            apiPath: apiPath,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorWidget: Icon(Icons.person, size: radius, color: AppColors.primary),
          ),
        ),
      );
    }

    final url = CatalogMeta.resolveImageUrl(imageUrl);
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.inputFill,
        child: ClipOval(
          child: Image.network(
            url,
            key: ValueKey(url),
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: radius, color: AppColors.primary),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return SizedBox(
                width: radius * 2,
                height: radius * 2,
                child: Center(
                  child: SizedBox(
                    width: radius * 0.6,
                    height: radius * 0.6,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return _fallback();
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _avatarContent();
    final size = radius * 2;

    if (!showEditBadge && onTap == null) {
      return avatar;
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (showEditBadge)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.34,
                height: size * 0.34,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: Icon(Icons.camera_alt, size: size * 0.18, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
