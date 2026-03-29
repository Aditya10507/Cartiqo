class MallProduct {
  final String productId;
  final String name;
  final String barcode;
  final String imageUrl;
  final String imageSourcePage;
  final double price;
  final double weight;
  final String weightUnit; // 'mg', 'g', 'kg', 'ml', 'l'
  final String unit;
  final String brand;
  final String category;
  final int stock;
  final bool inStock;

  MallProduct({
    required this.productId,
    required this.name,
    required this.barcode,
    this.imageUrl = '',
    this.imageSourcePage = '',
    required this.price,
    required this.weight,
    this.weightUnit = 'g',
    this.unit = '1 pc',
    this.brand = 'General',
    this.category = 'General',
    this.stock = 0,
    this.inStock = true,
  });

  bool get isLowStock => stock <= 5;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'barcode': barcode,
      'imageUrl': imageUrl,
      'imageSourcePage': imageSourcePage,
      'price': price,
      'weight': weight,
      'weightUnit': weightUnit,
      'unit': unit,
      'brand': brand,
      'category': category,
      'stock': stock,
      'inStock': inStock,
    };
  }

  factory MallProduct.fromMap(Map<String, dynamic> map) {
    return MallProduct(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      barcode: map['barcode'] ?? '',
      imageUrl: (map['imageUrl'] ?? '').toString(),
      imageSourcePage: (map['imageSourcePage'] ?? '').toString(),
      price: (map['price'] ?? 0.0).toDouble(),
      weight: (map['weight'] ?? 0.0).toDouble(),
      weightUnit: map['weightUnit'] ?? 'g',
      unit: map['unit'] ?? '1 pc',
      brand: map['brand'] ?? 'General',
      category: map['category'] ?? 'General',
      stock: map['stock'] ?? 0,
      inStock: map['inStock'] ?? true,
    );
  }
}
