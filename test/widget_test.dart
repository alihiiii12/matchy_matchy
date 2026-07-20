import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/app.dart';
import 'package:matchy_matchy/core/controllers/theme_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('ZADAK app shows splash screen on launch', (tester) async {
    Get.put(ThemeController());
    await tester.pumpWidget(const ZadakApp());
    await tester.pump();
    expect(find.text(AppStrings.splashTagline), findsOneWidget);
  });
}
