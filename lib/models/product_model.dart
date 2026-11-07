// product_model.dart
import '../models/product_model.dart';

import 'dart:convert';

// ---------- Helper parsing yang toleran terhadap format API ----------

/// Jika nilai berupa String JSON ("[...]" atau "{...}"), decode dulu.
dynamic _decodeIfString(dynamic v) {
  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) return null;
    try {
      return jsonDecode(s);
    } catch (_) {
      return v;
    }
  }
  return v;
}

/// Ambil nilai dari beberapa kemungkinan nama key (camelCase / snake_case).
dynamic _pick(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    if (json[k] != null) return json[k];
  }
  return null;
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? double.tryParse(v.toString())?.toInt();
}

List<String>? _toStringList(dynamic v) {
  final d = _decodeIfString(v);
  if (d is List) return d.map((e) => e.toString()).toList();
  return null;
}

Map<String, dynamic>? _toMap(dynamic v) {
  final d = _decodeIfString(v);
  if (d is Map) return Map<String, dynamic>.from(d);
  return null;
}

// ---------- Models ----------

class ProductResponse {
  List<Product>? products;
  int? total;
  int? skip;
  int? limit;

  ProductResponse({this.products, this.total, this.skip, this.limit});

  ProductResponse.fromJson(Map<String, dynamic> json) {
    final list = json['products'];
    if (list is List) {
      products = <Product>[];
      for (final v in list) {
        try {
          products!.add(Product.fromJson(Map<String, dynamic>.from(v)));
        } catch (e) {
          // Satu produk rusak tidak boleh menggagalkan seluruh daftar.
          // ignore: avoid_print
          print('Gagal parse produk: $e');
        }
      }
    }
    total = _toInt(json['total']);
    skip = _toInt(json['skip']);
    limit = _toInt(json['limit']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (products != null) {
      data['products'] = products!.map((v) => v.toJson()).toList();
    }
    data['total'] = total;
    data['skip'] = skip;
    data['limit'] = limit;
    return data;
  }
}

class Product {
  int? id;
  String? title;
  String? description;
  String? category;
  double? price;
  double? discountPercentage;
  double? rating;
  int? stock;
  List<String>? tags;
  String? brand;
  String? sku;
  int? weight;
  Dimensions? dimensions;
  String? warrantyInformation;
  String? shippingInformation;
  String? availabilityStatus;
  List<Reviews>? reviews;
  String? returnPolicy;
  int? minimumOrderQuantity;
  Meta? meta;
  List<String>? images;
  String? thumbnail;

  Product({
    this.id,
    this.title,
    this.description,
    this.category,
    this.price,
    this.discountPercentage,
    this.rating,
    this.stock,
    this.tags,
    this.brand,
    this.sku,
    this.weight,
    this.dimensions,
    this.warrantyInformation,
    this.shippingInformation,
    this.availabilityStatus,
    this.reviews,
    this.returnPolicy,
    this.minimumOrderQuantity,
    this.meta,
    this.images,
    this.thumbnail,
  });

  Product copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    double? price,
    double? discountPercentage,
    double? rating,
    int? stock,
    List<String>? tags,
    String? brand,
    String? sku,
    int? weight,
    Dimensions? dimensions,
    String? warrantyInformation,
    String? shippingInformation,
    String? availabilityStatus,
    List<Reviews>? reviews,
    String? returnPolicy,
    int? minimumOrderQuantity,
    Meta? meta,
    List<String>? images,
    String? thumbnail,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      rating: rating ?? this.rating,
      stock: stock ?? this.stock,
      tags: tags ?? this.tags,
      brand: brand ?? this.brand,
      sku: sku ?? this.sku,
      weight: weight ?? this.weight,
      dimensions: dimensions ?? this.dimensions,
      warrantyInformation: warrantyInformation ?? this.warrantyInformation,
      shippingInformation: shippingInformation ?? this.shippingInformation,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      reviews: reviews ?? this.reviews,
      returnPolicy: returnPolicy ?? this.returnPolicy,
      minimumOrderQuantity: minimumOrderQuantity ?? this.minimumOrderQuantity,
      meta: meta ?? this.meta,
      images: images ?? this.images,
      thumbnail: thumbnail ?? this.thumbnail,
    );
  }

  Product.fromJson(Map<String, dynamic> json) {
    id = _toInt(json['id']);
    title = json['title']?.toString();
    description = json['description']?.toString();
    category = json['category']?.toString();
    price = _toDouble(json['price']) ?? 0.0;
    discountPercentage =
        _toDouble(_pick(json, ['discountPercentage', 'discount_percentage'])) ??
        0.0;
    rating = _toDouble(json['rating']) ?? 0.0;
    stock = _toInt(json['stock']) ?? 0;
    tags = _toStringList(json['tags']);
    brand = json['brand']?.toString();
    sku = json['sku']?.toString();
    weight = _toInt(json['weight']);

    final dim = _toMap(json['dimensions']);
    dimensions = dim != null ? Dimensions.fromJson(dim) : null;

    warrantyInformation = _pick(json, [
      'warrantyInformation',
      'warranty_information',
    ])?.toString();
    shippingInformation = _pick(json, [
      'shippingInformation',
      'shipping_information',
    ])?.toString();
    availabilityStatus = _pick(json, [
      'availabilityStatus',
      'availability_status',
    ])?.toString();

    final rev = _decodeIfString(json['reviews']);
    if (rev is List) {
      reviews = <Reviews>[];
      for (final v in rev) {
        if (v is Map) {
          reviews!.add(Reviews.fromJson(Map<String, dynamic>.from(v)));
        }
      }
    }

    returnPolicy = _pick(json, ['returnPolicy', 'return_policy'])?.toString();
    minimumOrderQuantity =
        _toInt(
          _pick(json, ['minimumOrderQuantity', 'minimum_order_quantity']),
        ) ??
        0;

    final m = _toMap(_pick(json, ['meta', 'product_meta']));
    meta = m != null ? Meta.fromJson(m) : null;

    images = _toStringList(json['images']);
    thumbnail = json['thumbnail']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['description'] = description;
    data['category'] = category;
    data['price'] = price;
    data['discountPercentage'] = discountPercentage;
    data['rating'] = rating;
    data['stock'] = stock;
    data['tags'] = tags;
    data['brand'] = brand;
    data['sku'] = sku;
    data['weight'] = weight;
    if (dimensions != null) {
      data['dimensions'] = dimensions!.toJson();
    }
    data['warrantyInformation'] = warrantyInformation;
    data['shippingInformation'] = shippingInformation;
    data['availabilityStatus'] = availabilityStatus;
    if (reviews != null) {
      data['reviews'] = reviews!.map((v) => v.toJson()).toList();
    }
    data['returnPolicy'] = returnPolicy;
    data['minimumOrderQuantity'] = minimumOrderQuantity;
    if (meta != null) {
      data['meta'] = meta!.toJson();
    }
    data['images'] = images;
    data['thumbnail'] = thumbnail;
    return data;
  }
}

class Dimensions {
  double? width;
  double? height;
  double? depth;

  Dimensions({this.width, this.height, this.depth});

  Dimensions.fromJson(Map<String, dynamic> json) {
    width = _toDouble(json['width']);
    height = _toDouble(json['height']);
    depth = _toDouble(json['depth']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['width'] = width;
    data['height'] = height;
    data['depth'] = depth;
    return data;
  }
}

class Reviews {
  int? rating;
  String? comment;
  String? date;
  String? reviewerName;
  String? reviewerEmail;

  Reviews({
    this.rating,
    this.comment,
    this.date,
    this.reviewerName,
    this.reviewerEmail,
  });

  Reviews.fromJson(Map<String, dynamic> json) {
    rating = _toInt(json['rating']);
    comment = json['comment']?.toString();
    date = json['date']?.toString();
    reviewerName = json['reviewerName']?.toString();
    reviewerEmail = json['reviewerEmail']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['rating'] = rating;
    data['comment'] = comment;
    data['date'] = date;
    data['reviewerName'] = reviewerName;
    data['reviewerEmail'] = reviewerEmail;
    return data;
  }
}

class Meta {
  String? createdAt;
  String? updatedAt;
  String? barcode;
  String? qrCode;

  Meta({this.createdAt, this.updatedAt, this.barcode, this.qrCode});

  Meta.fromJson(Map<String, dynamic> json) {
    createdAt = json['createdAt']?.toString();
    updatedAt = json['updatedAt']?.toString();
    barcode = json['barcode']?.toString();
    qrCode = json['qrCode']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['barcode'] = barcode;
    data['qrCode'] = qrCode;
    return data;
  }
}
