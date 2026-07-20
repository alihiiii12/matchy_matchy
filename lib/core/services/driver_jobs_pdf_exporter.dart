import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:matchy_matchy/core/services/pdf_file_saver.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';

class DriverJobsPdfExporter {
  DriverJobsPdfExporter._();

  static final _latinRun = RegExp(r'[A-Za-z0-9@._+\-/\\,%:ZDK\-]+');
  static final _arabicRun = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]+',
  );

  static Future<String> exportAndSave(List<Map<String, dynamic>> jobs) async {
    final bytes = await _buildPdfBytes(jobs);
    return PdfFileSaver.saveArchivePdf(bytes, 'matchy-driver-jobs-archive');
  }

  static Future<Uint8List> _buildPdfBytes(List<Map<String, dynamic>> jobs) async {
    final arabicFont = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'));
    final englishFont = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    final generatedAt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    final doc = pw.Document(title: 'matchy matchy Driver Jobs Archive', author: 'matchy matchy');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.symmetric(horizontal: 22, vertical: 26),
        theme: pw.ThemeData.withFont(base: englishFont, bold: englishFont),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _mixedText('أرشيف مهام التوصيل — matchy matchy', arabicFont, englishFont, fontSize: 18, bold: true),
            pw.SizedBox(height: 6),
            _mixedText('تاريخ التصدير: $generatedAt', arabicFont, englishFont, fontSize: 10),
            _mixedText('عدد المهام: ${jobs.length}', arabicFont, englishFont, fontSize: 10),
          ],
        ),
        build: (context) => [
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(2.2),
              3: const pw.FlexColumnWidth(1.2),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cell('الطلب', arabicFont, englishFont, bold: true),
                  _cell('الحالة', arabicFont, englishFont, bold: true),
                  _cell('العنوان', arabicFont, englishFont, bold: true),
                  _cell('الزبون', arabicFont, englishFont, bold: true),
                  _cell('الإجمالي', arabicFont, englishFont, bold: true),
                  _cell('التاريخ', arabicFont, englishFont, bold: true),
                ],
              ),
              ...jobs.map((job) {
                final customer = job['customer'] as Map<String, dynamic>?;
                final date = _formatDate(
                  job['completed_at'] as String? ??
                      job['rejected_at'] as String? ??
                      job['assigned_at'] as String?,
                );
                return pw.TableRow(
                  children: [
                    _cell(job['order_code'] as String? ?? '—', arabicFont, englishFont),
                    _cell(job['status_label'] as String? ?? '—', arabicFont, englishFont),
                    _cell(job['address'] as String? ?? '—', arabicFont, englishFont),
                    _cell(customer?['name'] as String? ?? '—', arabicFont, englishFont),
                    _cell(CurrencyFormatter.format((job['total'] as num?) ?? 0), arabicFont, englishFont),
                    _cell(date, arabicFont, englishFont),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  static String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return '—';
    return DateFormat('yyyy/MM/dd HH:mm').format(date);
  }

  static pw.Widget _cell(String text, pw.Font arabicFont, pw.Font englishFont, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: _mixedText(text, arabicFont, englishFont, fontSize: 9, bold: bold),
    );
  }

  static pw.Widget _mixedText(
    String text,
    pw.Font arabicFont,
    pw.Font englishFont, {
    double fontSize = 10,
    bool bold = false,
  }) {
    final spans = <pw.InlineSpan>[];
    var cursor = 0;

    while (cursor < text.length) {
      final rest = text.substring(cursor);
      final arabic = _arabicRun.firstMatch(rest);
      final latin = _latinRun.firstMatch(rest);

      Match? match;
      var useArabic = true;

      if (arabic == null && latin == null) {
        spans.add(pw.TextSpan(text: rest, style: pw.TextStyle(font: arabicFont, fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : null)));
        break;
      } else if (arabic == null) {
        match = latin;
        useArabic = false;
      } else if (latin == null) {
        match = arabic;
      } else if (arabic.start <= latin.start) {
        match = arabic;
      } else {
        match = latin;
        useArabic = false;
      }

      if (match!.start > 0) {
        spans.add(pw.TextSpan(text: rest.substring(0, match.start), style: pw.TextStyle(font: arabicFont, fontSize: fontSize)));
      }

      spans.add(
        pw.TextSpan(
          text: match.group(0),
          style: pw.TextStyle(
            font: useArabic ? arabicFont : englishFont,
            fontSize: fontSize,
            fontWeight: bold ? pw.FontWeight.bold : null,
          ),
        ),
      );
      cursor += match.end;
    }

    return pw.RichText(text: pw.TextSpan(children: spans));
  }
}
