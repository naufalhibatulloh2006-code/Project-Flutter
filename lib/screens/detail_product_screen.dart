import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/product_providers.dart';
import '../services/api_services_product.dart';

class DetailProductScreen extends StatefulWidget {
  final int productId;
  const DetailProductScreen({super.key, required this.productId});

  @override
  State<DetailProductScreen> createState() => _DetailProductScreenState();
}

class _DetailProductScreenState extends State<DetailProductScreen> {
  final ApiServiceProducts _api = ApiServiceProducts();
  late Future<Product> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _api.getProduct(widget.productId);
  }

  void _reload() {
    setState(() {
      _future = _api.getProduct(widget.productId);
    });
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _edit(Product product) async {
    final provider = context.read<ProductProvider>();
    if (provider.categoryList.isEmpty) {
      await provider.fetchCategories();
    }
    if (!mounted) return;

    final updated = await showDialog<Product>(
      context: context,
      builder: (_) => _EditProductDialog(
        product: product,
        categories: provider.categoryList,
      ),
    );
    if (updated == null || !mounted) return;

    setState(() => _busy = true);
    final success = await provider.updateProduct(widget.productId, updated);
    if (!mounted) return;
    setState(() => _busy = false);

    if (success) {
      _showMessage('Produk berhasil diperbarui');
      _reload();
    } else {
      _showMessage('Gagal memperbarui produk: ${provider.error ?? '-'}');
    }
  }

  Future<void> _delete(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin ingin menghapus "${product.title ?? ''}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final provider = context.read<ProductProvider>();
    setState(() => _busy = true);
    final success = await provider.deleteProduct(widget.productId);
    if (!mounted) return;
    setState(() => _busy = false);

    if (success) {
      _showMessage('Produk berhasil dihapus');
      context.go('/');
    } else {
      _showMessage('Gagal menghapus produk: ${provider.error ?? '-'}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Produk')),
      body: FutureBuilder<Product>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Produk tidak ditemukan'));
          }

          final product = snapshot.data!;
          final thumbnail = product.thumbnail ?? '';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                if (thumbnail.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: thumbnail,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  )
                else
                  const SizedBox(
                    height: 200,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  product.title ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kategori: ${product.category}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'Harga: \$${product.price}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Brand: ${product.brand}'),
                Text('Stok: ${product.stock}'),
                Text('Rating: ${product.rating} ⭐'),
                const SizedBox(height: 16),
                const Text(
                  'Deskripsi:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(product.description ?? ''),
                const SizedBox(height: 24),
                if (_busy)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _edit(product),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _delete(product),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.red,
                          ),
                          icon: const Icon(Icons.delete),
                          label: const Text('Hapus'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Dialog form untuk mengedit produk. Mengembalikan Product yang sudah diubah
/// (atau null jika dibatalkan).
class _EditProductDialog extends StatefulWidget {
  final Product product;
  final List<String> categories;

  const _EditProductDialog({required this.product, required this.categories});

  @override
  State<_EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<_EditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late final TextEditingController _stock;
  late final TextEditingController _brand;
  late final TextEditingController _thumbnail;
  late final TextEditingController _categoryText;
  String? _category;

  late final List<String> _categoryOptions;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _title = TextEditingController(text: p.title ?? '');
    _price = TextEditingController(text: (p.price ?? 0).toString());
    _description = TextEditingController(text: p.description ?? '');
    _stock = TextEditingController(text: (p.stock ?? 0).toString());
    _brand = TextEditingController(text: p.brand ?? '');
    _thumbnail = TextEditingController(text: p.thumbnail ?? '');
    _categoryText = TextEditingController(text: p.category ?? '');

    // Pastikan kategori produk saat ini selalu ada di pilihan dropdown.
    final options = List<String>.from(widget.categories);
    final current = p.category ?? '';
    if (current.isNotEmpty && !options.contains(current)) {
      options.insert(0, current);
    }
    _categoryOptions = options;
    _category = current.isNotEmpty ? current : null;
  }

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _description.dispose();
    _stock.dispose();
    _brand.dispose();
    _thumbnail.dispose();
    _categoryText.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Tidak boleh kosong' : null;

  double? _parsePrice(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final category = _categoryOptions.isNotEmpty
        ? (_category ?? '')
        : _categoryText.text.trim();

    final updated = widget.product.copyWith(
      title: _title.text.trim(),
      price: _parsePrice(_price.text) ?? 0.0,
      category: category,
      description: _description.text.trim(),
      stock: int.tryParse(_stock.text.trim()) ?? 0,
      brand: _brand.text.trim(),
      thumbnail: _thumbnail.text.trim(),
    );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Produk'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Judul Produk *',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _price,
                  decoration: const InputDecoration(labelText: 'Harga *'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Tidak boleh kosong';
                    }
                    final price = _parsePrice(v);
                    if (price == null || price < 0) {
                      return 'Masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                if (_categoryOptions.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Kategori *'),
                    items: _categoryOptions
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v),
                    validator: (v) =>
                        v == null ? 'Pilih salah satu kategori' : null,
                  )
                else
                  TextFormField(
                    controller: _categoryText,
                    decoration: const InputDecoration(labelText: 'Kategori *'),
                    validator: _required,
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stock,
                  decoration: const InputDecoration(labelText: 'Stok'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    return int.tryParse(v.trim()) == null
                        ? 'Masukkan bilangan bulat'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _brand,
                  decoration: const InputDecoration(labelText: 'Merek'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _thumbnail,
                  decoration: const InputDecoration(labelText: 'URL Gambar'),
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Simpan')),
      ],
    );
  }
}
