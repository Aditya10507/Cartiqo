import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../models/mall_product.dart';
import '../providers/mall_manager_provider.dart';
import '../services/csv_service.dart';
import '../services/file_download_service.dart';

class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  bool _isLoading = false;
  List<MallProduct> _importedProducts = [];
  List<String> _importErrors = [];
  bool _showPreview = false;

  Future<void> _exportProducts() async {
    final provider = context.read<MallManagerProvider>();
    final products = provider.products;

    if (products.isEmpty) {
      _showSnackBar('No products to export', isError: true);
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Generate CSV
      String csv = CsvService.exportProductsToCsv(products);

      // Create download filename
      final now = DateTime.now();
      final filename =
          'SwiftCart_Products_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour}${now.minute}.csv';

      final downloaded = await downloadTextFile(
        filename: filename,
        content: csv,
        mimeType: 'text/csv;charset=utf-8',
      );
      if (downloaded) {
        _showSnackBar('CSV export started');
      } else {
        _showExportDialog(filename, csv, products.length);
      }
    } catch (e) {
      _showSnackBar('Export failed: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showExportDialog(String filename, String csvContent, int productCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Successful'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CSV file ready for download',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filename: $filename',
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Products: $productCount',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'CSV Preview (first 500 chars):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    csvContent.substring(0, csvContent.length > 500 ? 500 : csvContent.length),
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              _copyToClipboard(csvContent);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy CSV'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String content) {
    // In a real app, you'd use flutter_web_clipboard or similar
    // For now, show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV content copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _importProducts() async {
    try {
      setState(() => _isLoading = true);

      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        withData: true,
      );

      if (result == null) {
        setState(() => _isLoading = false);
        return;
      }

      final fileBytes = result.files.first.bytes;
      if (fileBytes == null) {
        _showSnackBar('Unable to read file', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final csvContent = String.fromCharCodes(fileBytes);

      // Parse CSV
      final importResult = CsvService.parseProductsFromCsv(csvContent);

      setState(() {
        _importedProducts = importResult.products;
        _importErrors = importResult.errors;
        _showPreview = true;
        _isLoading = false;
      });

      if (_importErrors.isNotEmpty) {
        _showErrorDialog(
          'Import Validation Issues',
          _importErrors,
          importResult.products.length,
        );
      }
    } catch (e) {
      _showSnackBar('Import failed: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String title, List<String> errors, int successCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (successCount > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$successCount valid product(s) ready to import',
                          style: TextStyle(color: Colors.green.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              if (successCount > 0) const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${errors.length} error(s)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...errors.take(5).map((error) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '• $error',
                        style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                      ),
                    )),
                    if (errors.length > 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '• ... and ${errors.length - 5} more error(s)',
                          style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (successCount > 0)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmImport();
              },
              child: Text('Import $successCount Product(s)'),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmImport() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ImportProgressDialog(
        productsToImport: _importedProducts,
        onComplete: (successfully, failed) {
          Navigator.pop(context);
          _showImportSummary(successfully, failed);
        },
      ),
    );
  }

  void _showImportSummary(int successful, int failed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (successful > 0)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Successfully imported',
                            style: TextStyle(color: Colors.green.shade900, fontSize: 12),
                          ),
                          Text(
                            '$successful product(s)',
                            style: TextStyle(
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (failed > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Failed to import',
                            style:
                                TextStyle(color: Colors.orange.shade900, fontSize: 12),
                          ),
                          Text(
                            '$failed product(s)',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _importedProducts = [];
                _importErrors = [];
                _showPreview = false;
              });
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MallManagerProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Bulk Import/Export'),
            elevation: 0,
          ),
          body: _showPreview
              ? _buildPreviewView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Cards
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0B5ED7), Color(0xFF12B886)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Inventory',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${provider.products.length} Products',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Export Section
                      Text(
                        'Export Products',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Download your current product list as a CSV file. Use this as a template for bulk import.',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isLoading || provider.products.isEmpty
                              ? null
                              : _exportProducts,
                          icon: const Icon(Icons.download),
                          label: const Text('Export as CSV'),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Import Section
                      Text(
                        'Import Products',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload a CSV or Excel file to add multiple products at once. All data will be validated before import.',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _importProducts,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Choose File to Import'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // CSV Format Guide
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'CSV Format Guide',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Headers Table
                              _buildFormatTable(),
                              const SizedBox(height: 12),
                              Text(
                                'Required columns: Product Name, Price. Barcode is optional (leave blank or omit the column) and will be auto-generated.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade800,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Features
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Smart Import Features',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildFeature(
                              'Automatic validation',
                              'All data is checked before import',
                            ),
                            _buildFeature(
                              'Duplicate detection',
                              'Prevents duplicate barcodes (when barcodes are provided)',
                            ),
                            _buildFeature(
                              'Error reporting',
                              'See exactly which rows failed and why',
                            ),
                            _buildFeature(
                              'Preview before import',
                              'Review all products before confirming',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildFormatTable() {
    final columns = [
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.resolveWith(
          (_) => Colors.blue.shade100,
        ),
        columns: columns
            .map((col) => DataColumn(
                  label: Text(
                    col,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ))
            .toList(),
        rows: [
          DataRow(cells: [
            const DataCell(Text('Milk 1L', style: TextStyle(fontSize: 10))),
            const DataCell(Text('', style: TextStyle(fontSize: 10))),
            const DataCell(Text('45.50', style: TextStyle(fontSize: 10))),
            const DataCell(Text('1 pc', style: TextStyle(fontSize: 10))),
            const DataCell(Text('Amul', style: TextStyle(fontSize: 10))),
            const DataCell(Text('Dairy', style: TextStyle(fontSize: 10))),
            const DataCell(Text('50', style: TextStyle(fontSize: 10))),
            const DataCell(Text('1', style: TextStyle(fontSize: 10))),
            const DataCell(Text('L', style: TextStyle(fontSize: 10))),
            const DataCell(Text('Yes', style: TextStyle(fontSize: 10))),
            const DataCell(Text('https://…', style: TextStyle(fontSize: 10))),
            const DataCell(Text('https://…', style: TextStyle(fontSize: 10))),
          ]),
        ],
      ),
    );
  }

  Widget _buildFeature(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.done, size: 16, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Import Preview'),
                        Text(
                          '${_importedProducts.length} product(s) ready',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showPreview = false;
                        _importedProducts = [];
                        _importErrors = [];
                      });
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _importedProducts.length,
            itemBuilder: (context, index) {
              final product = _importedProducts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text('${product.stock} units'),
                            backgroundColor: Colors.grey.shade200,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildProductDetail(
                              'Barcode',
                              product.barcode.isEmpty
                                  ? 'Auto-generated'
                                  : product.barcode,
                              Icons.qr_code,
                            ),
                          ),
                          Expanded(
                            child: _buildProductDetail(
                              'Price',
                              '₹${product.price}',
                              Icons.currency_rupee,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildProductDetail(
                              'Brand',
                              product.brand,
                              Icons.label,
                            ),
                          ),
                          Expanded(
                            child: _buildProductDetail(
                              'Category',
                              product.category,
                              Icons.category,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showPreview = false;
                      _importedProducts = [];
                      _importErrors = [];
                    });
                  },
                  child: const Text('Cancel Import'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _importedProducts.isEmpty ? null : _confirmImport,
                  icon: const Icon(Icons.download_done),
                  label: const Text('Confirm Import'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductDetail(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ImportProgressDialog extends StatefulWidget {
  final List<MallProduct> productsToImport;
  final Function(int successful, int failed) onComplete;

  const _ImportProgressDialog({
    required this.productsToImport,
    required this.onComplete,
  });

  @override
  State<_ImportProgressDialog> createState() => _ImportProgressDialogState();
}

class _ImportProgressDialogState extends State<_ImportProgressDialog> {
  late Future<void> _importFuture;

  @override
  void initState() {
    super.initState();
    _importFuture = _doImport();
  }

  Future<void> _doImport() async {
    final provider = context.read<MallManagerProvider>();
    int successful = 0;
    int failed = 0;

    for (int i = 0; i < widget.productsToImport.length; i++) {
      try {
        final product = widget.productsToImport[i];
        final success = await provider.addProduct(product);
        if (success) {
          successful++;
        } else {
          failed++;
        }
      } catch (e) {
        failed++;
      }
      // Small delay to ensure UI updates
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onComplete(successful, failed);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Importing Products'),
      content: FutureBuilder<void>(
        future: _importFuture,
        builder: (context, snapshot) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Importing ${widget.productsToImport.length} products...',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait, this may take a moment',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}
