
import 'package:matchy_matchy/app.dart';
import 'package:matchy_matchy/core/bootstrap/app_bootstrap.dart';
import 'package:matchy_matchy/core/ui/app_error_handling.dart';

void main() {
  runAppGuarded(() => AppBootstrap.minimalBeforeRunApp(), const ZadakApp());
}
