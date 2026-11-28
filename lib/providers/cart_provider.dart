import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vegetables_app/feature/cart/model/cart_item_model.dart';
import 'package:vegetables_app/model/vegetable_model/vegetable_model.dart';

class CartProvider extends ChangeNotifier {
  static const String _storageKey = 'shopping_cart_items';
  final SharedPreferences _prefs;

  CartProvider(this._prefs);

  List<CartItemModel> _items = const [];

  List<CartItemModel> get items => List.unmodifiable(_items);

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  int get totalPrice => _items.fold(0, (sum, item) => sum + item.subtotal);

  void loadCart() {
    try {
      final raw = _prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        _items = decoded
            .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  void addItem(VegetableModel vegetable, {int quantity = 1}) {
    final current = List<CartItemModel>.from(_items);
    final index = current.indexWhere((c) => c.vegetable.id == vegetable.id);

    if (index >= 0) {
      current[index].quantity += quantity;
    } else {
      current.add(CartItemModel(vegetable: vegetable, quantity: quantity));
    }

    _items = current;
    notifyListeners();
    _saveToStorage(current);
  }

  void updateQuantity(int vegetableId, int quantity) {
    final current = List<CartItemModel>.from(_items);
    final index = current.indexWhere((c) => c.vegetable.id == vegetableId);

    if (index >= 0) {
      if (quantity <= 0) {
        current.removeAt(index);
      } else {
        current[index].quantity = quantity;
      }
      _items = current;
      notifyListeners();
      _saveToStorage(current);
    }
  }

  void removeItem(int vegetableId) {
    final current = List<CartItemModel>.from(_items);
    current.removeWhere((c) => c.vegetable.id == vegetableId);
    _items = current;
    notifyListeners();
    _saveToStorage(current);
  }

  void clearCart() {
    _items = const [];
    notifyListeners();
    _saveToStorage(const []);
  }

  Future<void> _saveToStorage(List<CartItemModel> items) async {
    try {
      final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
      await _prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }
}
