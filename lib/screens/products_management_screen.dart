import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app/app.dart';
import '../models/mall_billing_settings.dart';
import '../models/mall_product.dart';
import '../providers/mall_manager_provider.dart';
import '../screens/barcode_library_screen.dart';
import '../screens/import_export_screen.dart';
import '../services/barcode_print_service.dart';
import '../services/barcode_service.dart';
import '../widgets/product_barcode_widget.dart';

class ProductsManagementScreen extends StatefulWidget {
  const ProductsManagementScreen({super.key});

  @override
  State<ProductsManagementScreen> createState() =>
      _ProductsManagementScreenState();
}

class _ProductsManagementScreenState extends State<ProductsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _categoryFilter = 'All';
  String _stockFilter = 'All';
  String _sortBy = 'Name';
  bool _bulkDeleteMode = false;
  final Set<String> _selectedProductIds = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleBulkDeleteMode() {
    setState(() {
      _bulkDeleteMode = !_bulkDeleteMode;
      if (!_bulkDeleteMode) {
        _selectedProductIds.clear();
      }
    });
  }

  void _toggleSelected(MallProduct product) {
    setState(() {
      if (_selectedProductIds.contains(product.productId)) {
        _selectedProductIds.remove(product.productId);
      } else {
        _selectedProductIds.add(product.productId);
      }
    });
  }

  void _selectAll(List<MallProduct> products) {
    setState(() {
      _selectedProductIds
        ..clear()
        ..addAll(products.map((p) => p.productId));
    });
  }

  void _clearSelection() {
    setState(() => _selectedProductIds.clear());
  }

  Future<void> _bulkDeleteSelected(List<MallProduct> visibleProducts) async {
    final selectedProducts = visibleProducts
        .where((p) => _selectedProductIds.contains(p.productId))
        .toList();
    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one product to delete')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Products'),
        content: Text(
          'This will permanently delete ${selectedProducts.length} product(s) from inventory and remove their barcode mappings. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _BulkDeleteProgressDialog(
        productsToDelete: selectedProducts,
        onComplete: (successful, failed) {
          if (!mounted) return;
          Navigator.of(context).pop(); // close progress dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                failed == 0
                    ? 'Deleted $successful product(s)'
                    : 'Deleted $successful product(s), $failed failed',
              ),
            ),
          );
          setState(() {
            for (final p in selectedProducts) {
              _selectedProductIds.remove(p.productId);
            }
            if (_selectedProductIds.isEmpty) {
              _bulkDeleteMode = false;
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final navigator = Navigator.of(context);
        final provider = context.read<MallManagerProvider>();
        if (navigator.canPop()) {
          navigator.pop();
          return;
        }
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Manager Portal'),
            content: const Text(
              'Do you want to logout and go back to the home screen?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
        if (shouldLogout == true && mounted) {
          provider.logout();
          navigator.pushReplacement(
            MaterialPageRoute(builder: (_) => const AppModeSelector()),
          );
        }
      },
      child: Consumer<MallManagerProvider>(
        builder: (context, provider, _) {
          final products = _filteredProducts(provider.products);
          final categories = <String>{
            'All',
            ...provider.products
                .map((p) => p.category)
                .where((c) => c.trim().isNotEmpty),
          }.toList()..sort();
          final totalProducts = provider.products.length;
          final lowStockCount = provider.products
              .where((p) => p.isLowStock)
              .length;
          final outOfStockCount = provider.products
              .where((p) => !p.inStock || p.stock <= 0)
              .length;
          final wide = MediaQuery.of(context).size.width >= 1100;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Products Management'),
              elevation: 0,
              actions: [
                IconButton(
                  onPressed: provider.products.isEmpty ? null : _toggleBulkDeleteMode,
                  icon: Icon(
                    _bulkDeleteMode
                        ? Icons.checklist_rtl_outlined
                        : Icons.playlist_add_check_outlined,
                  ),
                  tooltip: _bulkDeleteMode ? 'Exit bulk delete' : 'Bulk delete',
                ),
                IconButton(
                  onPressed: _showBillingSettingsDialog,
                  icon: const Icon(Icons.receipt_long_outlined),
                  tooltip: 'Billing settings',
                ),
                IconButton(
                  onPressed: _openBarcodeLibrary,
                  icon: const Icon(Icons.qr_code_2_outlined),
                  tooltip: 'Barcode library',
                ),
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                ),
              ],
            ),
            body: provider.isLoading && provider.products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _TopToolbar(
                        totalProducts: totalProducts,
                        onAddProduct: () => _showAddProductDialog(),
                        onImportExport: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ImportExportScreen(),
                          ),
                        ),
                        onOpenBarcodeLibrary: _openBarcodeLibrary,
                        onOpenBilling: _showBillingSettingsDialog,
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: wide ? 4 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: wide ? 1.6 : 1.25,
                        children: [
                          _SummaryCard(
                            label: 'Products',
                            value: '$totalProducts',
                            icon: Icons.inventory_2_outlined,
                            accent: const Color(0xFF0B5ED7),
                          ),
                          _SummaryCard(
                            label: 'Filtered',
                            value: '${products.length}',
                            icon: Icons.filter_alt_outlined,
                            accent: const Color(0xFF6C5CE7),
                          ),
                          _SummaryCard(
                            label: 'Low stock',
                            value: '$lowStockCount',
                            icon: Icons.warning_amber_outlined,
                            accent: const Color(0xFFFF9F1C),
                          ),
                          _SummaryCard(
                            label: 'Out of stock',
                            value: '$outOfStockCount',
                            icon: Icons.remove_shopping_cart_outlined,
                            accent: const Color(0xFFEF4444),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _FilterBar(
                        searchController: _searchController,
                        searchQuery: _searchQuery,
                        categories: categories,
                        categoryFilter: _categoryFilter,
                        stockFilter: _stockFilter,
                        sortBy: _sortBy,
                        onSearchChanged: (value) => setState(
                          () => _searchQuery = value.trim().toLowerCase(),
                        ),
                        onClearSearch: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        onCategoryChanged: (value) =>
                            setState(() => _categoryFilter = value),
                        onStockChanged: (value) =>
                            setState(() => _stockFilter = value),
                        onSortChanged: (value) =>
                            setState(() => _sortBy = value),
                      ),
                      const SizedBox(height: 16),
                      if (_bulkDeleteMode)
                        _BulkDeleteBar(
                          selectedCount: _selectedProductIds.length,
                          visibleCount: products.length,
                          onSelectAll: () => _selectAll(products),
                          onClear: _clearSelection,
                          onDeleteSelected: _selectedProductIds.isEmpty
                              ? null
                              : () => _bulkDeleteSelected(products),
                        ),
                      if (_bulkDeleteMode) const SizedBox(height: 16),
                      if (products.isEmpty)
                        _EmptyProductState(
                          onAddProduct: () => _showAddProductDialog(),
                        )
                      else if (wide)
                        _ProductsTable(
                          products: products,
                          onEdit: (product) => _showAddProductDialog(product),
                          onDelete: (product) => _deleteProduct(product),
                          onPreviewBarcode: (product) =>
                              _showBarcodePreview(product),
                          selectionMode: _bulkDeleteMode,
                          selectedProductIds: _selectedProductIds,
                          onToggleSelected: _toggleSelected,
                          onToggleSelectAll: () {
                            if (_selectedProductIds.length == products.length) {
                              _clearSelection();
                            } else {
                              _selectAll(products);
                            }
                          },
                        )
                      else
                        ...products.map(
                          (product) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ProductCard(
                              product: product,
                              isLowStock: product.isLowStock,
                              onEdit: () => _showAddProductDialog(product),
                              onDelete: () => _deleteProduct(product),
                              onPreviewBarcode: () =>
                                  _showBarcodePreview(product),
                              selectionMode: _bulkDeleteMode,
                              selected: _selectedProductIds.contains(
                                product.productId,
                              ),
                              onToggleSelected: () => _toggleSelected(product),
                            ),
                          ),
                        ),
                    ],
                  ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _bulkDeleteMode
                  ? (_selectedProductIds.isEmpty
                      ? null
                      : () => _bulkDeleteSelected(products))
                  : () => _showAddProductDialog(),
              icon: Icon(
                _bulkDeleteMode ? Icons.delete_outline : Icons.add,
              ),
              label: Text(
                _bulkDeleteMode
                    ? 'Delete (${_selectedProductIds.length})'
                    : 'Add Product',
              ),
            ),
          );
        },
      ),
    );
  }

  List<MallProduct> _filteredProducts(List<MallProduct> source) {
    final filtered = source.where((product) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          [
            product.name,
            product.brand,
            product.category,
            product.barcode,
          ].any((value) => value.toLowerCase().contains(_searchQuery));
      final matchesCategory =
          _categoryFilter == 'All' || product.category == _categoryFilter;
      final matchesStock = switch (_stockFilter) {
        'In Stock' => product.inStock && product.stock > 0,
        'Low Stock' => product.isLowStock,
        'Out of Stock' => !product.inStock || product.stock <= 0,
        _ => true,
      };
      return matchesSearch && matchesCategory && matchesStock;
    }).toList();

    switch (_sortBy) {
      case 'Price':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Stock':
        filtered.sort((a, b) => b.stock.compareTo(a.stock));
        break;
      case 'Brand':
        filtered.sort(
          (a, b) => a.brand.toLowerCase().compareTo(b.brand.toLowerCase()),
        );
        break;
      default:
        filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    }
    return filtered;
  }

  void _openBarcodeLibrary() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BarcodeLibraryScreen()));
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<MallManagerProvider>().logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AppModeSelector()),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog([MallProduct? product]) {
    showDialog(
      context: context,
      builder: (_) => _AddProductDialog(product: product),
    );
  }

  void _showBillingSettingsDialog() {
    showDialog(
      context: context,
      builder: (_) => const _BillingSettingsDialog(),
    );
  }

  void _showBarcodePreview(MallProduct product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Product Barcode'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${product.brand} | Rs ${product.price.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Barcode Number',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      product.barcode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ProductBarcodeWidget(
                  barcode: product.barcode,
                  height: 140,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: product.barcode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Barcode copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copy'),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _printBarcode(product);
            },
            icon: const Icon(Icons.print_outlined),
            label: const Text('Print'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _printBarcode(MallProduct product) async {
    try {
      await BarcodePrintService.printSingleLabel(
        BarcodeLabelData.fromProduct(product),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open the print dialog right now.'),
        ),
      );
    }
  }

  void _deleteProduct(MallProduct product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final provider = this.context.read<MallManagerProvider>();
              final messenger = ScaffoldMessenger.of(this.context);
              Navigator.pop(context);
              final success = await provider.deleteProduct(
                product.productId,
                product.barcode,
              );
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Product deleted successfully'
                        : provider.error ?? 'Error deleting product',
                  ),
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _TopToolbar extends StatelessWidget {
  final int totalProducts;
  final VoidCallback onAddProduct;
  final VoidCallback onImportExport;
  final VoidCallback onOpenBarcodeLibrary;
  final VoidCallback onOpenBilling;

  const _TopToolbar({
    required this.totalProducts,
    required this.onAddProduct,
    required this.onImportExport,
    required this.onOpenBarcodeLibrary,
    required this.onOpenBilling,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4EBF3)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Product Workspace',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalProducts products ready for search, filtering, quick edit, and barcode printing.',
                style: const TextStyle(color: Color(0xFF5F6C7C)),
              ),
            ],
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onAddProduct,
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          ),
          OutlinedButton.icon(
            onPressed: onImportExport,
            icon: const Icon(Icons.sync_alt),
            label: const Text('Import / Export'),
          ),
          OutlinedButton.icon(
            onPressed: onOpenBarcodeLibrary,
            icon: const Icon(Icons.qr_code_2_outlined),
            label: const Text('Barcode Library'),
          ),
          OutlinedButton.icon(
            onPressed: onOpenBilling,
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Billing Settings'),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final List<String> categories;
  final String categoryFilter;
  final String stockFilter;
  final String sortBy;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onStockChanged;
  final ValueChanged<String> onSortChanged;

  const _FilterBar({
    required this.searchController,
    required this.searchQuery,
    required this.categories,
    required this.categoryFilter,
    required this.stockFilter,
    required this.sortBy,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onCategoryChanged,
    required this.onStockChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4EBF3)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 280,
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name, brand, category, barcode',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: onClearSearch,
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              initialValue: categoryFilter,
              decoration: const InputDecoration(labelText: 'Category'),
              items: categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onCategoryChanged(value);
              },
            ),
          ),
          SizedBox(
            width: 170,
            child: DropdownButtonFormField<String>(
              initialValue: stockFilter,
              decoration: const InputDecoration(labelText: 'Stock status'),
              items: const ['All', 'In Stock', 'Low Stock', 'Out of Stock']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onStockChanged(value);
              },
            ),
          ),
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<String>(
              initialValue: sortBy,
              decoration: const InputDecoration(labelText: 'Sort by'),
              items: const ['Name', 'Price', 'Stock', 'Brand']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onSortChanged(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EBF3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: accent.withValues(alpha: 0.12),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(color: Color(0xFF607084))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductsTable extends StatelessWidget {
  final List<MallProduct> products;
  final ValueChanged<MallProduct> onEdit;
  final ValueChanged<MallProduct> onDelete;
  final ValueChanged<MallProduct> onPreviewBarcode;
  final bool selectionMode;
  final Set<String> selectedProductIds;
  final ValueChanged<MallProduct> onToggleSelected;
  final VoidCallback onToggleSelectAll;

  const _ProductsTable({
    required this.products,
    required this.onEdit,
    required this.onDelete,
    required this.onPreviewBarcode,
    this.selectionMode = false,
    this.selectedProductIds = const <String>{},
    required this.onToggleSelected,
    required this.onToggleSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4EBF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Table',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use this richer table for product search, quick edit, barcode preview, and audit-style metadata.',
            style: TextStyle(color: Color(0xFF5F6C7C)),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF7FAFD)),
              columns: [
                if (selectionMode)
                  DataColumn(
                    label: Checkbox(
                      value: products.isNotEmpty &&
                          selectedProductIds.length == products.length,
                      onChanged: (_) => onToggleSelectAll(),
                    ),
                  ),
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Brand')),
                DataColumn(label: Text('Category')),
                DataColumn(label: Text('Price')),
                DataColumn(label: Text('Stock')),
                DataColumn(label: Text('Barcode')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Audit')),
                DataColumn(label: Text('Actions')),
              ],
              rows: products.map((product) {
                final status = !product.inStock || product.stock <= 0
                    ? 'Out of stock'
                    : product.isLowStock
                    ? 'Low stock'
                    : 'Healthy';
                final isSelected = selectedProductIds.contains(product.productId);
                return DataRow(
                  selected: selectionMode ? isSelected : false,
                  onSelectChanged: selectionMode
                      ? (_) => onToggleSelected(product)
                      : null,
                  cells: [
                    if (selectionMode)
                      DataCell(
                        Checkbox(
                          value: isSelected,
                          onChanged: (_) => onToggleSelected(product),
                        ),
                      ),
                    DataCell(
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 36,
                              height: 36,
                              color: const Color(0xFFF1F5F9),
                              child: product.imageUrl.trim().isEmpty
                                  ? const Icon(
                                      Icons.image_outlined,
                                      size: 18,
                                      color: Color(0xFF64748B),
                                    )
                                  : Image.network(
                                      product.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stack) {
                                        return const Icon(
                                          Icons.broken_image_outlined,
                                          size: 18,
                                          color: Color(0xFF64748B),
                                        );
                                      },
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(product.brand)),
                    DataCell(Text(product.category)),
                    DataCell(Text('Rs ${product.price.toStringAsFixed(2)}')),
                    DataCell(Text('${product.stock}')),
                    DataCell(
                      SelectableText(
                        product.barcode,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    DataCell(Text(status)),
                    DataCell(
                      Text(
                        'ID ${product.productId}\n${product.unit}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed:
                                selectionMode ? null : () => onEdit(product),
                            child: const Text('Edit'),
                          ),
                          TextButton(
                            onPressed: selectionMode
                                ? null
                                : () => onPreviewBarcode(product),
                            child: const Text('Barcode'),
                          ),
                          TextButton(
                            onPressed:
                                selectionMode ? null : () => onDelete(product),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProductState extends StatelessWidget {
  final VoidCallback onAddProduct;

  const _EmptyProductState({required this.onAddProduct});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No products found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first product or adjust the filters. New products automatically become available in the barcode library.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAddProduct,
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillingSettingsDialog extends StatefulWidget {
  const _BillingSettingsDialog();

  @override
  State<_BillingSettingsDialog> createState() => _BillingSettingsDialogState();
}

class _BillingSettingsDialogState extends State<_BillingSettingsDialog> {
  late final TextEditingController _gstCtrl;
  late final TextEditingController _taxLabelCtrl;
  late final TextEditingController _taxCtrl;
  late final TextEditingController _extraChargeLabelCtrl;
  late final TextEditingController _extraChargeCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<MallManagerProvider>().billingSettings;
    _gstCtrl = TextEditingController(
      text: settings.gstPercent == 0 ? '' : settings.gstPercent.toString(),
    );
    _taxLabelCtrl = TextEditingController(text: settings.taxLabel);
    _taxCtrl = TextEditingController(
      text: settings.taxPercent == 0 ? '' : settings.taxPercent.toString(),
    );
    _extraChargeLabelCtrl = TextEditingController(
      text: settings.extraChargeLabel,
    );
    _extraChargeCtrl = TextEditingController(
      text: settings.extraChargeAmount == 0
          ? ''
          : settings.extraChargeAmount.toString(),
    );
  }

  @override
  void dispose() {
    _gstCtrl.dispose();
    _taxLabelCtrl.dispose();
    _taxCtrl.dispose();
    _extraChargeLabelCtrl.dispose();
    _extraChargeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<MallManagerProvider>().billingSettings;
    return AlertDialog(
      title: const Text('Billing Settings'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set GST, tax, and extra charges manually for this mall. Checkout will use only these values.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _gstCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'GST %',
                  hintText: 'e.g. 18',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _taxLabelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Additional Tax Label',
                  hintText: 'e.g. Service Tax',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _taxCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Additional Tax %',
                  hintText: 'e.g. 2.5',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _extraChargeLabelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Extra Charge Label',
                  hintText: 'e.g. Packing Charges',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _extraChargeCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Extra Charge Amount',
                  hintText: 'e.g. 12',
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Summary',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text('GST: ${settings.gstPercent.toStringAsFixed(1)}%'),
                    Text(
                      '${settings.taxLabel}: ${settings.taxPercent.toStringAsFixed(1)}%',
                    ),
                    Text(
                      '${settings.extraChargeLabel}: Rs ${settings.extraChargeAmount.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final settings = MallBillingSettings(
      gstPercent: double.tryParse(_gstCtrl.text.trim()) ?? 0,
      taxLabel: _taxLabelCtrl.text.trim().isEmpty
          ? 'Tax'
          : _taxLabelCtrl.text.trim(),
      taxPercent: double.tryParse(_taxCtrl.text.trim()) ?? 0,
      extraChargeLabel: _extraChargeLabelCtrl.text.trim().isEmpty
          ? 'Extra Charges'
          : _extraChargeLabelCtrl.text.trim(),
      extraChargeAmount: double.tryParse(_extraChargeCtrl.text.trim()) ?? 0,
    );
    final provider = context.read<MallManagerProvider>();
    final success = await provider.updateBillingSettings(settings);
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Billing settings updated')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Unable to update billing settings'),
        ),
      );
    }
  }
}

class _ProductCard extends StatelessWidget {
  final MallProduct product;
  final bool isLowStock;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPreviewBarcode;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onToggleSelected;

  const _ProductCard({
    required this.product,
    required this.isLowStock,
    required this.onEdit,
    required this.onDelete,
    required this.onPreviewBarcode,
    this.selectionMode = false,
    this.selected = false,
    required this.onToggleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: isLowStock ? 4 : 1,
      shadowColor: isLowStock ? Colors.red.withValues(alpha: 0.25) : null,
      color: isLowStock ? Colors.red.shade50 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectionMode) ...[
                  Checkbox(
                    value: selected,
                    onChanged: (_) => onToggleSelected(),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isLowStock
                                    ? Colors.red.shade900
                                    : Colors.black,
                              ),
                            ),
                          ),
                          if (isLowStock)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'LOW STOCK',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.brand} | ${product.category} | ID ${product.productId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isLowStock
                              ? Colors.red.shade700
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: product.inStock
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product.inStock ? 'In Stock' : 'Out of Stock',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: product.inStock
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _MetricChip(
                  label: 'Price',
                  value: 'Rs ${product.price.toStringAsFixed(2)}',
                ),
                _MetricChip(
                  label: 'Weight',
                  value: '${product.weight}${product.weightUnit}',
                ),
                _MetricChip(label: 'Stock', value: product.stock.toString()),
                _MetricChip(label: 'Barcode', value: product.barcode),
                _MetricChip(label: 'Audit', value: product.unit),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: selectionMode ? null : onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Quick Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: selectionMode ? null : onPreviewBarcode,
                    icon: const Icon(Icons.view_stream, size: 18),
                    label: const Text('Barcode'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: selectionMode ? null : onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _BulkDeleteBar extends StatelessWidget {
  final int selectedCount;
  final int visibleCount;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;
  final VoidCallback? onDeleteSelected;

  const _BulkDeleteBar({
    required this.selectedCount,
    required this.visibleCount,
    required this.onSelectAll,
    required this.onClear,
    required this.onDeleteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.delete_sweep_outlined, color: Color(0xFFB91C1C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$selectedCount selected (out of $visibleCount visible)',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: onSelectAll,
            child: const Text('Select all'),
          ),
          TextButton(
            onPressed: onClear,
            child: const Text('Clear'),
          ),
          const SizedBox(width: 6),
          FilledButton.icon(
            onPressed: onDeleteSelected,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete selected'),
          ),
        ],
      ),
    );
  }
}

class _BulkDeleteProgressDialog extends StatefulWidget {
  final List<MallProduct> productsToDelete;
  final void Function(int successful, int failed) onComplete;

  const _BulkDeleteProgressDialog({
    required this.productsToDelete,
    required this.onComplete,
  });

  @override
  State<_BulkDeleteProgressDialog> createState() =>
      _BulkDeleteProgressDialogState();
}

class _BulkDeleteProgressDialogState extends State<_BulkDeleteProgressDialog> {
  late Future<void> _deleteFuture;

  @override
  void initState() {
    super.initState();
    _deleteFuture = _doDelete();
  }

  Future<void> _doDelete() async {
    final provider = context.read<MallManagerProvider>();
    int successful = 0;
    int failed = 0;

    for (final product in widget.productsToDelete) {
      try {
        final ok = await provider.deleteProduct(
          product.productId,
          product.barcode,
        );
        if (ok) {
          successful++;
        } else {
          failed++;
        }
      } catch (_) {
        failed++;
      }
      await Future.delayed(const Duration(milliseconds: 80));
    }

    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 350), () {
      widget.onComplete(successful, failed);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Deleting Products'),
      content: FutureBuilder<void>(
        future: _deleteFuture,
        builder: (context, snapshot) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Deleting ${widget.productsToDelete.length} product(s)...',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait',
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

class _AddProductDialog extends StatefulWidget {
  final MallProduct? product;

  const _AddProductDialog({this.product});

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _categoryCtrl;
  final List<String> _weightUnits = ['mg', 'g', 'kg', 'ml', 'l'];
  late String _selectedWeightUnit;
  bool _inStock = true;
  bool _isSubmitting = false;
  bool _showBarcodePreview = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product?.name ?? '');
    _barcodeCtrl = TextEditingController(text: widget.product?.barcode ?? '');
    _priceCtrl = TextEditingController(
      text: widget.product != null ? widget.product!.price.toString() : '',
    );
    _weightCtrl = TextEditingController(
      text: widget.product != null ? widget.product!.weight.toString() : '',
    );
    _stockCtrl = TextEditingController(
      text: widget.product != null ? widget.product!.stock.toString() : '0',
    );
    _unitCtrl = TextEditingController(text: widget.product?.unit ?? '1 pc');
    _brandCtrl = TextEditingController(
      text: widget.product?.brand ?? 'General',
    );
    _categoryCtrl = TextEditingController(
      text: widget.product?.category ?? 'General',
    );
    _selectedWeightUnit = widget.product?.weightUnit ?? 'g';
    _inStock = widget.product?.inStock ?? true;
    _showBarcodePreview = _barcodeCtrl.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _priceCtrl.dispose();
    _weightCtrl.dispose();
    _stockCtrl.dispose();
    _unitCtrl.dispose();
    _brandCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _barcodeCtrl.text.trim().isEmpty ||
        _priceCtrl.text.trim().isEmpty ||
        _weightCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final product = MallProduct(
      productId:
          widget.product?.productId ??
          'p${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      barcode: _barcodeCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
      weight: double.tryParse(_weightCtrl.text.trim()) ?? 0,
      weightUnit: _selectedWeightUnit,
      unit: _unitCtrl.text.trim(),
      brand: _brandCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      stock: int.tryParse(_stockCtrl.text.trim()) ?? 0,
      inStock: _inStock,
    );

    final provider = context.read<MallManagerProvider>();
    final success = widget.product != null
        ? await provider.updateProduct(product)
        : await provider.addProduct(product);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.product != null
                ? 'Product updated successfully'
                : 'Product added and barcode saved to the library',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Error saving product')),
      );
    }
  }

  void _generateBarcode() {
    final generatedBarcode = BarcodeService.generateRandomBarcode();
    setState(() {
      _barcodeCtrl.text = generatedBarcode;
      _showBarcodePreview = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Barcode generated: $generatedBarcode'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.product != null ? 'Quick Edit Product' : 'Add Product',
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Product Name*',
                  hintText: 'e.g., Milk 1L',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _barcodeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Barcode*',
                        hintText: 'e.g., 8901234567890',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setState(
                        () => _showBarcodePreview = value.trim().isNotEmpty,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Generate barcode',
                    child: FloatingActionButton.small(
                      heroTag: 'barcode_generator',
                      onPressed: _generateBarcode,
                      child: const Icon(Icons.auto_awesome, size: 18),
                    ),
                  ),
                ],
              ),
              if (_showBarcodePreview &&
                  _barcodeCtrl.text.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Barcode Preview',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _barcodeCtrl.text.trim(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ProductBarcodeWidget(
                          barcode: _barcodeCtrl.text.trim(),
                          height: 120,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Price*',
                        hintText: '0.00',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _weightCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Weight*',
                        hintText: '1.0',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedWeightUnit,
                      items: _weightUnits
                          .map(
                            (unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedWeightUnit = value);
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Unit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _stockCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        hintText: '0',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _unitCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Pack Unit',
                        hintText: '1 pc',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _brandCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Brand',
                        hintText: 'General',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _categoryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        hintText: 'General',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('In Stock'),
                value: _inStock,
                onChanged: (value) => setState(() => _inStock = value ?? true),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.product != null ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
