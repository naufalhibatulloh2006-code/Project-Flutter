import 'package:dio/dio.dart';

import '../models/product_model.dart';

import 'dart:convert';

class ApiServiceProducts {
  final Dio _dio = Dio(
    BaseOptions(
      // Diubah ke URL lokal PHP API via Caddy Docker
      baseUrl: 'http://192.168.1.10:8090',
      // Catatan: Jika menggunakan Android Emulator, gunakan 'http://10.0.2.2:8080'

      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // 1. GET ALL PRODUCTS (Mendukung limit, skip, sortBy, order)
  Future<ProductResponse> getAllProducts({
    int limit = 0,
    int skip = 0,
    String? sortBy,
    String? order,
  }) async {
    Map<String, dynamic> params = {'limit': limit, 'skip': skip};
    if (sortBy != null) params['sortBy'] = sortBy;
    if (order != null) params['order'] = order;

    final res = await _dio.get('/products', queryParameters: params);
    return ProductResponse.fromJson(res.data);
  }

  // 2. GET SINGLE PRODUCT
  Future<Product> getProduct(int id) async {
    final res = await _dio.get('/products/$id');
    return Product.fromJson(res.data);
  }

  // 3. SEARCH PRODUCTS
  Future<ProductResponse> searchProducts(String query) async {
    final res = await _dio.get(
      '/products/search',
      queryParameters: {'q': query},
    );
    return ProductResponse.fromJson(res.data);
  }

  // 4. LIMIT, SKIP, SELECT PAGINATION
  Future<ProductResponse> getProductsPaginated({
    int limit = 10,
    int skip = 0,
    String? select,
  }) async {
    Map<String, dynamic> params = {'limit': limit, 'skip': skip};
    if (select != null) params['select'] = select;
    final res = await _dio.get('/products', queryParameters: params);
    return ProductResponse.fromJson(res.data);
  }

  // 5. SORT PRODUCTS
  Future<ProductResponse> sortProducts(String sortBy, String order) async {
    final res = await _dio.get(
      '/products',
      queryParameters: {'sortBy': sortBy, 'order': order},
    );
    return ProductResponse.fromJson(res.data);
  }

  // 6. GET CATEGORIES
  Future<List<String>> getCategories() async {
    final res = await _dio.get('/products/categories');
    return (res.data as List).map((e) => e.toString()).toList();
  }

  // 7. GET CATEGORY LIST
  Future<List<String>> getCategoryList() async {
    final res = await _dio.get('/products/category-list');
    dynamic data = res.data;
    if (data is String) data = jsonDecode(data);
    if (data is Map) {
      data = data['categories'] ?? data['data'] ?? data['category_list'] ?? [];
    }
    return (data as List)
        .map((e) {
          if (e is Map) return (e['slug'] ?? e['name'] ?? '').toString();
          return e.toString();
        })
        .where((e) => e.isNotEmpty)
        .toList();
  }

  // 8. GET PRODUCTS BY CATEGORY
  Future<ProductResponse> getProductsByCategory(String category) async {
    final res = await _dio.get('/products/category/$category');
    return ProductResponse.fromJson(res.data);
  }

  // 9. ADD PRODUCT (POST) -> Sesuai endpoint /products/add di PHP API
  Future<Product> addProduct(Map<String, dynamic> data) async {
    final res = await _dio.post('/products/add', data: data);
    return Product.fromJson(res.data);
  }

  // 10. UPDATE PRODUCT (PUT)
  Future<Product> updateProduct(int id, Map<String, dynamic> data) async {
    final res = await _dio.put('/products/$id', data: data);
    return Product.fromJson(res.data);
  }

  // 11. PATCH PRODUCT
  Future<Product> patchProduct(int id, Map<String, dynamic> partialData) async {
    final res = await _dio.patch('/products/$id', data: partialData);
    return Product.fromJson(res.data);
  }

  // 12. DELETE PRODUCT
  Future<Product> deleteProduct(int id) async {
    final res = await _dio.delete('/products/$id');
    return Product.fromJson(res.data);
  }
}
