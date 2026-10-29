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
      _products = res.product ?? [];
      _total = res.total ?? 0;
      _skip = res.skip ?? 0;
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> fetchCategories() async {
    try {
      _categoryList = await _api.getCategoryList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) return fetchProduct();

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.searchProducts(query);
      _products = res.product ?? [];
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
      _products = res.product ?? [];
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
      _products = res.product ?? [];
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
}
