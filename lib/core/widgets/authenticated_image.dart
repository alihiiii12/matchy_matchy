import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/network/authenticated_image_loader.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class AuthenticatedImage extends StatefulWidget {
  const AuthenticatedImage({
    super.key,
    required this.apiPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
  });

  final String apiPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;

  @override
  State<AuthenticatedImage> createState() => _AuthenticatedImageState();
}

class _AuthenticatedImageState extends State<AuthenticatedImage> {
  late Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = AuthenticatedImageLoader.loadBytes(widget.apiPath);
  }

  @override
  void didUpdateWidget(covariant AuthenticatedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.apiPath != widget.apiPath) {
      _future = AuthenticatedImageLoader.loadBytes(widget.apiPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final bytes = snapshot.data;
        if (bytes == null) {
          return widget.errorWidget ??
              SizedBox(
                width: widget.width,
                height: widget.height,
                child: Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
              );
        }

        Widget image = Image.memory(
          bytes,
          key: ValueKey(widget.apiPath),
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          gaplessPlayback: true,
        );

        if (widget.borderRadius != null) {
          image = ClipRRect(borderRadius: widget.borderRadius!, child: image);
        }

        return image;
      },
    );
  }
}
