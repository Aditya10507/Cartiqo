import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../models/mall_product.dart';
import '../providers/cart_provider.dart';
import '../services/storefront_api_service.dart';
import 'barcode_scanner_screen.dart';
import 'cart_screen.dart';
import 'product_search_screen.dart';
import 'product_text_match_screen.dart';

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
    if (scanned == null || !mounted) {
      return;
    }

    _barcodeCtrl.text = scanned;
    await _findProduct();
  }

  Future<void> _findByPackText() async {
    final matchedProduct = await Navigator.push<MallProduct>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductTextMatchScreen(mallId: widget.mallId),
      ),
    );

    if (matchedProduct == null) {
      return;
    }

    setState(() {
      _product = matchedProduct;
      _barcodeCtrl.text = matchedProduct.barcode;
      _message = 'Recommended product added to cart.';
    });
  }

  Future<void> _findProduct() async {
    final barcode = _barcodeCtrl.text.trim();
    if (barcode.isEmpty) {
      setState(() {
        _message = 'Enter a barcode';
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
      setState(() {
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Scan Items'),
        actions: [
          IconButton(
            onPressed: _scanBarcode,
            icon: const Icon(Icons.qr_code_scanner_outlined),
            tooltip: 'Scan barcode',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductSearchScreen(mallId: widget.mallId),
                ),
              );
            },
            icon: const Icon(Icons.search_outlined),
            tooltip: 'Browse products',
          ),
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              final count = cart.totalItemsCount;
              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CartScreen(mallId: widget.mallId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart_outlined),
                    tooltip: 'Cart',
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.mallId,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Enter Barcode',
                child: Column(
                  children: [
                    TextField(
                      controller: _barcodeCtrl,
                      keyboardType: TextInputType.number,
                      onSubmitted: (_) => _findProduct(),
                      decoration: InputDecoration(
                        labelText: 'Barcode',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        suffixIcon: _barcodeCtrl.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _barcodeCtrl.clear();
                                  setState(() {
                                    _message = null;
                                    _product = null;
                                  });
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _loading ? null : _findProduct,
                        child: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Find Product'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildSection(
                title: 'Scan Barcode',
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _scanBarcode,
                    icon: const Icon(Icons.qr_code_scanner_outlined),
                    label: const Text('Open Scanner'),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _buildSection(
                title: 'Capture Product',
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _findByPackText,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Open Camera'),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _buildSection(
                title: 'Browse Products',
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProductSearchScreen(mallId: widget.mallId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.search_outlined),
                    label: const Text('Browse'),
                  ),
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE4E7EC)),
                  ),
                  child: Text(_message!),
                ),
              ],
              if (product != null) ...[
                const SizedBox(height: 16),
                _buildProductCard(product),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildProductCard(MallProduct product) {
    final cartQty = context.watch<CartProvider>().quantityFor(product.barcode);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.imageUrl.trim().isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFF2F4F7),
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
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
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.brand,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
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
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Found',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailColumn('Price', 'Rs ${product.price.round()}'),
                _buildDivider(),
                _buildDetailColumn('Unit', product.unit),
                _buildDivider(),
                _buildDetailColumn('Stock', '${product.stock}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 420;
              final addButton = SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _addToCart(context, product),
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('Add to Cart'),
                ),
              );

              final quantityBox = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE4E7EC)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: cartQty > 0
                          ? () => context
                              .read<CartProvider>()
                              .decrement(product.barcode)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '$cartQty',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          _addToCart(context, product, showMessage: false),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    addButton,
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: quantityBox,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: addButton),
                  const SizedBox(width: 12),
                  quantityBox,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 28,
      width: 1,
      color: const Color(0xFFE4E7EC),
    );
  }

  void _addToCart(BuildContext context, MallProduct product,
      {bool showMessage = true}) {
    final item = CartItem(
      productId: product.productId,
      name: product.name,
      barcode: product.barcode,
      price: product.price.round(),
      unit: product.unit,
      imageUrl: product.imageUrl,
    );

    context.read<CartProvider>().addOrIncrement(item);

    if (showMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} added to cart'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
