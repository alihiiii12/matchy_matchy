import 'package:flutter/material.dart';

/// Official rozetaj brand mark.
abstract final class BrandAssets {
  /// Full-color logo (pastel background) — splash / hero.
  static const logo = 'assets/images/logo.png';

  /// Dark mark for light surfaces (login, headers).
  static const logoDark = 'assets/images/matchy_logo_dark.png';
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size,
    this.width,
    this.height,
    this.dark = false,
    this.circular = true,
    this.fit = BoxFit.cover,
    this.border,
  });

  /// قطر الدائرة (يفضّل استخدامه بدل width/height).
  final double? size;
  final double? width;
  final double? height;
  final bool dark;
  final bool circular;
  final BoxFit fit;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final diameter = size ?? width ?? height ?? 120;
    final image = Image.asset(
      dark ? BrandAssets.logoDark : BrandAssets.logo,
      width: diameter,
      height: diameter,
      fit: fit,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      semanticLabel: 'rozetaj',
    );

    if (!circular) {
      return SizedBox(
        width: width ?? diameter,
        height: height ?? diameter,
        child: image,
      );
    }

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: border,
      ),
      clipBehavior: Clip.antiAlias,
      child: image,
    );
  }
}
