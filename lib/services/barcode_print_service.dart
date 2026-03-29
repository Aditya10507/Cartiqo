import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/mall_product.dart';

class BarcodeLabelData {
  final String productName;
  final String barcode;
  final String brand;
  final String unit;
  final double price;

  const BarcodeLabelData({
    required this.productName,
    required this.barcode,
    required this.brand,
    required this.unit,
    required this.price,
  });

  factory BarcodeLabelData.fromProduct(MallProduct product) {
    return BarcodeLabelData(
      productName: product.name,
      barcode: product.barcode,
      brand: product.brand,
      unit: product.unit,
      price: product.price,
    );
  }
}

enum BarcodeLabelSize { compact, standard, detailed }

class BarcodePrintOptions {
  final BarcodeLabelSize size;
  final bool showPrice;
  final bool showBrand;
  final bool showUnit;

  const BarcodePrintOptions({
    this.size = BarcodeLabelSize.standard,
    this.showPrice = true,
    this.showBrand = true,
    this.showUnit = true,
  });
}

class BarcodePrintService {
  const BarcodePrintService._();

  static Future<void> printSingleLabel(
    BarcodeLabelData label, {
    BarcodePrintOptions options = const BarcodePrintOptions(),
  }) {
    return _printLabels(
      [label],
      jobName: 'Barcode_${label.barcode}',
      options: options,
    );
  }

  static Future<void> printLabelSheet(
    List<BarcodeLabelData> labels, {
    BarcodePrintOptions options = const BarcodePrintOptions(),
  }) {
    return _printLabels(
      labels,
      jobName: 'Barcode_Label_Sheet',
      options: options,
    );
  }

  static Future<void> _printLabels(
    List<BarcodeLabelData> labels, {
    required String jobName,
    required BarcodePrintOptions options,
  }) async {
    final filteredLabels = labels
        .where((label) => label.barcode.trim().isNotEmpty)
        .toList();
    if (filteredLabels.isEmpty) {
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
              children: filteredLabels
                  .map((label) => _buildLabelCard(label, options))
                  .toList(),
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

  static pw.Widget _buildLabelCard(
    BarcodeLabelData label,
    BarcodePrintOptions options,
  ) {
    final width = switch (options.size) {
      BarcodeLabelSize.compact => 210.0,
      BarcodeLabelSize.standard => 255.0,
      BarcodeLabelSize.detailed => 290.0,
    };

    final barcodeHeight = switch (options.size) {
      BarcodeLabelSize.compact => 56.0,
      BarcodeLabelSize.standard => 70.0,
      BarcodeLabelSize.detailed => 82.0,
    };

    final titleSize = switch (options.size) {
      BarcodeLabelSize.compact => 12.0,
      BarcodeLabelSize.standard => 14.0,
      BarcodeLabelSize.detailed => 15.0,
    };

    return pw.Container(
      width: width,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.productName,
            maxLines: options.size == BarcodeLabelSize.compact ? 1 : 2,
            style: pw.TextStyle(
              fontSize: titleSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (options.showBrand || options.showUnit) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              [
                if (options.showBrand) label.brand,
                if (options.showUnit) label.unit,
              ].where((item) => item.trim().isNotEmpty).join(' | '),
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
          pw.SizedBox(height: 10),
          if (_isPrintableBarcode(label.barcode))
            pw.Center(
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.ean13(),
                data: label.barcode,
                width: width - 70,
                height: barcodeHeight,
                drawText: false,
              ),
            )
          else
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 8,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Text(
                'Unsupported barcode format',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              _formatBarcodeForDisplay(label.barcode),
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
          if (options.showPrice) ...[
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'MRP',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  'Rs ${label.price.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static bool _isPrintableBarcode(String barcode) {
    return RegExp(r'^\d{13}$').hasMatch(barcode);
  }

  static String _formatBarcodeForDisplay(String barcode) {
    if (barcode.length != 13) {
      return barcode;
    }

    return '${barcode[0]} ${barcode.substring(1, 7)} ${barcode.substring(7)}';
  }
}
