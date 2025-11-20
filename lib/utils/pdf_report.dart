import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/receipt.dart';

class PdfReportInput {
  final String title;
  final DateTime rangeStart, rangeEnd;
  final List<Receipt> receipts;
  final Map<String, double> spendByCategory, spendByStore;
  final double grandTotal;

  PdfReportInput({
    required this.title,
    required this.rangeStart,
    required this.rangeEnd,
    required this.receipts,
    required this.spendByCategory,
    required this.spendByStore,
    required this.grandTotal,
  });
}

Future<Uint8List> generateSpendingReportPdf(PdfReportInput data) async {
  final pdf = pw.Document();
  final df = DateFormat('MMM dd, yyyy');
  final cf = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  // Colors & Styles
  const cP = PdfColor.fromInt(0xFF0F172A), cS = PdfColor.fromInt(0xFF334155);
  const cAcc = PdfColor.fromInt(0xFF10B981), bg = PdfColor.fromInt(0xFFF8FAFC);
  const border = PdfColor.fromInt(0xFFE2E8F0),
      txtD = PdfColor.fromInt(0xFF1E293B),
      txtL = PdfColor.fromInt(0xFF64748B);

  pw.TextStyle style(double s, [PdfColor? c, pw.FontWeight? w]) =>
      pw.TextStyle(color: c ?? txtD, fontSize: s, fontWeight: w);
  pw.BoxDecoration box({PdfColor? c, PdfColor? b, double r = 4}) =>
      pw.BoxDecoration(
        color: c,
        border: b != null ? pw.Border.all(color: b) : null,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(r)),
      );

  // Components

  pw.Widget header() => pw.Column(
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                data.title.toUpperCase(),
                style: style(10, cAcc, pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Expense Report',
                style: style(24, cP, pw.FontWeight.bold),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Generated on ${df.format(DateTime.now())}',
                style: style(10, txtL),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: box(c: bg, b: border),
                child: pw.Text(
                  '${df.format(data.rangeStart)} - ${df.format(data.rangeEnd)}',
                  style: style(10, cS, pw.FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Divider(color: cP, thickness: 2),
      pw.SizedBox(height: 20),
    ],
  );

  pw.Widget metric(String l, String v, [PdfColor? c]) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: box(c: PdfColors.white, b: border, r: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(l.toUpperCase(), style: style(9, txtL, pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text(v, style: style(18, c ?? txtD, pw.FontWeight.bold)),
        ],
      ),
    ),
  );

  pw.Widget table(
    List<String> head,
    List<List<dynamic>> rows,
    Map<int, pw.FlexColumnWidth> widths,
    Map<int, pw.Alignment> aligns,
  ) => pw.TableHelper.fromTextArray(
    headers: head,
    data: rows,
    border: null,
    headerStyle: style(10, txtL, pw.FontWeight.bold),
    headerDecoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: border, width: 1)),
    ),
    cellStyle: style(10, txtD),
    cellAlignments: aligns,
    cellPadding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
    rowDecoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: border, width: 0.5)),
    ),
    oddRowDecoration: const pw.BoxDecoration(color: bg),
  );

  pw.Widget catChart() {
    final list =
        (data.spendByCategory.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(6)
            .toList();
    final maxV = list.isNotEmpty ? list.first.value : 1.0;
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: box(c: bg, b: border, r: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Top Spending Categories',
            style: style(12, cS, pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          ...list.map(
            (e) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      e.key.isEmpty ? 'Other' : e.key,
                      style: style(10),
                      maxLines: 1,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    flex: 5,
                    child: pw.Stack(
                      children: [
                        pw.Container(
                          height: 6,
                          decoration: box(c: border, r: 3),
                        ),
                        pw.Container(
                          height: 6,
                          width: 180 * (e.value / maxV),
                          decoration: box(c: cAcc, r: 3),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      cf.format(e.value),
                      style: style(10, txtD, pw.FontWeight.bold),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => [
        header(),
        pw.Row(
          children: [
            metric('Total Spend', cf.format(data.grandTotal), cP),
            pw.SizedBox(width: 12),
            metric('Total Receipts', '${data.receipts.length}'),
            pw.SizedBox(width: 12),
            metric(
              'Avg. Per Receipt',
              cf.format(
                data.grandTotal /
                    (data.receipts.isEmpty ? 1 : data.receipts.length),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 24),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(flex: 3, child: catChart()),
            pw.SizedBox(width: 20),
            pw.Expanded(
              flex: 2,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Top Stores',
                    style: style(12, cS, pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  table(
                    ['Store', 'Total'],
                    data.spendByStore.entries
                        .take(8)
                        .map((e) => [e.key, cf.format(e.value)])
                        .toList(),
                    {
                      0: const pw.FlexColumnWidth(2),
                      1: const pw.FlexColumnWidth(1),
                    },
                    {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerRight},
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 30),
        pw.Text('Itemized Receipts', style: style(14, cP, pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        table(
          ['Date', 'Store', 'Category', 'Return By', 'Total'],
          data.receipts
              .map(
                (r) => [
                  df.format(r.date),
                  r.store,
                  r.category ?? '-',
                  r.returnBy != null ? df.format(r.returnBy!) : '-',
                  cf.format(r.total),
                ],
              )
              .toList(),
          {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(2),
          },
          {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerLeft,
            3: pw.Alignment.centerRight,
            4: pw.Alignment.centerRight,
          },
        ),
      ],
      footer: (ctx) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 20),
        padding: const pw.EdgeInsets.only(top: 10),
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: border, width: 1)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Confidential Financial Document', style: style(8, txtL)),
            pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: style(8, txtL),
            ),
          ],
        ),
      ),
    ),
  );
  return pdf.save();
}
