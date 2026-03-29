import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/mall_subscription.dart';

class MallQrLabelData {
  final String mallName;
  final String mallId;
  final String city;
  final String state;

  const MallQrLabelData({
    required this.mallName,
    required this.mallId,
    required this.city,
    required this.state,
  });

  factory MallQrLabelData.fromMall(MallSubscription mall) {
    return MallQrLabelData(
      mallName: mall.name,
      mallId: mall.mallId,
      city: mall.city ?? 'Unknown City',
      state: mall.state ?? 'Unknown State',
    );
  }
}

class MallQrPrintService {
  const MallQrPrintService._();

  static Future<void> printSingleLabel(MallQrLabelData label) {
    return _printLabels([label], jobName: 'Mall_QR_${label.mallId}');
  }

  static Future<void> printLabelSheet(List<MallQrLabelData> labels) {
    return _printLabels(labels, jobName: 'Mall_QR_Sheet');
  }

  static Future<void> _printLabels(
    List<MallQrLabelData> labels, {
    required String jobName,
  }) async {
    if (labels.isEmpty) {
      return;
    }

    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return [
            pw.Wrap(
              spacing: 12,
              runSpacing: 12,
              children: labels.map(_buildLabelCard).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      name: jobName,
      onLayout: (format) async => document.save(),
    );
  }

  static pw.Widget _buildLabelCard(MallQrLabelData label) {
    return pw.Container(
      width: 255,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.mallName,
            maxLines: 2,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${label.city}, ${label.state}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: label.mallId,
              width: 110,
              height: 110,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              label.mallId,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              'Scan to open mall',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );
  }
}
