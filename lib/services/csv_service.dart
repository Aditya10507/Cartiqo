import 'dart:math' as math;

import 'package:csv/csv.dart';
import '../models/mall_product.dart';
import '../models/mall_subscription.dart';

class CsvService {
  /// Export products to CSV format
  static String exportProductsToCsv(List<MallProduct> products) {
    List<List<dynamic>> rows = [
      [
        'Product Name',
        'Barcode',
        'Price',
        'Unit',
        'Brand',
        'Category',
        'Stock',
        'Weight',
        'Weight Unit',
        'In Stock',
        'Image URL',
        'Image Source Page',
      ],
    ];

    for (var product in products) {
      rows.add([
        product.name,
        product.barcode,
        product.price.toString(),
        product.unit,
        product.brand,
        product.category,
        product.stock.toString(),
        product.weight.toString(),
        product.weightUnit,
        product.inStock ? 'Yes' : 'No',
        product.imageUrl,
        product.imageSourcePage,
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    return csv;
  }

  static String exportMallSubscriptionsToCsv(
    List<MallSubscription> malls,
    Map<String, int> managerCounts,
  ) {
    final rows = <List<dynamic>>[
      [
        'Mall Name',
        'Mall ID',
        'Owner Name',
        'Owner Email',
        'City',
        'State',
        'Plan',
        'Max Products',
        'Active',
        'Subscription Start',
        'Subscription End',
        'Expired',
        'Days Until Expiry',
        'Manager Count',
      ],
    ];

    for (final mall in malls) {
      rows.add([
        mall.name,
        mall.mallId,
        mall.ownerName ?? '',
        mall.ownerEmail ?? '',
        mall.city ?? '',
        mall.state ?? '',
        mall.planType,
        mall.maxProducts,
        mall.isActive ? 'Yes' : 'No',
        _formatDateForCsv(mall.subscriptionStartDate),
        _formatDateForCsv(mall.subscriptionEndDate),
        mall.isExpired ? 'Yes' : 'No',
        mall.daysUntilExpiry,
        managerCounts[mall.mallId] ?? 0,
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  static String exportSalesDashboardToCsv({
    required Map<String, String> summary,
    required String groupByLabel,
    required List<Map<String, dynamic>> groupedRows,
    required List<Map<String, dynamic>> paymentRows,
  }) {
    final rows = <List<dynamic>>[
      ['Sales Summary'],
      ['Metric', 'Value'],
      ...summary.entries.map((entry) => [entry.key, entry.value]),
      [],
      ['Consolidated Analysis'],
      [
        'Period',
        'Orders',
        'Sales Amount',
        'Average Order Value',
        'Cash',
        'Card',
        'UPI',
        'Other',
      ],
      ...groupedRows.map(
        (row) => [
          row['label'] ?? '',
          row['orders'] ?? 0,
          row['sales'] ?? 0,
          row['averageOrderValue'] ?? 0,
          row['cashSales'] ?? 0,
          row['cardSales'] ?? 0,
          row['upiSales'] ?? 0,
          row['otherSales'] ?? 0,
        ],
      ),
      [],
      ['Filtered Payments ($groupByLabel view source)'],
      [
        'Created At',
        'Payment Number',
        'Bill Number',
        'Customer',
        'Method',
        'Status',
        'Amount',
      ],
      ...paymentRows.map(
        (row) => [
          row['createdAt'] ?? '',
          row['paymentNumber'] ?? '',
          row['billNumber'] ?? '',
          row['customerName'] ?? '',
          row['method'] ?? '',
          row['status'] ?? '',
          row['amount'] ?? 0,
        ],
      ),
    ];

    return const ListToCsvConverter().convert(rows);
  }

  static String _formatDateForCsv(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// Parse CSV content and return list of products with validation
  static CsvImportResult parseProductsFromCsv(String csvContent) {
    try {
      List<List<dynamic>> rows = const CsvToListConverter().convert(csvContent);

      if (rows.isEmpty) {
        return CsvImportResult(
          success: false,
          message: 'CSV file is empty',
          products: [],
          errors: [],
        );
      }

      // Validate header. Barcode is optional: if it is missing or blank we will
      // auto-generate barcodes during import in the manager portal.
      List<dynamic> header = rows[0];
      List<String> expectedHeaders = [
        'Product Name',
        'Barcode',
        'Price',
        'Unit',
        'Brand',
        'Category',
        'Stock',
        'Weight',
        'Weight Unit',
        'In Stock',
        'Image URL',
        'Image Source Page',
      ];

      const requiredHeaders = <String>[
        'Product Name',
        'Price',
      ];

      Map<String, int> headerIndex = {};
      for (int i = 0; i < header.length; i++) {
        String headerValue = header[i].toString().trim();
        // Find matching index (case-insensitive)
        for (String expected in expectedHeaders) {
          if (expected.toLowerCase() == headerValue.toLowerCase()) {
            headerIndex[expected] = i;
            break;
          }
        }
      }

      final missingRequired = requiredHeaders
          .where((required) => !headerIndex.containsKey(required))
          .toList();
      if (missingRequired.isNotEmpty) {
        return CsvImportResult(
          success: false,
          message: 'Invalid CSV header. Missing required columns: ${missingRequired.join(", ")}',
          products: [],
          errors: [
            'Header validation failed. Ensure required columns are present.',
          ],
        );
      }

      List<MallProduct> products = [];
      List<String> errors = [];
      final barcodesSeen = <String>{};

      // Parse data rows
      for (int i = 1; i < rows.length; i++) {
        List<dynamic> row = rows[i];

        // Skip empty rows
        if (row.isEmpty ||
            row.every((cell) => cell.toString().trim().isEmpty)) {
          continue;
        }

        try {
          String name = _getCell(
            row,
            headerIndex,
            'Product Name',
            '',
          ).toString().trim();
          String barcode = _getCell(
            row,
            headerIndex,
            'Barcode',
            '',
          ).toString().trim();
          String priceStr = _getCell(
            row,
            headerIndex,
            'Price',
            '0',
          ).toString().trim();
          String unit = _getCell(
            row,
            headerIndex,
            'Unit',
            '1 pc',
          ).toString().trim();
          String brand = _getCell(
            row,
            headerIndex,
            'Brand',
            'General',
          ).toString().trim();
          String category = _getCell(
            row,
            headerIndex,
            'Category',
            'General',
          ).toString().trim();
          String stockStr = _getCell(
            row,
            headerIndex,
            'Stock',
            '0',
          ).toString().trim();
          String weightStr = _getCell(
            row,
            headerIndex,
            'Weight',
            '0',
          ).toString().trim();
          String weightUnit = _getCell(
            row,
            headerIndex,
            'Weight Unit',
            'g',
          ).toString().trim();
          String inStockStr = _getCell(
            row,
            headerIndex,
            'In Stock',
            'Yes',
          ).toString().trim();
          String imageUrl = _getCell(
            row,
            headerIndex,
            'Image URL',
            '',
          ).toString().trim();
          String imageSourcePage = _getCell(
            row,
            headerIndex,
            'Image Source Page',
            '',
          ).toString().trim();

          // Validation
          List<String> rowErrors = [];

          if (name.isEmpty) {
            rowErrors.add('Row ${i + 1}: Product Name is required');
          }

          if (barcode.isNotEmpty) {
            if (barcodesSeen.contains(barcode)) {
              rowErrors.add('Row ${i + 1}: Duplicate barcode "$barcode" in CSV');
            } else {
              barcodesSeen.add(barcode);
            }
          }

          double price = 0;
          try {
            price = double.parse(priceStr);
            if (price < 0) {
              rowErrors.add('Row ${i + 1}: Price cannot be negative');
            }
          } catch (e) {
            rowErrors.add('Row ${i + 1}: Invalid price format: "$priceStr"');
          }

          int stock = 0;
          try {
            stock = int.parse(stockStr);
            if (stock < 0) {
              rowErrors.add('Row ${i + 1}: Stock cannot be negative');
            }
          } catch (e) {
            rowErrors.add('Row ${i + 1}: Invalid stock format: "$stockStr"');
          }

          double weight = 0;
          try {
            weight = double.parse(weightStr);
            if (weight < 0) {
              rowErrors.add('Row ${i + 1}: Weight cannot be negative');
            }
          } catch (e) {
            rowErrors.add('Row ${i + 1}: Invalid weight format: "$weightStr"');
          }

          bool inStock =
              inStockStr.toLowerCase() == 'yes' ||
              inStockStr.toLowerCase() == 'true' ||
              inStockStr == '1';

          if (rowErrors.isNotEmpty) {
            errors.addAll(rowErrors);
            continue;
          }

          // Create product
          MallProduct product = MallProduct(
            productId: _generateProductId(),
            name: name,
            barcode: barcode,
            imageUrl: imageUrl,
            imageSourcePage: imageSourcePage,
            price: price,
            unit: unit.isEmpty ? '1 pc' : unit,
            brand: brand.isEmpty ? 'General' : brand,
            category: category.isEmpty ? 'General' : category,
            stock: stock,
            weight: weight,
            weightUnit: weightUnit.isEmpty ? 'g' : weightUnit,
            inStock: inStock,
          );

          products.add(product);
        } catch (e) {
          errors.add('Row ${i + 1}: Error parsing row - ${e.toString()}');
        }
      }

      if (products.isEmpty && errors.isEmpty) {
        return CsvImportResult(
          success: false,
          message: 'No valid products found in CSV',
          products: [],
          errors: [
            'Please check your CSV format and ensure data rows are present.',
          ],
        );
      }

      return CsvImportResult(
        success: errors.isEmpty,
        message: errors.isEmpty
            ? 'Successfully parsed ${products.length} products'
            : '${products.length} products parsed with ${errors.length} error(s)',
        products: products,
        errors: errors,
      );
    } catch (e) {
      return CsvImportResult(
        success: false,
        message: 'Error parsing CSV: ${e.toString()}',
        products: [],
        errors: ['Fatal error: ${e.toString()}'],
      );
    }
  }

  /// Helper to get cell value safely
  static dynamic _getCell(
    List<dynamic> row,
    Map<String, int> headerIndex,
    String columnName,
    dynamic defaultValue,
  ) {
    int? index = headerIndex[columnName];
    if (index == null || index >= row.length) {
      return defaultValue;
    }
    dynamic value = row[index];
    if (value == null || value.toString().trim().isEmpty) {
      return defaultValue;
    }
    return value;
  }

  /// Generate unique product ID
  static String _generateProductId() {
    // IMPORTANT:
    // On Flutter web, DateTime.now() effectively has millisecond precision.
    // When parsing a big CSV, multiple rows can land on the same millisecond
    // which causes productId collisions. Firestore then overwrites documents,
    // and after re-login you "lose" products (only the last few remain).
    //
    // Add a sequence + random suffix to guarantee uniqueness.
    final now = DateTime.now().millisecondsSinceEpoch;
    _productSeq = (_productSeq + 1) % 1000000;
    final rand = _productRand.nextInt(1 << 20); // 0..~1M
    return 'PROD_${now}_${_productSeq.toString().padLeft(6, '0')}_${rand.toRadixString(16).padLeft(5, '0')}';
  }
}

// File-level state for product id uniqueness during imports.
int _productSeq = 0;
final math.Random _productRand = math.Random();

class CsvImportResult {
  final bool success;
  final String message;
  final List<MallProduct> products;
  final List<String> errors;

  CsvImportResult({
    required this.success,
    required this.message,
    required this.products,
    required this.errors,
  });
}
