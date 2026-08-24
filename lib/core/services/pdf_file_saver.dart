import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';

abstract final class PdfFileSaver {
  static const _archiveFolder = 'rozetaj';

  static Future<String> saveArchivePdf(Uint8List bytes, String baseName) async {
    final timestamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    final fileName = '$baseName-$timestamp.pdf';

    if (Platform.isAndroid) {
      await _ensureAndroidStoragePermission();
      final savedPath = await _trySaveToDownloads(bytes, fileName);
      if (savedPath != null) return savedPath;
    }

    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && userProfile.isNotEmpty) {
        final desktop = Directory('$userProfile\\Desktop');
        if (!desktop.existsSync()) {
          desktop.createSync(recursive: true);
        }
        final file = File('${desktop.path}\\$fileName');
        await file.writeAsBytes(bytes, flush: true);
        return file.path;
      }
    }

    final downloads = await getDownloadsDirectory();
    if (downloads != null) {
      final dir = Directory('${downloads.path}${Platform.pathSeparator}$_archiveFolder');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final file = File('${dir.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    }

    throw const PdfSaveException('تعذر الوصول إلى مجلد التنزيلات');
  }

  static Future<void> openSavedPdf(String path) async {
    final result = await OpenFilex.open(path);
    if (result.type == ResultType.done) return;

    final file = File(path);
    if (!file.existsSync()) return;

    await Printing.sharePdf(
      bytes: await file.readAsBytes(),
      filename: path.split(Platform.pathSeparator).last,
    );
  }

  static Future<String?> _trySaveToDownloads(Uint8List bytes, String fileName) async {
    final candidates = <Directory>[];

    final downloads = await getDownloadsDirectory();
    if (downloads != null) {
      candidates.add(Directory('${downloads.path}${Platform.pathSeparator}$_archiveFolder'));
    }

    candidates.add(Directory('/storage/emulated/0/Download/$_archiveFolder'));

    for (final dir in candidates) {
      try {
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        final file = File('${dir.path}${Platform.pathSeparator}$fileName');
        await file.writeAsBytes(bytes, flush: true);
        return file.path;
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  static Future<void> _ensureAndroidStoragePermission() async {
    if (!Platform.isAndroid) return;
    if (await Permission.storage.isGranted) return;
    await Permission.storage.request();
  }
}

class PdfSaveException implements Exception {
  const PdfSaveException(this.message);

  final String message;

  @override
  String toString() => message;
}
