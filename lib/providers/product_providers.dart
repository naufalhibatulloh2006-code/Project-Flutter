import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/api_services_product.dart';

class ProductProvider extends ChangeNotifier {
  final ApiServiceProducts _api = ApiServiceProducts();

  List<Product> _products = [];
  List<String> _categoryList = [];
  bool _loading = false;
  String? _error;
  int _total = 0;
  int _skip = 0;
  String _selectedCategory = '';

  List<Product> get product => _products;
  List<String> get categoryList => _categoryList;
  bool get loading => _loading;
  int get total => _total;
  int get skip => _skip; // Ditambahkan agar _skip bisa diakses jika diperlukan
  String get selectedCategory => _selectedCategory;
  String? get error => _error;

  Future<void> fetchProduct({int limit = 30, int skip = 0}) async {
    _loading = true;
    _error = null;
    _selectedCategory = '';
    notifyListeners();

    try {
      final res = await _api.getAllProducts(limit: limit, skip: skip);
      _products = res.products ?? [];
      _total = res.total ?? 0;
      _skip = res.skip ?? 0;
      if (_categoryList.isEmpty) _buildCategoriesFromProducts();
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  void _buildCategoriesFromProducts() {
    final set = <String>{};
    for (final p in _products) {
      final c = p.category;
      if (c != null && c.isNotEmpty) set.add(c);
    }
    _categoryList = set.toList()..sort();
  }

  Future<void> fetchCategories() async {
    try {
      final list = await _api.getCategoryList();
      if (list.isNotEmpty) {
        _categoryList = list;
      } else {
        _buildCategoriesFromProducts();
      }
    } catch (e) {
      debugPrint('fetchCategories gagal: $e');
      _buildCategoriesFromProducts();
    }
    notifyListeners();
  }

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) return fetchProduct();

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.searchProducts(query);
      _products = res.products ?? [];
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> filterByCategory(String category) async {
    _selectedCategory = category;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getProductsByCategory(category);
      _products = res.products ?? [];
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> sortProducts(String sortBy, String order) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.sortProducts(sortBy, order);
      _products = res.products ?? [];
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> updateProduct(int id, Product updated) async {
    _loading = true;
    _error = null;
    notifyListeners();

    bool success = false;

    try {
      final result = await _api.updateProduct(id, updated.toJson());
      int idx = _products.indexWhere((p) => p.id == id);
      if (idx != -1) {
        _products[idx] = result;
      }
      success = true; // Berhasil update
    } catch (e) {
      _error = e.toString();
      success = false; // Gagal update
    }

    _loading = false;
    notifyListeners();
    return success;
  }

  Future<bool> addProduct(Map<String, dynamic> data) async {
    _loading = true;
    _error = null;
    notifyListeners();

    bool success = false;
    try {
      final created = await _api.addProduct(data);
      _products.insert(0, created);
      _total += 1;
      success = true;
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
    return success;
  }

  Future<bool> deleteProduct(int id) async {
    _error = null;
    bool success = false;
    try {
      await _api.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      _total = _total > 0 ? _total - 1 : 0;
      success = true;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
    return success;
  }
}
