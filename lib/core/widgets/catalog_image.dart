import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/data/catalog_meta.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class CatalogImage extends StatelessWidget {
  const CatalogImage({
    super.key,
    this.imageUrl,
    required this.fallbackIcon,
    this.fallbackColor,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    this.circular = false,
  });

  final String? imageUrl;
  final IconData fallbackIcon;
  final Color? fallbackColor;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final color = fallbackColor ?? AppColors.accent;
    final radius = circular ? null : borderRadius;
    final shape = circular ? BoxShape.circle : BoxShape.rectangle;

    Widget child;
    final url = CatalogMeta.resolveImageUrl(imageUrl);
    if (url != null && url.isNotEmpty) {
      child = Image.network(
        url,
        fit: fit,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _fallbackBox(color: color, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
        },
        errorBuilder: (context, error, stackTrace) => _fallbackBox(
          color: color,
          child: Icon(fallbackIcon, color: color, size: _iconSize),
        ),
      );
    } else {
      child = _fallbackBox(color: color, child: Icon(fallbackIcon, color: color, size: _iconSize));
    }

    return Container(
      width: _layoutWidth,
      height: _layoutHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: radius,
        shape: shape,
      ),
      child: _usesExplicitSize ? child : SizedBox.expand(child: child),
    );
  }

  double get _iconSize {
    final w = width;
    final h = height;

    double? finiteBase;
    if (w != null && w.isFinite) {
      finiteBase = w;
    }
    if (h != null && h.isFinite) {
      finiteBase = finiteBase == null ? h : (finiteBase < h ? finiteBase : h);
    }

    return (finiteBase ?? 48) * 0.45;
  }

  bool get _usesExplicitSize {
    final w = width;
    final h = height;
    return (w != null && w.isFinite) || (h != null && h.isFinite);
  }

  double? get _layoutWidth {
    final w = width;
    return w != null && w.isFinite ? w : null;
  }

  double? get _layoutHeight {
    final h = height;
    return h != null && h.isFinite ? h : null;
  }

  Widget _fallbackBox({required Color color, required Widget child}) {
    if (!_usesExplicitSize) {
      return ColoredBox(
        color: color.withValues(alpha: 0.12),
        child: Center(child: child),
      );
    }

    return Container(
      width: _layoutWidth,
      height: _layoutHeight,
      alignment: Alignment.center,
      color: color.withValues(alpha: 0.12),
      child: child,
    );
  }
}
