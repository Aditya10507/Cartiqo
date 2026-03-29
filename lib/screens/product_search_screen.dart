import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../models/mall_product.dart';
import '../providers/cart_provider.dart';

class ProductSearchScreen extends StatefulWidget {
  final String mallId;

  const ProductSearchScreen({super.key, required this.mallId});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _inStockOnly = false;
  String _sortBy = 'name';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsStream = FirebaseFirestore.instance
        .collection('malls')
        .doc(widget.mallId)
        .collection('products')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: productsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data?.docs
                  .map((doc) => MallProduct.fromMap(doc.data()))
                  .toList() ??
              <MallProduct>[];

          final categories = <String>{
            'All',
            ...products
                .map((product) => product.category.trim())
                .where((category) => category.isNotEmpty),
          }.toList()
            ..sort();

          final filteredProducts = products.where((product) {
            final query = _searchQuery.trim().toLowerCase();
            final matchesSearch = query.isEmpty ||
                product.name.toLowerCase().contains(query) ||
                product.brand.toLowerCase().contains(query) ||
                product.category.toLowerCase().contains(query) ||
                product.barcode.toLowerCase().contains(query);

            final matchesCategory = _selectedCategory == 'All' ||
                product.category == _selectedCategory;

            final matchesStock = !_inStockOnly || product.inStock;

            return matchesSearch && matchesCategory && matchesStock;
          }).toList()
            ..sort(_sortProducts);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by name, brand, category or barcode',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                icon: const Icon(Icons.close),
                              ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final selected = category == _selectedCategory;
                          return ChoiceChip(
                            label: Text(category),
                            selected: selected,
                            onSelected: (_) {
                              setState(() => _selectedCategory = category);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _sortBy,
                            decoration: const InputDecoration(
                              labelText: 'Sort By',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'name',
                                child: Text('Name A-Z'),
                              ),
                              DropdownMenuItem(
                                value: 'price_low',
                                child: Text('Price Low-High'),
                              ),
                              DropdownMenuItem(
                                value: 'price_high',
                                child: Text('Price High-Low'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _sortBy = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SwitchListTile(
                            value: _inStockOnly,
                            onChanged: (value) {
                              setState(() => _inStockOnly = value);
                            },
                            title: const Text('In Stock'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredProducts.isEmpty
                    ? const Center(
                        child: Text('No products found for the current filters'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: filteredProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _SearchProductCard(product: product);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  int _sortProducts(MallProduct a, MallProduct b) {
    switch (_sortBy) {
      case 'price_low':
        return a.price.compareTo(b.price);
      case 'price_high':
        return b.price.compareTo(a.price);
      default:
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    }
  }
}

class _SearchProductCard extends StatelessWidget {
  final MallProduct product;

  const _SearchProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.brand} - ${product.category}',
                        style: TextStyle(color: Colors.grey[700]),
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
                    color:
                        product.inStock ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product.inStock ? 'In Stock' : 'Out of Stock',
                    style: TextStyle(
                      color:
                          product.inStock ? Colors.green[800] : Colors.red[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Text(
                  'Rs ${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text('Weight: ${product.weight}${product.weightUnit}'),
                Text('Stock: ${product.stock}'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Barcode: ${product.barcode}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: product.inStock
                    ? () {
                        final item = CartItem(
                          productId: product.productId,
                          name: product.name,
                          barcode: product.barcode,
                          price: product.price.round(),
                          unit: product.unit,
                        );
                        context.read<CartProvider>().addOrIncrement(item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} added to cart'),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: const Text('Add to Cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
