import 'package:dio/dio.dart';

import '../models/product_model.dart';

class ApiServiceProducts {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://dummyjson.com',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // 1. GET ALL PRODUCTS
  Future<ProductResponse> getAllProducts({int limit = 30, int skip = 0}) async {
    final res = await _dio.get(
      '/products',
      queryParameters: {'limit': limit, 'skip': skip},
    );
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
    return (res.data as List).map((e) => e.toString()).toList();
  }

  // 8. GET PRODUCTS BY CATEGORY
  Future<ProductResponse> getProductsByCategory(String category) async {
    final res = await _dio.get('/products/category/$category');
    return ProductResponse.fromJson(res.data);
  }

  // 9. ADD PRODUCT (POST)
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
