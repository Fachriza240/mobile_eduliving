import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item_model.dart';
import '../models/marketplace_model.dart';

class CartProvider extends ChangeNotifier {
  static const String _cartKey = 'user_marketplace_cart';
  List<CartItemModel> _items = [];

  List<CartItemModel> get items => _items;

  int get itemCount => _items.length;

  double get totalPrice {
    double total = 0;
    for (var item in _items) {
      total += item.product.price * item.quantity;
    }
    return total;
  }

  CartProvider() {
    _loadCart();
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartString = prefs.getString(_cartKey);
    if (cartString != null) {
      try {
        final List<dynamic> decodedList = jsonDecode(cartString);
        _items = decodedList.map((item) => CartItemModel.fromJson(item)).toList();
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading cart: $e');
      }
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_cartKey, encodedList);
    notifyListeners();
  }

  void addItem(MarketplaceProductModel product) {
    // Check if product already in cart
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      // Increase qty if not exceeding stock
      if (_items[index].quantity < product.stockQuantity) {
        _items[index].quantity++;
      }
    } else {
      _items.add(CartItemModel(product: product, quantity: 1));
    }
    _saveCart();
  }

  void updateQuantity(int productId, int quantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        // Ensure not exceeding stock
        final stock = _items[index].product.stockQuantity;
        _items[index].quantity = quantity > stock ? stock : quantity;
      }
      _saveCart();
    }
  }

  void removeItem(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _saveCart();
  }

  void clearCart() {
    _items.clear();
    _saveCart();
  }
}
