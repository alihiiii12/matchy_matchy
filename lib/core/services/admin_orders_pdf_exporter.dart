import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:matchy_matchy/core/services/pdf_file_saver.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';

class AdminOrdersPdfExporter {
  AdminOrdersPdfExporter._();

  static final _latinRun = RegExp(r'[A-Za-z0-9@._+\-/\\,%:ZDK\-]+');
  static final _arabicRun = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]+',
  );

  static Future<String> exportAndSave(List<Map<String, dynamic>> orders) async {
    final bytes = await _buildPdfBytes(orders);
    return PdfFileSaver.saveArchivePdf(bytes, 'matchy-orders-archive');
  }

  static Future<Uint8List> _buildPdfBytes(List<Map<String, dynamic>> orders) async {
    final arabicFont = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'));
    final englishFont = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    final generatedAt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final totalRevenue = orders.fold<double>(0, (sum, o) => sum + ((o['total'] as num?)?.toDouble() ?? 0));

    final doc = pw.Document(
      title: 'matchy matchy Orders Archive',
      author: 'matchy matchy',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.symmetric(horizontal: 22, vertical: 26),
        theme: pw.ThemeData.withFont(base: englishFont, bold: englishFont),
        header: (context) => _buildHeader(
          arabicFont: arabicFont,
          englishFont: englishFont,
          generatedAt: generatedAt,
          totalOrders: orders.length,
          totalRevenue: totalRevenue,
        ),
        footer: (context) => _buildFooter(context, englishFont),
        build: (context) => [
          pw.SizedBox(height: 8),
          _buildTable(orders, arabicFont, englishFont),
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

  static String _itemsSummary(List<dynamic>? items) {
    if (items == null || items.isEmpty) return '—';
    return items
        .map((item) {
          final map = item as Map<String, dynamic>;
          final name = map['product_name'] as String? ?? '—';
          final qty = map['quantity'] as int? ?? 0;
          return '$name x$qty';
        })
        .join(' | ');
  }

  static pw.Widget _buildHeader({
    required pw.Font arabicFont,
    required pw.Font englishFont,
    required String generatedAt,
    required int totalOrders,
    required double totalRevenue,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
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
                      style: pw.TextStyle(
                        font: englishFont,
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF2E3192),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Orders Archive',
                      style: pw.TextStyle(font: englishFont, fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text(
                  'أرشيف الطلبات',
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFFA66B74),
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _mixedText(
                'Export: $generatedAt | تاريخ الأرشفة: $generatedAt',
                arabicFont,
                englishFont,
                fontSize: 9,
                color: PdfColors.grey700,
              ),
              _mixedText(
                'Orders: $totalOrders | الطلبات: $totalOrders',
                arabicFont,
                englishFont,
                fontSize: 9,
                color: PdfColors.grey700,
              ),
              _mixedText(
                'Total: ${CurrencyFormatter.format(totalRevenue)} | الإجمالي: ${CurrencyFormatter.format(totalRevenue)}',
                arabicFont,
                englishFont,
                fontSize: 10,
                color: PdfColor.fromInt(0xFF2E3192),
                bold: true,
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
        padding: const pw.EdgeInsets.only(top: 6),
        child: pw.Text(
          'Page ${context.pageNumber} / ${context.pagesCount}',
          style: pw.TextStyle(font: englishFont, fontSize: 9, color: PdfColors.grey600),
        ),
      ),
    );
  }

  static pw.Widget _buildTable(
    List<Map<String, dynamic>> orders,
    pw.Font arabicFont,
    pw.Font englishFont,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(20),
        1: const pw.FlexColumnWidth(1.0),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.0),
        4: const pw.FlexColumnWidth(1.0),
        5: const pw.FlexColumnWidth(0.9),
        6: const pw.FlexColumnWidth(0.8),
        7: const pw.FlexColumnWidth(1.0),
        8: const pw.FlexColumnWidth(1.4),
        9: const pw.FlexColumnWidth(1.0),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2E3192)),
          children: [
            _headerCellEnglish('#', englishFont),
            _headerCellBilingual('الطلب', 'Order', arabicFont, englishFont),
            _headerCellBilingual('الزبون', 'Customer', arabicFont, englishFont),
            _headerCellBilingual('الهاتف', 'Phone', arabicFont, englishFont),
            _headerCellBilingual('الحالة', 'Status', arabicFont, englishFont),
            _headerCellBilingual('الدفع', 'Payment', arabicFont, englishFont),
            _headerCellBilingual('الإجمالي', 'Total', arabicFont, englishFont),
            _headerCellBilingual('المحافظة', 'Gov.', arabicFont, englishFont),
            _headerCellBilingual('المنتجات', 'Items', arabicFont, englishFont),
            _headerCellBilingual('التاريخ', 'Date', arabicFont, englishFont),
          ],
        ),
        ...orders.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final order = entry.value;
          final bg = index.isEven ? PdfColors.grey100 : PdfColors.white;
          final customer = order['customer'] as Map<String, dynamic>?;

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              _bodyCellEnglish('$index', englishFont, align: pw.TextAlign.center),
              _bodyCellEnglish(order['order_code'] as String? ?? '—', englishFont, align: pw.TextAlign.center),
              _bodyCellMixed(customer?['name'] as String? ?? '—', arabicFont, englishFont),
              _bodyCellEnglish(customer?['phone'] as String? ?? '—', englishFont),
              _bodyCellMixed(order['status_label'] as String? ?? order['status'] as String? ?? '—', arabicFont, englishFont),
              _bodyCellMixed(order['payment_method_label'] as String? ?? '—', arabicFont, englishFont),
              _bodyCellMixed(CurrencyFormatter.format((order['total'] as num?)?.toDouble() ?? 0), arabicFont, englishFont, align: pw.TextAlign.center),
              _bodyCellMixed(order['governorate_name'] as String? ?? '—', arabicFont, englishFont),
              _bodyCellMixed(_itemsSummary(order['items'] as List<dynamic>?), arabicFont, englishFont, fontSize: 7.5),
              _bodyCellEnglish(_formatDate(order['created_at'] as String?), englishFont, fontSize: 7.5),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _headerCellEnglish(String text, pw.Font englishFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      child: pw.Directionality(
        textDirection: pw.TextDirection.ltr,
        child: pw.Text(
          text,
          style: pw.TextStyle(font: englishFont, fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  static pw.Widget _headerCellBilingual(String arabic, String english, pw.Font arabicFont, pw.Font englishFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(
              arabic,
              style: pw.TextStyle(font: arabicFont, fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 1),
          pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Text(
              english,
              style: pw.TextStyle(
                font: englishFont,
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFFE8F4FF),
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _bodyCellEnglish(
    String text,
    pw.Font englishFont, {
    pw.TextAlign align = pw.TextAlign.left,
    double fontSize = 8,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: pw.Directionality(
        textDirection: pw.TextDirection.ltr,
        child: pw.Text(
          text,
          style: pw.TextStyle(font: englishFont, fontSize: fontSize, color: PdfColors.grey900),
          textAlign: align,
        ),
      ),
    );
  }

  static pw.Widget _bodyCellMixed(
    String text,
    pw.Font arabicFont,
    pw.Font englishFont, {
    pw.TextAlign align = pw.TextAlign.left,
    double fontSize = 8,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: _mixedText(text, arabicFont, englishFont, fontSize: fontSize, align: align),
    );
  }

  static pw.Widget _mixedText(
    String text,
    pw.Font arabicFont,
    pw.Font englishFont, {
    double fontSize = 10,
    PdfColor color = PdfColors.grey900,
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    final spans = _buildSpans(text, arabicFont, englishFont, fontSize: fontSize, color: color, bold: bold);
    final hasArabic = _arabicRun.hasMatch(text);
    final direction = hasArabic && !_isMostlyLatin(text) ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    return pw.Directionality(
      textDirection: direction,
      child: pw.RichText(
        textAlign: align,
        text: pw.TextSpan(children: spans),
      ),
    );
  }

  static List<pw.TextSpan> _buildSpans(
    String text,
    pw.Font arabicFont,
    pw.Font englishFont, {
    required double fontSize,
    required PdfColor color,
    required bool bold,
  }) {
    if (text.isEmpty) {
      return [
        pw.TextSpan(
          text: '—',
          style: pw.TextStyle(
            font: englishFont,
            fontSize: fontSize,
            color: color,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ];
    }

    final spans = <pw.TextSpan>[];
    var index = 0;

    while (index < text.length) {
      final latinMatch = _latinRun.matchAsPrefix(text, index);
      final arabicMatch = _arabicRun.matchAsPrefix(text, index);

      if (latinMatch != null) {
        spans.add(
          pw.TextSpan(
            text: latinMatch.group(0),
            style: pw.TextStyle(
              font: englishFont,
              fontSize: fontSize,
              color: color,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        );
        index += latinMatch.end - latinMatch.start;
        continue;
      }

      if (arabicMatch != null) {
        spans.add(
          pw.TextSpan(
            text: arabicMatch.group(0),
            style: pw.TextStyle(
              font: arabicFont,
              fontSize: fontSize,
              color: color,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        );
        index += arabicMatch.end - arabicMatch.start;
        continue;
      }

      spans.add(
        pw.TextSpan(
          text: text[index],
          style: pw.TextStyle(
            font: englishFont,
            fontSize: fontSize,
            color: color,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
      index += 1;
    }

    return spans;
  }

  static bool _isMostlyLatin(String text) {
    if (text.isEmpty) return true;
    final latinChars = RegExp(r'[A-Za-z0-9@._+\-/\\ ,:%ZDK\-|x]');
    final matches = latinChars.allMatches(text).length;
    return matches >= text.length * 0.55;
  }
}
