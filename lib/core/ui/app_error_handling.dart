import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/bootstrap/app_bootstrap.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

/// Prevents Flutter's default red error screens and logs failures safely.
void configureAppErrorHandling() {
  ErrorWidget.builder = (details) => AppFriendlyErrorWidget(details: details);

  FlutterError.onError = (details) {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('Uncaught async error: $error\n$stack');
    }
    return true;
  };
}

Future<void> runAppGuarded(Future<void> Function() bootstrap, Widget app) async {
  await runZonedGuarded(() async {
    configureAppErrorHandling();
    await bootstrap();
    runApp(app);
    // تحميل ثقيل بعد أول إطار (السبلاش يظهر فوراً).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppBootstrap.startDeferred();
    });
  }, (error, stack) {
    if (kDebugMode) {
      debugPrint('Zone error: $error\n$stack');
    }
  });
}

class AppFriendlyErrorWidget extends StatelessWidget {
  const AppFriendlyErrorWidget({super.key, required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundLight,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 56, color: AppColors.error.withValues(alpha: 0.85)),
                const SizedBox(height: 16),
                Text(
                  AppStrings.unexpectedErrorTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.unexpectedErrorBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  Text(
                    details.exceptionAsString(),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
