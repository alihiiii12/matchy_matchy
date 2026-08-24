import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';

class AdminSalesPdfExporter {
  AdminSalesPdfExporter._();

  static final _latinRun = RegExp(r'[A-Za-z0-9@._+\-/\\,%:]+');
  static final _arabicRun = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]+',
  );

  static Future<void> export({
    required List<Map<String, dynamic>> sales,
    required int totalLines,
    required double totalRevenue,
  }) async {
    final arabicFont = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'));
    final englishFont = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    final generatedAt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    final doc = pw.Document(
      title: 'rozetaj Sales Report',
      author: 'rozetaj',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        theme: pw.ThemeData.withFont(base: englishFont, bold: englishFont),
        header: (context) => _buildHeader(
          arabicFont: arabicFont,
          englishFont: englishFont,
          generatedAt: generatedAt,
          totalLines: totalLines,
          totalRevenue: totalRevenue,
        ),
        footer: (context) => _buildFooter(context, englishFont),
        build: (context) => [
          pw.SizedBox(height: 10),
          _buildTable(sales, arabicFont, englishFont),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: 'matchy-sales-$generatedAt.pdf',
      onLayout: (format) async => doc.save(),
    );
  }

  static String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return '—';
    return DateFormat('yyyy/MM/dd').format(date);
  }

  static pw.Widget _buildHeader({
    required pw.Font arabicFont,
    required pw.Font englishFont,
    required String generatedAt,
    required int totalLines,
    required double totalRevenue,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 14),
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
                      'rozetaj',
                      style: pw.TextStyle(
                        font: englishFont,
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF2E3192),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Sales Report',
                      style: pw.TextStyle(font: englishFont, fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text(
                  'تقرير المبيعات',
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
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _mixedText(
                'Export date: $generatedAt | تاريخ التصدير: $generatedAt',
                arabicFont,
                englishFont,
                fontSize: 10,
                color: PdfColors.grey700,
              ),
              _mixedText(
                'Items: $totalLines | ${AppStrings.totalSoldItems}: $totalLines',
                arabicFont,
                englishFont,
                fontSize: 10,
                color: PdfColors.grey700,
              ),
              _mixedText(
                'Revenue: ${CurrencyFormatter.format(totalRevenue)} | ${AppStrings.totalSalesRevenue}: ${CurrencyFormatter.format(totalRevenue)}',
                arabicFont,
                englishFont,
                fontSize: 11,
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
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Text(
          'Page ${context.pageNumber} / ${context.pagesCount}',
          style: pw.TextStyle(font: englishFont, fontSize: 9, color: PdfColors.grey600),
        ),
      ),
    );
  }

  static pw.Widget _buildTable(
    List<Map<String, dynamic>> sales,
    pw.Font arabicFont,
    pw.Font englishFont,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(22),
        1: const pw.FlexColumnWidth(2.0),
        2: const pw.FlexColumnWidth(1.3),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.2),
        5: const pw.FlexColumnWidth(0.8),
        6: const pw.FlexColumnWidth(1.0),
        7: const pw.FlexColumnWidth(1.0),
        8: const pw.FlexColumnWidth(0.9),
        9: const pw.FlexColumnWidth(0.9),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2E3192)),
          children: [
            _headerCellEnglish('#', englishFont),
            _headerCellBilingual('المنتج', 'Product', arabicFont, englishFont),
            _headerCellBilingual('الماركة', 'Brand', arabicFont, englishFont),
            _headerCellBilingual('البائع', 'Seller', arabicFont, englishFont),
            _headerCellBilingual('الزبون', 'Customer', arabicFont, englishFont),
            _headerCellBilingual('الكمية', 'Qty', arabicFont, englishFont),
            _headerCellBilingual('السعر', 'Price', arabicFont, englishFont),
            _headerCellBilingual('الإجمالي', 'Total', arabicFont, englishFont),
            _headerCellBilingual('الطلب', 'Order', arabicFont, englishFont),
            _headerCellBilingual('التاريخ', 'Date', arabicFont, englishFont),
          ],
        ),
        ...sales.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final sale = entry.value;
          final bg = index.isEven ? PdfColors.grey100 : PdfColors.white;

          final productName = sale['product_name'] as String? ?? '—';
          final brand = sale['product_brand'] as String? ?? '—';
          final sellerName = sale['seller_name'] as String? ?? AppStrings.unknownSeller;
          final customer = sale['customer'] as Map<String, dynamic>?;
          final customerName = customer?['name'] as String? ?? '—';
          final quantity = sale['quantity'] as int? ?? 0;
          final unitPrice = (sale['unit_price'] as num?)?.toDouble() ?? 0;
          final lineTotal = (sale['line_total'] as num?)?.toDouble() ?? 0;
          final orderCode = sale['order_code'] as String? ?? '—';
          final soldAt = _formatDate(sale['sold_at'] as String?);

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              _bodyCellEnglish('$index', englishFont, align: pw.TextAlign.center),
              _bodyCellMixed(productName, arabicFont, englishFont),
              _bodyCellMixed(brand, arabicFont, englishFont),
              _bodyCellMixed(sellerName, arabicFont, englishFont),
              _bodyCellMixed(customerName, arabicFont, englishFont),
              _bodyCellEnglish('$quantity', englishFont, align: pw.TextAlign.center),
              _bodyCellMixed(CurrencyFormatter.format(unitPrice), arabicFont, englishFont, align: pw.TextAlign.center),
              _bodyCellMixed(CurrencyFormatter.format(lineTotal), arabicFont, englishFont, align: pw.TextAlign.center),
              _bodyCellEnglish(orderCode, englishFont, align: pw.TextAlign.center),
              _bodyCellEnglish(soldAt, englishFont, align: pw.TextAlign.center),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _headerCellEnglish(String text, pw.Font englishFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Directionality(
        textDirection: pw.TextDirection.ltr,
        child: pw.Text(
          text,
          style: pw.TextStyle(font: englishFont, fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  static pw.Widget _headerCellBilingual(String arabic, String english, pw.Font arabicFont, pw.Font englishFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(
              arabic,
              style: pw.TextStyle(font: arabicFont, fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Text(
              english,
              style: pw.TextStyle(
                font: englishFont,
                fontSize: 8,
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

  static pw.Widget _bodyCellEnglish(String text, pw.Font englishFont, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Directionality(
        textDirection: pw.TextDirection.ltr,
        child: pw.Text(
          text,
          style: pw.TextStyle(font: englishFont, fontSize: 8.5, color: PdfColors.grey900),
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
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: _mixedText(text, arabicFont, englishFont, fontSize: 8.5, align: align),
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
          style: pw.TextStyle(font: englishFont, fontSize: fontSize, color: color, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
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
    final latinChars = RegExp(r'[A-Za-z0-9@._+\-/\\ ,:%]');
    final matches = latinChars.allMatches(text).length;
    return matches >= text.length * 0.6;
  }
}
