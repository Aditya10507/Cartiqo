import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app.dart';
import '../models/mall_product.dart';
import '../providers/mall_manager_provider.dart';
import '../widgets/swiftcart_logo.dart';
import '../widgets/manager_sales_dashboard_panel.dart';
import 'barcode_library_screen.dart';
import 'import_export_screen.dart';
import 'mall_billing_settings_screen.dart';
import 'mall_manager_profile_screen.dart';
import 'products_management_screen.dart';
import 'sales_history_screen.dart';

class WebMallManagerDashboardScreen extends StatelessWidget {
  const WebMallManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MallManagerProvider>(
      builder: (context, provider, _) {
        final products = provider.products;
        final wide = MediaQuery.of(context).size.width >= 1180;
        final inStock = products.where((product) => product.inStock).length;
        final lowStock = products.where((product) => product.isLowStock).length;
        final outOfStock = products
            .where((product) => !product.inStock || product.stock <= 0)
            .length;
        final topProducts = [...products]
          ..sort((a, b) => b.price.compareTo(a.price));

        return Scaffold(
          backgroundColor: const Color(0xFFF5F8FC),
          drawer: wide
              ? null
              : Drawer(
                  child: _ManagerSidebar(
                    compact: true,
                    mallId: provider.currentMallId ?? 'Mall Manager',
                    onOpenSales: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SalesHistoryScreen(),
                      ),
                    ),
                    onOpenProfile: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MallManagerProfileScreen(),
                      ),
                    ),
                    onOpenProducts: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProductsManagementScreen(),
                      ),
                    ),
                    onOpenBillingSettings: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MallBillingSettingsScreen(),
                      ),
                    ),
                    onOpenBarcodeLabels: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BarcodeLibraryScreen(),
                      ),
                    ),
                    onBackHome: () {
                      provider.logout();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const AppModeSelector(),
                        ),
                      );
                    },
                  ),
                ),
          body: SafeArea(
            child: Row(
              children: [
                if (wide)
                  _ManagerSidebar(
                    mallId: provider.currentMallId ?? 'Mall Manager',
                    onOpenSales: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SalesHistoryScreen(),
                      ),
                    ),
                    onOpenProfile: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MallManagerProfileScreen(),
                      ),
                    ),
                    onOpenProducts: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProductsManagementScreen(),
                      ),
                    ),
                    onOpenBillingSettings: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MallBillingSettingsScreen(),
                      ),
                    ),
                    onOpenBarcodeLabels: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BarcodeLibraryScreen(),
                      ),
                    ),
                    onBackHome: () {
                      provider.logout();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const AppModeSelector(),
                        ),
                      );
                    },
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _ManagerHeader(
                        wide: wide,
                        mallId: provider.currentMallId ?? '',
                        onMenuTap: wide
                            ? null
                            : () => Scaffold.of(context).openDrawer(),
                        onOpenLabels: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BarcodeLibraryScreen(),
                          ),
                        ),
                        onOpenProducts: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProductsManagementScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GridView.count(
                        crossAxisCount: wide ? 4 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: wide ? 1.55 : 1.25,
                        children: [
                          _ManagerStatCard(
                            label: 'Products',
                            value: '${products.length}',
                            icon: Icons.inventory_2_outlined,
                            accent: const Color(0xFF0B5ED7),
                          ),
                          _ManagerStatCard(
                            label: 'In stock',
                            value: '$inStock',
                            icon: Icons.check_circle_outline,
                            accent: const Color(0xFF12B886),
                          ),
                          _ManagerStatCard(
                            label: 'Low stock',
                            value: '$lowStock',
                            icon: Icons.warning_amber_outlined,
                            accent: const Color(0xFFFF9F1C),
                          ),
                          _ManagerStatCard(
                            label: 'Out of stock',
                            value: '$outOfStock',
                            icon: Icons.remove_shopping_cart_outlined,
                            accent: const Color(0xFFEF4444),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _ActionRow(
                        actions: [
                          _ActionItem(
                            icon: Icons.assessment_outlined,
                            label: 'Sales history',
                            subtitle: 'Filter and export reports',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SalesHistoryScreen(),
                              ),
                            ),
                          ),
                          _ActionItem(
                            icon: Icons.upload_file_outlined,
                            label: 'Import CSV',
                            subtitle: 'Bulk product upload',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ImportExportScreen(),
                              ),
                            ),
                          ),
                          _ActionItem(
                            icon: Icons.download_outlined,
                            label: 'Export CSV',
                            subtitle: 'Download inventory data',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ImportExportScreen(),
                              ),
                            ),
                          ),
                          _ActionItem(
                            icon: Icons.print_outlined,
                            label: 'Bulk print',
                            subtitle: 'Create label batches',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const BarcodeLibraryScreen(),
                              ),
                            ),
                          ),
                          _ActionItem(
                            icon: Icons.edit_note_outlined,
                            label: 'Stock update',
                            subtitle: 'Run bulk stock edits',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ProductsManagementScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ManagerSalesDashboardPanel(provider: provider),
                      const SizedBox(height: 20),
                      wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: _InventoryPanel(products: products),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    children: [
                                      _AlertsPanel(
                                        lowStock: lowStock,
                                        outOfStock: outOfStock,
                                      ),
                                      const SizedBox(height: 16),
                                      _BillingPreviewPanel(provider: provider),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _InventoryPanel(products: products),
                                const SizedBox(height: 16),
                                _AlertsPanel(
                                  lowStock: lowStock,
                                  outOfStock: outOfStock,
                                ),
                                const SizedBox(height: 16),
                                _BillingPreviewPanel(provider: provider),
                              ],
                            ),
                      const SizedBox(height: 20),
                      wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _TopProductsPanel(
                                    products: topProducts,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _TransactionsPanel(provider: provider),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _PromotionsPanel(provider: provider),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _TopProductsPanel(products: topProducts),
                                const SizedBox(height: 16),
                                _TransactionsPanel(provider: provider),
                                const SizedBox(height: 16),
                                _PromotionsPanel(provider: provider),
                              ],
                            ),
                      const SizedBox(height: 20),
                      wide
                          ? Row(
                              children: [
                                Expanded(child: _SearchPanel()),
                                SizedBox(width: 16),
                                Expanded(
                                  child: _StaffActivityPanel(
                                    provider: provider,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                const _SearchPanel(),
                                SizedBox(height: 16),
                                _StaffActivityPanel(provider: provider),
                              ],
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
}

class _ManagerSidebar extends StatelessWidget {
  final bool compact;
  final String mallId;
  final VoidCallback onOpenSales;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenProducts;
  final VoidCallback onOpenBillingSettings;
  final VoidCallback onOpenBarcodeLabels;
  final VoidCallback onBackHome;

  const _ManagerSidebar({
    this.compact = false,
    required this.mallId,
    required this.onOpenSales,
    required this.onOpenProfile,
    required this.onOpenProducts,
    required this.onOpenBillingSettings,
    required this.onOpenBarcodeLabels,
    required this.onBackHome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? double.infinity : 280,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      color: const Color(0xFF0F172A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SwiftCartLogo(
            size: 64,
            showWordmark: false,
            primaryColor: Color(0xFFEAF3FF),
            accentColor: Color(0xFFD8FFF0),
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'Mall Manager',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mallId,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 28),
          _MenuTile(
            icon: Icons.assessment_outlined,
            label: 'Sales History',
            onTap: onOpenSales,
          ),
          _MenuTile(
            icon: Icons.person_outline,
            label: 'Profile',
            onTap: onOpenProfile,
          ),
          _MenuTile(
            icon: Icons.inventory_2_outlined,
            label: 'Products',
            onTap: onOpenProducts,
          ),
          _MenuTile(
            icon: Icons.receipt_long_outlined,
            label: 'Billing Settings',
            onTap: onOpenBillingSettings,
          ),
          _MenuTile(
            icon: Icons.print_outlined,
            label: 'Barcode Labels',
            onTap: onOpenBarcodeLabels,
          ),
          const Spacer(),
          _MenuTile(
            icon: Icons.arrow_back_outlined,
            label: 'Back Home',
            onTap: onBackHome,
            filled: true,
          ),
        ],
      ),
    );
  }
}

class _ManagerHeader extends StatelessWidget {
  final bool wide;
  final String mallId;
  final VoidCallback? onMenuTap;
  final VoidCallback onOpenLabels;
  final VoidCallback onOpenProducts;

  const _ManagerHeader({
    required this.wide,
    required this.mallId,
    this.onMenuTap,
    required this.onOpenLabels,
    required this.onOpenProducts,
  });

  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mall Manager Workspace',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Operate products, pricing labels, billing rules, and daily retail actions for mall $mallId.',
          style: const TextStyle(fontSize: 15, color: Color(0xFF5F6C7C)),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: onOpenLabels,
          icon: const Icon(Icons.print_outlined),
          label: const Text('Barcode Labels'),
        ),
        ElevatedButton.icon(
          onPressed: onOpenProducts,
          icon: const Icon(Icons.inventory_2_outlined),
          label: const Text('Open Product Manager'),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4EBF3)),
      ),
      child: wide
          ? Row(
              children: [
                Expanded(child: title),
                actions,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: onMenuTap,
                      icon: const Icon(Icons.menu),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: title),
                  ],
                ),
                const SizedBox(height: 12),
                actions,
              ],
            ),
    );
  }
}

class _InventoryPanel extends StatefulWidget {
  final List<MallProduct> products;

  const _InventoryPanel({required this.products});

  @override
  State<_InventoryPanel> createState() => _InventoryPanelState();
}

class _InventoryPanelState extends State<_InventoryPanel> {
  late final ScrollController _verticalController;
  late final ScrollController _horizontalController;

  @override
  void initState() {
    super.initState();
    _verticalController = ScrollController();
    _horizontalController = ScrollController();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Inventory Snapshot',
      subtitle:
          'A quick browser view of your products before opening the full workspace.',
      child: widget.products.isEmpty
          ? const SizedBox(
              height: 220,
              child: Center(child: Text('No products added yet')),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _GridHint(label: 'Scroll down for more products'),
                    _GridHint(label: 'Scroll right for more columns'),
                    _GridHint(label: 'Use Product Manager for full editing'),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 400,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE4EBF3)),
                  ),
                  child: Scrollbar(
                    controller: _verticalController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _verticalController,
                      padding: const EdgeInsets.all(12),
                      child: Scrollbar(
                        controller: _horizontalController,
                        thumbVisibility: true,
                        notificationPredicate: (notification) =>
                            notification.metrics.axis == Axis.horizontal,
                        child: SingleChildScrollView(
                          controller: _horizontalController,
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 980),
                            child: DataTable(
                              horizontalMargin: 18,
                              columnSpacing: 26,
                              dataRowMinHeight: 72,
                              dataRowMaxHeight: 88,
                              headingRowHeight: 58,
                              headingRowColor: WidgetStateProperty.all(
                                const Color(0xFFEFF5FC),
                              ),
                              border: TableBorder(
                                horizontalInside: BorderSide(
                                  color: const Color(0xFFDCE6F3),
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              columns: const [
                                DataColumn(label: Text('Product')),
                                DataColumn(label: Text('Brand')),
                                DataColumn(label: Text('Category')),
                                DataColumn(label: Text('Price')),
                                DataColumn(label: Text('Stock')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Barcode')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: widget.products.map((product) {
                                final status =
                                    !product.inStock || product.stock <= 0
                                    ? 'Out of stock'
                                    : product.isLowStock
                                    ? 'Low stock'
                                    : 'In stock';

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      SizedBox(
                                        width: 220,
                                        child: Text(
                                          product.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 130,
                                        child: Text(product.brand),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 140,
                                        child: Text(product.category),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 110,
                                        child: Text(
                                          'Rs ${product.price.toStringAsFixed(2)}',
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 90,
                                        child: Text(
                                          '${product.stock}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(_StockBadge(label: status)),
                                    DataCell(
                                      SizedBox(
                                        width: 170,
                                        child: SelectableText(
                                          product.barcode,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 110,
                                        child: TextButton(
                                          onPressed: () async {
                                            final provider = context
                                                .read<MallManagerProvider>();
                                            final confirmed =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title:
                                                    const Text('Delete Product'),
                                                content: Text(
                                                  'Delete "${product.name}"?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                      context,
                                                      false,
                                                    ),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                      context,
                                                      true,
                                                    ),
                                                    child: const Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirmed != true) return;
                                            await provider.deleteProduct(
                                              product.productId,
                                              product.barcode,
                                            );
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  provider.error == null
                                                      ? 'Product deleted'
                                                      : provider.error!,
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(
                                              color: Color(0xFFDC2626),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _GridHint extends StatelessWidget {
  final String label;

  const _GridHint({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7FC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDCE6F3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF5F6C7C),
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final String label;

  const _StockBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final accent = switch (label) {
      'Out of stock' => const Color(0xFFE03131),
      'Low stock' => const Color(0xFFFF9F1C),
      _ => const Color(0xFF12B886),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: accent, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _AlertsPanel extends StatelessWidget {
  final int lowStock;
  final int outOfStock;

  const _AlertsPanel({required this.lowStock, required this.outOfStock});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Inventory Alerts',
      subtitle: 'Keep urgent stock conditions and workflow issues visible.',
      child: Column(
        children: [
          _MiniCard(
            title: 'Low stock products',
            subtitle: '$lowStock items need restocking soon',
          ),
          _MiniCard(
            title: 'Out of stock products',
            subtitle: '$outOfStock items are unavailable right now',
          ),
          const _MiniCard(
            title: 'Duplicate barcode check',
            subtitle:
                'Keep this area for conflict warnings during future bulk imports',
          ),
        ],
      ),
    );
  }
}

class _BillingPreviewPanel extends StatelessWidget {
  final MallManagerProvider provider;

  const _BillingPreviewPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    final settings = provider.billingSettings;
    return _Panel(
      title: 'Billing Rules Preview',
      subtitle:
          'Keep the current GST and extra-charge behavior visible without opening settings.',
      child: Column(
        children: [
          _MiniCard(
            title: 'GST enabled',
            subtitle: settings.hasGst ? 'Yes' : 'No',
          ),
          _MiniCard(
            title: 'GST rate',
            subtitle: '${settings.gstPercent.toStringAsFixed(1)}%',
          ),
          _MiniCard(
            title: 'Extra charges',
            subtitle: settings.hasExtraCharge
                ? '${settings.extraChargeLabel} • Rs ${settings.extraChargeAmount.toStringAsFixed(2)}'
                : 'Disabled',
          ),
        ],
      ),
    );
  }
}

class _TopProductsPanel extends StatelessWidget {
  final List<MallProduct> products;

  const _TopProductsPanel({required this.products});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Top Products',
      subtitle: 'Use this section for most valuable or most watched items.',
      child: products.isEmpty
          ? const Text(
              'Product highlights will appear here once inventory is available.',
            )
          : Column(
              children: products
                  .take(4)
                  .map(
                    (product) => _MiniCard(
                      title: product.name,
                      subtitle:
                          '${product.brand} • Rs ${product.price.toStringAsFixed(2)} • stock ${product.stock}',
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _TransactionsPanel extends StatelessWidget {
  final MallManagerProvider provider;

  const _TransactionsPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Recent Transactions',
      subtitle: 'Latest payment records captured for this mall.',
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: provider.watchMallPayments(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Text('No transactions recorded yet.');
          }
          return Column(
            children: items.take(4).map((item) {
              final amount = ((item['amount'] as num?)?.toDouble() ?? 0)
                  .toStringAsFixed(2);
              return _MiniCard(
                title:
                    '${(item['paymentNumber'] ?? 'Payment').toString()} • Rs $amount',
                subtitle:
                    '${(item['customerName'] ?? 'Customer').toString()} • ${(item['method'] ?? 'method').toString()} • ${(item['status'] ?? 'success').toString()}',
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _PromotionsPanel extends StatelessWidget {
  final MallManagerProvider provider;

  const _PromotionsPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Promotions Panel',
      subtitle: 'Create and manage active offer windows from the dashboard.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => _PromotionDialog(provider: provider),
              ),
              icon: const Icon(Icons.local_offer_outlined),
              label: const Text('New promotion'),
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: provider.watchPromotions(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const [];
              if (items.isEmpty) {
                return const Text('No promotions configured yet.');
              }
              return Column(
                children: items.take(4).map((item) {
                  final id = (item['id'] ?? '').toString();
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FBFF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (item['title'] ?? 'Promotion').toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(item['discountLabel'] ?? '').toString()} • ${(item['description'] ?? '').toString()}',
                          style: const TextStyle(
                            color: Color(0xFF5F6C7C),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            Text(
                              (item['isActive'] ?? false) == true
                                  ? 'Active'
                                  : 'Paused',
                            ),
                            TextButton(
                              onPressed: () => provider.deletePromotion(id),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel();

  @override
  Widget build(BuildContext context) {
    return const _Panel(
      title: 'Search And Filters',
      subtitle:
          'Add global product search, category filters, and stock status shortcuts.',
      child: Column(
        children: [
          _MiniCard(
            title: 'Search by name or barcode',
            subtitle: 'Fast lookup for products and labels',
          ),
          _MiniCard(
            title: 'Filter by category',
            subtitle: 'Add category, stock, and price-range controls',
          ),
        ],
      ),
    );
  }
}

class _StaffActivityPanel extends StatelessWidget {
  final MallManagerProvider provider;

  const _StaffActivityPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Staff Activity',
      subtitle: 'Recent manager-side actions logged from the web workspace.',
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: provider.watchStaffActivity(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Text('No activity logged yet.');
          }
          return Column(
            children: items.take(5).map((item) {
              return _MiniCard(
                title: (item['action'] ?? 'Activity').toString(),
                subtitle:
                    '${(item['details'] ?? '').toString()} • ${(item['managerEmail'] ?? item['managerId'] ?? '').toString()}',
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final List<_ActionItem> actions;

  const _ActionRow({required this.actions});

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
        children: actions
            .map(
              (action) => SizedBox(
                width: 220,
                child: InkWell(
                  onTap: action.onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FBFF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFE8F0FF),
                          child: Icon(
                            action.icon,
                            color: const Color(0xFF0B5ED7),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                action.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                action.subtitle,
                                style: const TextStyle(
                                  color: Color(0xFF5F6C7C),
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: filled
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManagerStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _ManagerStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4EBF3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: accent.withValues(alpha: 0.12),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
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

class _Panel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4EBF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Color(0xFF5F6C7C))),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _MiniCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF5F6C7C), height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _PromotionDialog extends StatefulWidget {
  final MallManagerProvider provider;

  const _PromotionDialog({required this.provider});

  @override
  State<_PromotionDialog> createState() => _PromotionDialogState();
}

class _PromotionDialogState extends State<_PromotionDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountController = TextEditingController();
  bool _isActive = true;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Promotion'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _discountController,
              decoration: const InputDecoration(
                labelText: 'Discount Label',
                hintText: 'e.g. Flat 20% off',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              title: const Text('Active'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty ||
        _discountController.text.trim().isEmpty) {
      return;
    }
    setState(() => _saving = true);
    final success = await widget.provider.savePromotion(
      title: _titleController.text,
      description: _descriptionController.text,
      discountLabel: _discountController.text,
      startDate: null,
      endDate: null,
      isActive: _isActive,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      Navigator.pop(context);
    }
  }
}
