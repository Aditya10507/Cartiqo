import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import 'checkout_flow_screen.dart';
import '../widgets/swiftcart_logo.dart';

class CartScreen extends StatelessWidget {
  final String mallId;

  const CartScreen({super.key, required this.mallId});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4FBFF), Color(0xFFEAF1FF), Color(0xFFF8F0FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    const SwiftCartLogo(
                      size: 44,
                      showWordmark: false,
                      primaryColor: Color(0xFF0B5ED7),
                      accentColor: Color(0xFF12B886),
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Cart',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Review items before checkout',
                            style: TextStyle(color: Color(0xFF607089)),
                          ),
                        ],
                      ),
                    ),
                    if (items.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => cart.clear(),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Clear'),
                      ),
                  ],
                ),
              ),
              if (items.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shopping_bag_outlined, size: 56),
                              SizedBox(height: 14),
                              Text(
                                'Cart is empty',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Scan products to start building your bill.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    children: [
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Color(0xFFE8F2FF),
                                child: Icon(Icons.receipt_long,
                                    color: Color(0xFF0B5ED7)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${items.length} item${items.length == 1 ? '' : 's'} in cart',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap checkout when you are ready to review payment.',
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                              Chip(
                                label: Text('Rs ${cart.total}'),
                                backgroundColor: const Color(0xFFEAF9F2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: SizedBox(
                                          width: 52,
                                          height: 52,
                                          child: item.imageUrl.trim().isEmpty
                                              ? Container(
                                                  color: const Color(0xFFE8F2FF),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    item.name.isEmpty
                                                        ? 'P'
                                                        : item.name[0].toUpperCase(),
                                                    style: const TextStyle(
                                                      color: Color(0xFF0B5ED7),
                                                      fontWeight: FontWeight.w900,
                                                    ),
                                                  ),
                                                )
                                              : Image.network(
                                                  item.imageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    return Container(
                                                      color: const Color(0xFFE8F2FF),
                                                      alignment: Alignment.center,
                                                      child: Text(
                                                        item.name.isEmpty
                                                            ? 'P'
                                                            : item.name[0].toUpperCase(),
                                                        style: const TextStyle(
                                                          color: Color(0xFF0B5ED7),
                                                          fontWeight: FontWeight.w900,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Rs ${item.price} • ${item.unit}',
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        'Rs ${item.lineTotal}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Barcode: ${item.barcode}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF4F7FB),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Row(
                                          children: [
                                            IconButton(
                                              onPressed: () =>
                                                  cart.decrement(item.barcode),
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                              ),
                                            ),
                                            Text(
                                              '${item.qty}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () =>
                                                  cart.increment(item.barcode),
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => cart.remove(item.barcode),
                                      icon: const Icon(Icons.delete_outline),
                                      label: const Text('Remove'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 84),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 10,
            shadowColor: const Color(0x220B5ED7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rs ${cart.total}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: items.isEmpty
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CheckoutReviewScreen(
                                  mallId: mallId,
                                ),
                              ),
                            );
                          },
                    child: const Text('Checkout'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
