import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/mall_product.dart';
import '../providers/mall_manager_provider.dart';
import '../services/barcode_print_service.dart';
import '../widgets/product_barcode_widget.dart';

class BarcodeLibraryScreen extends StatefulWidget {
  const BarcodeLibraryScreen({super.key});

  @override
  State<BarcodeLibraryScreen> createState() => _BarcodeLibraryScreenState();
}

class _BarcodeLibraryScreenState extends State<BarcodeLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _queuedProductIds = <String>{};
  final List<_PrintHistoryEntry> _history = [];

  String _searchQuery = '';
  String _categoryFilter = 'All';
  BarcodeLabelSize _labelSize = BarcodeLabelSize.standard;
  bool _showPrice = true;
  bool _showBrand = true;
  bool _showUnit = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MallManagerProvider>(
      builder: (context, provider, _) {
        final categories = <String>{
          'All',
          ...provider.products
              .map((p) => p.category)
              .where((c) => c.trim().isNotEmpty),
        }.toList()..sort();
        final filteredProducts =
            provider.products.where(_matchesSearch).where((product) {
              return _categoryFilter == 'All' ||
                  product.category == _categoryFilter;
            }).toList()..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
        final queuedProducts = provider.products
            .where((product) => _queuedProductIds.contains(product.productId))
            .toList();
        final wide = MediaQuery.of(context).size.width >= 1120;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Barcode Library'),
            actions: [
              IconButton(
                onPressed: filteredProducts.isEmpty
                    ? null
                    : () => _printProducts(
                        filteredProducts,
                        label: 'visible labels',
                      ),
                icon: const Icon(Icons.print_outlined),
                tooltip: 'Print visible labels',
              ),
            ],
          ),
          body: Row(
            children: [
              Expanded(
                flex: wide ? 7 : 1,
                child: Column(
                  children: [
                    _HeaderPanel(
                      searchController: _searchController,
                      searchQuery: _searchQuery,
                      categoryFilter: _categoryFilter,
                      categories: categories,
                      labelSize: _labelSize,
                      showPrice: _showPrice,
                      showBrand: _showBrand,
                      showUnit: _showUnit,
                      visibleCount: filteredProducts.length,
                      onSearchChanged: (value) => setState(
                        () => _searchQuery = value.trim().toLowerCase(),
                      ),
                      onClearSearch: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      onCategoryChanged: (value) =>
                          setState(() => _categoryFilter = value),
                      onLabelSizeChanged: (value) =>
                          setState(() => _labelSize = value),
                      onShowPriceChanged: (value) =>
                          setState(() => _showPrice = value),
                      onShowBrandChanged: (value) =>
                          setState(() => _showBrand = value),
                      onShowUnitChanged: (value) =>
                          setState(() => _showUnit = value),
                      onPrintVisible: filteredProducts.isEmpty
                          ? null
                          : () => _printProducts(
                              filteredProducts,
                              label: 'visible labels',
                            ),
                    ),
                    Expanded(
                      child: filteredProducts.isEmpty
                          ? _EmptyBarcodeState(
                              hasProducts: provider.products.isNotEmpty,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredProducts.length,
                              separatorBuilder: (_, index) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                final queued = _queuedProductIds.contains(
                                  product.productId,
                                );
                                return _BarcodeLibraryCard(
                                  product: product,
                                  queued: queued,
                                  onCopy: () =>
                                      _copyBarcode(context, product.barcode),
                                  onPrint: () => _printProducts([
                                    product,
                                  ], label: product.name),
                                  onToggleQueue: () => setState(() {
                                    if (queued) {
                                      _queuedProductIds.remove(
                                        product.productId,
                                      );
                                    } else {
                                      _queuedProductIds.add(product.productId);
                                    }
                                  }),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              if (wide)
                SizedBox(
                  width: 340,
                  child: _QueuePanel(
                    queuedProducts: queuedProducts,
                    history: _history,
                    onRemoveQueued: (productId) =>
                        setState(() => _queuedProductIds.remove(productId)),
                    onClearQueue: queuedProducts.isEmpty
                        ? null
                        : () => setState(_queuedProductIds.clear),
                    onPrintQueue: queuedProducts.isEmpty
                        ? null
                        : () => _printProducts(queuedProducts, label: 'queue'),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : _MobileQueueBar(
                  count: queuedProducts.length,
                  onOpenQueue: queuedProducts.isEmpty
                      ? null
                      : () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: _QueuePanel(
                                queuedProducts: queuedProducts,
                                history: _history,
                                onRemoveQueued: (productId) => setState(
                                  () => _queuedProductIds.remove(productId),
                                ),
                                onClearQueue: queuedProducts.isEmpty
                                    ? null
                                    : () => setState(_queuedProductIds.clear),
                                onPrintQueue: queuedProducts.isEmpty
                                    ? null
                                    : () async {
                                        Navigator.pop(context);
                                        await _printProducts(
                                          queuedProducts,
                                          label: 'queue',
                                        );
                                      },
                              ),
                            ),
                          ),
                        ),
                ),
        );
      },
    );
  }

  bool _matchesSearch(MallProduct product) {
    if (_searchQuery.isEmpty) {
      return true;
    }

    final values = [
      product.name,
      product.brand,
      product.category,
      product.barcode,
    ];
    return values.any((value) => value.toLowerCase().contains(_searchQuery));
  }

  Future<void> _printProducts(
    List<MallProduct> products, {
    required String label,
  }) async {
    try {
      await BarcodePrintService.printLabelSheet(
        products.map(BarcodeLabelData.fromProduct).toList(),
        options: BarcodePrintOptions(
          size: _labelSize,
          showPrice: _showPrice,
          showBrand: _showBrand,
          showUnit: _showUnit,
        ),
      );

      if (!mounted) return;
      setState(() {
        _history.insert(
          0,
          _PrintHistoryEntry(
            title:
                'Printed ${products.length} ${products.length == 1 ? 'label' : 'labels'}',
            subtitle: '${_labelSize.name} format • $label',
            timestamp: DateTime.now(),
          ),
        );
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open the print dialog right now.'),
        ),
      );
    }
  }

  void _copyBarcode(BuildContext context, String barcode) {
    Clipboard.setData(ClipboardData(text: barcode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Barcode number copied to clipboard')),
    );
  }
}

class _HeaderPanel extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final String categoryFilter;
  final List<String> categories;
  final BarcodeLabelSize labelSize;
  final bool showPrice;
  final bool showBrand;
  final bool showUnit;
  final int visibleCount;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<BarcodeLabelSize> onLabelSizeChanged;
  final ValueChanged<bool> onShowPriceChanged;
  final ValueChanged<bool> onShowBrandChanged;
  final ValueChanged<bool> onShowUnitChanged;
  final VoidCallback? onPrintVisible;

  const _HeaderPanel({
    required this.searchController,
    required this.searchQuery,
    required this.categoryFilter,
    required this.categories,
    required this.labelSize,
    required this.showPrice,
    required this.showBrand,
    required this.showUnit,
    required this.visibleCount,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onCategoryChanged,
    required this.onLabelSizeChanged,
    required this.onShowPriceChanged,
    required this.onShowBrandChanged,
    required this.onShowUnitChanged,
    required this.onPrintVisible,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.blueGrey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$visibleCount printable barcode${visibleCount == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Search fast, build a print queue, and control label format before printing.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by product name, brand, category, or barcode',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: onClearSearch,
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
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
                width: 180,
                child: DropdownButtonFormField<BarcodeLabelSize>(
                  initialValue: labelSize,
                  decoration: const InputDecoration(labelText: 'Label format'),
                  items: BarcodeLabelSize.values
                      .map(
                        (size) => DropdownMenuItem(
                          value: size,
                          child: Text(size.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onLabelSizeChanged(value);
                  },
                ),
              ),
              FilterChip(
                selected: showPrice,
                label: const Text('Show price'),
                onSelected: onShowPriceChanged,
              ),
              FilterChip(
                selected: showBrand,
                label: const Text('Show brand'),
                onSelected: onShowBrandChanged,
              ),
              FilterChip(
                selected: showUnit,
                label: const Text('Show unit'),
                onSelected: onShowUnitChanged,
              ),
              ElevatedButton.icon(
                onPressed: onPrintVisible,
                icon: const Icon(Icons.local_printshop_outlined),
                label: const Text('Print visible'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarcodeLibraryCard extends StatelessWidget {
  final MallProduct product;
  final bool queued;
  final VoidCallback onCopy;
  final VoidCallback onPrint;
  final VoidCallback onToggleQueue;

  const _BarcodeLibraryCard({
    required this.product,
    required this.queued,
    required this.onCopy,
    required this.onPrint,
    required this.onToggleQueue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.brand} | ${product.category} | ${product.unit}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: queued ? Colors.blue.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    queued
                        ? 'Queued'
                        : 'Rs ${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: queued
                          ? Colors.blue.shade800
                          : Colors.green.shade800,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ProductBarcodeWidget(
                barcode: product.barcode,
                height: 110,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.barcode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_outlined),
                  tooltip: 'Copy barcode',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: onPrint,
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Print now'),
                ),
                OutlinedButton.icon(
                  onPressed: onToggleQueue,
                  icon: Icon(
                    queued
                        ? Icons.remove_circle_outline
                        : Icons.playlist_add_outlined,
                  ),
                  label: Text(queued ? 'Remove from queue' : 'Add to queue'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QueuePanel extends StatelessWidget {
  final List<MallProduct> queuedProducts;
  final List<_PrintHistoryEntry> history;
  final ValueChanged<String> onRemoveQueued;
  final VoidCallback? onClearQueue;
  final VoidCallback? onPrintQueue;

  const _QueuePanel({
    required this.queuedProducts,
    required this.history,
    required this.onRemoveQueued,
    required this.onClearQueue,
    required this.onPrintQueue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FBFF),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Print Queue',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '${queuedProducts.length} label${queuedProducts.length == 1 ? '' : 's'} selected for the next print batch.',
            style: const TextStyle(color: Color(0xFF5F6C7C)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onPrintQueue,
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Print queue'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onClearQueue,
                icon: const Icon(Icons.clear_all),
                tooltip: 'Clear queue',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                ...queuedProducts.map(
                  (product) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                product.barcode,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => onRemoveQueued(product.productId),
                          icon: const Icon(Icons.close),
                          tooltip: 'Remove',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Recently Printed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                if (history.isEmpty)
                  const Text('No print history in this session yet.')
                else
                  ...history
                      .take(5)
                      .map(
                        (entry) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                entry.subtitle,
                                style: const TextStyle(
                                  color: Color(0xFF5F6C7C),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(entry.timestamp),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _MobileQueueBar extends StatelessWidget {
  final int count;
  final VoidCallback? onOpenQueue;

  const _MobileQueueBar({required this.count, required this.onOpenQueue});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text('$count label${count == 1 ? '' : 's'} in queue'),
            ),
            ElevatedButton.icon(
              onPressed: onOpenQueue,
              icon: const Icon(Icons.playlist_add_check_circle_outlined),
              label: const Text('Queue'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrintHistoryEntry {
  final String title;
  final String subtitle;
  final DateTime timestamp;

  const _PrintHistoryEntry({
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });
}

class _EmptyBarcodeState extends StatelessWidget {
  final bool hasProducts;

  const _EmptyBarcodeState({required this.hasProducts});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              hasProducts
                  ? 'No barcodes match this search'
                  : 'No product barcodes yet',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasProducts
                  ? 'Try a different search term or category to find the barcode label you want.'
                  : 'Add a product first and its barcode will appear here automatically.',
              style: TextStyle(color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
