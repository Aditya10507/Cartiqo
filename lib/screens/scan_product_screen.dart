import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../models/mall_product.dart';
import '../providers/cart_provider.dart';
import '../services/storefront_api_service.dart';
import 'cart_screen.dart';
import 'barcode_scanner_screen.dart';
import 'product_search_screen.dart';

class ScanProductScreen extends StatefulWidget {
  final String mallId;
  const ScanProductScreen({super.key, required this.mallId});

  @override
  State<ScanProductScreen> createState() => _ScanProductScreenState();
}

class _ScanProductScreenState extends State<ScanProductScreen> {
  final _storefrontApiService = StorefrontApiService();
  final _barcodeCtrl = TextEditingController();
  bool _loading = false;

  MallProduct? _product;
  String? _message;

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (scanned == null) return;

    _barcodeCtrl.text = scanned;
    await _findProduct();
  }

  Future<void> _findProduct() async {
    final barcode = _barcodeCtrl.text.trim();
    if (barcode.isEmpty) {
      setState(() {
        _message = "Enter a barcode";
        _product = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
      _product = null;
    });

    try {
      final product = await _storefrontApiService.fetchProductByBarcode(
        mallId: widget.mallId,
        barcode: barcode,
      );
      setState(() {
        _product = product;
        _message = null;
      });
    } catch (e) {
      setState(() => _message = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _product;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[900]!,
              Colors.grey[800]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern AppBar
              _buildModernAppBar(context),
              
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'Scan Items',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter barcode or scan to find products',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Barcode Input with Camera Button
                      _buildBarcodeInputSection(),
                      const SizedBox(height: 20),

                      // Browse Products Button
                      _buildBrowseButton(),
                      const SizedBox(height: 16),

                      // Find Product Button
                      _buildFindProductButton(),
                      const SizedBox(height: 24),

                      // Message Display
                      if (_message != null) _buildMessageWidget(),

                      // Product Card with Modern Design
                      if (p != null) ...[
                        _buildProductCard(p),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build modern AppBar with gradient
  Widget _buildModernAppBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[850]!,
            Colors.grey[900]!,
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.cyan.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.store, color: Colors.cyan),
                    const SizedBox(width: 8),
                    Text(
                      widget.mallId,
                      style: const TextStyle(
                        color: Colors.cyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                _buildIconButton(
                  icon: Icons.document_scanner_outlined,
                  onPress: _scanBarcode,
                  tooltip: 'Scan',
                ),
                _buildIconButton(
                  icon: Icons.search_outlined,
                  onPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductSearchScreen(mallId: widget.mallId),
                      ),
                    );
                  },
                  tooltip: 'Search',
                ),
                _buildCartIconButton(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build barcode input with camera button
  Widget _buildBarcodeInputSection() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.cyan.withOpacity(0.4),
                width: 2,
              ),
              color: Colors.grey[850]?.withOpacity(0.5),
            ),
            child: TextField(
              controller: _barcodeCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              onSubmitted: (_) => _findProduct(),
              decoration: InputDecoration(
                labelText: 'Barcode',
                labelStyle: TextStyle(color: Colors.cyan.withOpacity(0.7)),
                hintText: 'Enter or scan barcode',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                suffixIcon: _barcodeCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.cyan),
                        onPressed: () {
                          _barcodeCtrl.clear();
                          setState(() {
                            _product = null;
                            _message = null;
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.cyan.withOpacity(0.8),
                Colors.blue.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _scanBarcode,
              borderRadius: BorderRadius.circular(14),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.photo_camera, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build browse products button
  Widget _buildBrowseButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.3),
            Colors.purple.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.blue.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductSearchScreen(mallId: widget.mallId),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.manage_search, color: Colors.cyan),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Browse Products',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Search & Filter by category',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward, color: Colors.cyan.withOpacity(0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build find product button with loading state
  Widget _buildFindProductButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: _loading
            ? LinearGradient(
                colors: [
                  Colors.grey[700]!,
                  Colors.grey[600]!,
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.greenAccent.withOpacity(0.8),
                  Colors.cyan.withOpacity(0.6),
                ],
              ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: _loading
            ? []
            : [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loading ? null : _findProduct,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _loading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Finding Product...',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Find Product',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build message widget with better styling
  Widget _buildMessageWidget() {
    final isError = _message!.toLowerCase().contains('not found') ||
        _message!.toLowerCase().contains('error');

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isError
              ? [
                  Colors.red.withOpacity(0.2),
                  Colors.orange.withOpacity(0.1),
                ]
              : [
                  Colors.yellowAccent.withOpacity(0.2),
                  Colors.amber.withOpacity(0.1),
                ],
        ),
        border: Border.all(
          color: isError
              ? Colors.red.withOpacity(0.4)
              : Colors.amber.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            color: isError ? Colors.red : Colors.amber,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _message!,
              style: TextStyle(
                color: isError ? Colors.red.shade200 : Colors.amber.shade200,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build modern product card
  Widget _buildProductCard(MallProduct p) {
    final price = p.price.round();
    final unit = p.unit;
    final name = p.name;
    final brand = p.brand;
    final stock = p.stock;
    final imageUrl = p.imageUrl.trim();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[850]!.withOpacity(0.8),
            Colors.grey[900]!.withOpacity(0.8),
          ],
        ),
        border: Border.all(
          color: Colors.greenAccent.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.black.withOpacity(0.2),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white70,
                        size: 34,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Product Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      brand,
                      style: TextStyle(
                        color: Colors.cyan.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.greenAccent.withOpacity(0.3),
                      Colors.cyan.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  '✓ Found',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Product Details Grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[900]?.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailColumn('Price', '₹$price', Colors.greenAccent),
                _buildDivider(),
                _buildDetailColumn('Unit', unit, Colors.cyan),
                _buildDivider(),
                _buildDetailColumn('Stock', '$stock', Colors.orangeAccent),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Add to Cart Button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.greenAccent.withOpacity(0.9),
                  Colors.cyan.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _addToCart(context, p),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.white),
                      const SizedBox(width: 12),
                      const Text(
                        'Add to Cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper: Detail Column
  Widget _buildDetailColumn(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white60,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// Helper: Divider
  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }

  /// Helper: Icon Button
  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPress,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPress,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.cyan, size: 22),
          ),
        ),
      ),
    );
  }

  /// Helper: Cart Icon Button with Badge
  Widget _buildCartIconButton(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final count = cart.totalItemsCount;
        return Stack(
          alignment: Alignment.center,
          children: [
            Tooltip(
              message: 'Cart',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CartScreen(mallId: widget.mallId),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.shopping_cart, color: Colors.cyan, size: 22),
                  ),
                ),
              ),
            ),
            if (count > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Add to cart helper
  void _addToCart(BuildContext context, MallProduct p) {
    final cart = context.read<CartProvider>();
    final item = CartItem(
      productId: p.productId,
      name: p.name,
      barcode: p.barcode,
      price: p.price.round(),
      unit: p.unit,
    );
    cart.addOrIncrement(item);

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('${item.name} added to cart')),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    // Optional: Clear input for next scan
    _barcodeCtrl.clear();
    setState(() {
      _product = null;
      _message = null;
    });
  }
}
