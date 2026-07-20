import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminUsersPdfExporter {
  AdminUsersPdfExporter._();

  static Future<void> export(List<Map<String, dynamic>> users) async {
    final arabicFont = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'));
    final englishFont = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    final generatedAt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    final doc = pw.Document(
      title: 'matchy matchy Registered Users',
      author: 'matchy matchy',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        theme: pw.ThemeData.withFont(base: englishFont, bold: englishFont),
        header: (context) => _buildHeader(arabicFont, englishFont, generatedAt, users.length),
        footer: (context) => _buildFooter(context, englishFont),
        build: (context) => [
          pw.SizedBox(height: 12),
          _buildTable(users, arabicFont, englishFont),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: 'matchy-users-$generatedAt.pdf',
      onLayout: (format) async => doc.save(),
    );
  }

  static bool _isMostlyLatin(String text) {
    if (text.isEmpty) return true;
    final latinChars = RegExp(r'[A-Za-z0-9@._+\-/\\ ]');
    final matches = latinChars.allMatches(text).length;
    return matches >= text.length * 0.6;
  }

  static pw.Widget _buildHeader(pw.Font arabicFont, pw.Font englishFont, String date, int count) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Directionality(
                textDirection: pw.TextDirection.ltr,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'matchy matchy',
                      style: pw.TextStyle(font: englishFont, fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF2E3192)),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Registered Users Report',
                      style: pw.TextStyle(font: englishFont, fontSize: 11, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text(
                  'تقرير الحسابات المسجلة',
                  style: pw.TextStyle(font: arabicFont, fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFFA66B74)),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text(
                  'تاريخ التصدير: $date',
                  style: pw.TextStyle(font: arabicFont, fontSize: 10, color: PdfColors.grey700),
                ),
              ),
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text(
                  'عدد الحسابات: $count',
                  style: pw.TextStyle(font: arabicFont, fontSize: 10, color: PdfColors.grey700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context, pw.Font englishFont) {
    return pw.Directionality(
      textDirection: pw.TextDirection.ltr,
      child: pw.Container(
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Text(
          'Page ${context.pageNumber} / ${context.pagesCount}',
          style: pw.TextStyle(font: englishFont, fontSize: 9, color: PdfColors.grey600),
        ),
      ),
    );
  }

  static pw.Widget _buildTable(List<Map<String, dynamic>> users, pw.Font arabicFont, pw.Font englishFont) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(28),
        1: const pw.FlexColumnWidth(2.2),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(2.3),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2E3192)),
          children: [
            _headerCellEnglish('#', englishFont),
            _headerCellBilingual('الاسم الكامل', 'Full Name', arabicFont, englishFont),
            _headerCellBilingual('رقم الهاتف', 'Phone', arabicFont, englishFont),
            _headerCellBilingual('البريد الإلكتروني', 'Email', arabicFont, englishFont),
          ],
        ),
        ...users.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final user = entry.value;
          final bg = index.isEven ? PdfColors.grey100 : PdfColors.white;
          final name = user['name'] as String? ?? '—';
          final phone = user['phone'] as String? ?? '—';
          final email = user['email'] as String? ?? '—';

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              _bodyCellEnglish('$index', englishFont, align: pw.TextAlign.center),
              _bodyCellAuto(name, arabicFont, englishFont),
              _bodyCellEnglish(phone, englishFont),
              _bodyCellEnglish(email, englishFont),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _headerCellEnglish(String text, pw.Font englishFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: pw.Directionality(
        textDirection: pw.TextDirection.ltr,
        child: pw.Text(
          text,
          style: pw.TextStyle(font: englishFont, fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  static pw.Widget _headerCellBilingual(String arabic, String english, pw.Font arabicFont, pw.Font englishFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(
              arabic,
              style: pw.TextStyle(font: arabicFont, fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Text(
              english,
              style: pw.TextStyle(font: englishFont, fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFFE8F4FF)),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _bodyCellEnglish(String text, pw.Font englishFont, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Directionality(
        textDirection: pw.TextDirection.ltr,
        child: pw.Text(
          text,
          style: pw.TextStyle(font: englishFont, fontSize: 9.5, color: PdfColors.grey900),
          textAlign: align,
        ),
      ),
    );
  }

  static pw.Widget _bodyCellAuto(String text, pw.Font arabicFont, pw.Font englishFont) {
    final font = _isMostlyLatin(text) ? englishFont : arabicFont;
    final direction = _isMostlyLatin(text) ? pw.TextDirection.ltr : pw.TextDirection.rtl;

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Directionality(
        textDirection: direction,
        child: pw.Text(
          text,
          style: pw.TextStyle(font: font, fontSize: 9.5, color: PdfColors.grey900),
          textAlign: direction == pw.TextDirection.ltr ? pw.TextAlign.left : pw.TextAlign.right,
        ),
      ),
    );
  }
}
