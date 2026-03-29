import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  // Keyed by barcode
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  int get total => _items.values.fold(0, (sum, item) => sum + item.lineTotal);

  int get totalItemsCount =>
      _items.values.fold(0, (sum, item) => sum + item.qty);

  void addOrIncrement(CartItem item) {
    if (_items.containsKey(item.barcode)) {
      _items[item.barcode]!.qty += 1;
    } else {
      _items[item.barcode] = item;
    }
    notifyListeners();
  }

  void increment(String barcode) {
    final item = _items[barcode];
    if (item == null) return;
    item.qty += 1;
    notifyListeners();
  }

  void decrement(String barcode) {
    final item = _items[barcode];
    if (item == null) return;

    item.qty -= 1;
    if (item.qty <= 0) _items.remove(barcode);
    notifyListeners();
  }

  void remove(String barcode) {
    _items.remove(barcode);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
