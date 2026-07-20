import 'package:url_launcher/url_launcher.dart';
import 'package:matchy_matchy/core/config/support_config.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';

abstract final class WhatsappSupportService {
  static Future<void> openTechnicalSupport() async {
    final phone = SupportConfig.whatsappPhone.replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty) {
      showMatchySnackBar(
        message: AppStrings.whatsappSupportNotConfigured,
        type: AppSnackBarType.info,
      );
      return;
    }

    final uri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(SupportConfig.whatsappDefaultMessage)}',
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      showMatchySnackBar(
        message: AppStrings.whatsappOpenFailed,
        type: AppSnackBarType.error,
      );
    }
  }
}
