import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HistoryPrintService {
  const HistoryPrintService._();

  static Future<void> printBill({
    required Map<String, dynamic> bill,
    required String customerName,
  }) async {
    final document = pw.Document();
    final items = _normalizedItems(bill['items']);
    final subtotal = _asNum(bill['subtotal']) ?? _sumLineTotals(items);
    final extraCharge = _asNum(bill['extraCharge']) ?? _asNum(bill['handlingFee']) ?? 0;
    final extraChargeLabel =
        (bill['extraChargeLabel'] ?? 'Extra Charges').toString();
    final gst = _asNum(bill['gst']) ?? 0;
    final gstPercent = _asNum(bill['gstPercent']) ?? 0;
    final otherTax = _asNum(bill['otherTax']) ?? 0;
    final otherTaxLabel = (bill['otherTaxLabel'] ?? 'Tax').toString();
    final otherTaxPercent = _asNum(bill['otherTaxPercent']) ?? 0;
    final total = _asNum(bill['total']) ?? (subtotal + extraCharge + gst + otherTax);

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'Cartiqo Mart Bill',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Bill No: ${(bill['billNumber'] ?? bill['billId'] ?? '').toString()}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.Center(
              child: pw.Text(
                'Mall ID: ${(bill['mallId'] ?? '').toString()}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.SizedBox(height: 8),
            _metaRow('Customer', customerName),
            _metaRow('Date', _formatDateTime(bill['createdAt'])),
            _metaRow('Status', (bill['status'] ?? 'paid').toString().toUpperCase()),
            pw.Divider(),
            ...items.map((item) => _billItemRow(item)),
            pw.Divider(),
            _amountRow('Subtotal', subtotal),
            if (extraCharge > 0) _amountRow(extraChargeLabel, extraCharge),
            if (gst > 0)
              _amountRow(
                'GST (${gstPercent.toStringAsFixed(1)}%)',
                gst,
              ),
            if (otherTax > 0)
              _amountRow(
                '$otherTaxLabel (${otherTaxPercent.toStringAsFixed(1)}%)',
                otherTax,
              ),
            pw.Divider(),
            _amountRow('Grand Total', total, emphasis: true),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'Thank you for shopping with Cartiqo',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      name: 'Bill_${(bill['billNumber'] ?? bill['billId'] ?? 'receipt').toString()}',
      onLayout: (format) async => document.save(),
    );
  }

  static Future<void> printPayment({
    required Map<String, dynamic> payment,
    required String customerName,
  }) async {
    final document = pw.Document();
    final amount = _asNum(payment['amount']) ?? 0;

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        margin: const pw.EdgeInsets.all(18),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                border: pw.Border.all(color: PdfColors.green300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Payment Successful',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Rs ${amount.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    customerName,
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            _metaRow(
              'Transaction ID',
              (payment['paymentNumber'] ?? payment['paymentId'] ?? '').toString(),
            ),
            _metaRow('Bill Number', (payment['billNumber'] ?? '').toString()),
            _metaRow('Mall ID', (payment['mallId'] ?? '').toString()),
            _metaRow('Method', (payment['method'] ?? '').toString()),
            if ((_asNum(payment['gst']) ?? 0) > 0)
              _metaRow(
                'GST',
                'Rs ${(_asNum(payment['gst']) ?? 0).toStringAsFixed(2)}',
              ),
            if ((_asNum(payment['otherTax']) ?? 0) > 0)
              _metaRow(
                (payment['otherTaxLabel'] ?? 'Tax').toString(),
                'Rs ${(_asNum(payment['otherTax']) ?? 0).toStringAsFixed(2)}',
              ),
            _metaRow(
              'Reference',
              (payment['reference'] ?? 'Not available').toString(),
            ),
            _metaRow('Status', (payment['status'] ?? 'success').toString()),
            _metaRow('Date', _formatDateTime(payment['createdAt'])),
            pw.Spacer(),
            pw.Center(
              child: pw.Text(
                'Cartiqo Payment Receipt',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      name: 'Payment_${(payment['paymentNumber'] ?? payment['paymentId'] ?? 'receipt').toString()}',
      onLayout: (format) async => document.save(),
    );
  }

  static List<Map<String, dynamic>> _normalizedItems(dynamic rawItems) {
    final items = rawItems as List<dynamic>? ?? <dynamic>[];
    return items
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  static double _sumLineTotals(List<Map<String, dynamic>> items) {
    return items.fold<double>(
      0,
      (sum, item) => sum + (_asNum(item['lineTotal']) ?? 0),
    );
  }

  static double? _asNum(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  static pw.Widget _billItemRow(Map<String, dynamic> item) {
    final name = (item['name'] ?? 'Item').toString();
    final qty = (item['qty'] ?? 1).toString();
    final price = (_asNum(item['price']) ?? 0).toStringAsFixed(2);
    final total = (_asNum(item['lineTotal']) ?? 0).toStringAsFixed(2);

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            name,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Qty $qty x Rs $price', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Rs $total', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _metaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _amountRow(String label, double value, {bool emphasis = false}) {
    final style = pw.TextStyle(
      fontSize: emphasis ? 12 : 10,
      fontWeight: emphasis ? pw.FontWeight.bold : pw.FontWeight.normal,
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text('Rs ${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }

  static String _formatDateTime(dynamic value) {
    if (value == null) {
      return 'Unknown';
    }
    final dateTime = value is DateTime
        ? value
        : value.runtimeType.toString() == 'Timestamp'
            ? (value as dynamic).toDate() as DateTime
            : DateTime.tryParse(value.toString());

    if (dateTime == null) {
      return 'Unknown';
    }

    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
