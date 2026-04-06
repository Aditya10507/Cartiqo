class CartItem {
  final String productId;
  final String name;
  final String barcode;
  final int price; // rupees
  final String unit;
  final String imageUrl;
  int qty;

  CartItem({
    required this.productId,
    required this.name,
    required this.barcode,
    required this.price,
    required this.unit,
    this.imageUrl = '',
    this.qty = 1,
  });

  int get lineTotal => price * qty;
}
