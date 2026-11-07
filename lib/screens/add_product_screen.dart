import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/product_providers.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stockController = TextEditingController();
  final _brandController = TextEditingController();
  final _thumbnailController = TextEditingController();
  final _categoryController = TextEditingController();

  String? _selectedCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pastikan daftar kategori sudah dimuat untuk dropdown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      if (provider.categoryList.isEmpty) {
        provider.fetchCategories();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _brandController.dispose();
    _thumbnailController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  double? _parsePrice(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final categories = context.read<ProductProvider>().categoryList;
    final category = categories.isNotEmpty
        ? (_selectedCategory ?? '')
        : _categoryController.text.trim();

    final data = <String, dynamic>{
      'title': _titleController.text.trim(),
      'price': _parsePrice(_priceController.text) ?? 0.0,
      'category': category,
      'description': _descriptionController.text.trim(),
      'stock': int.tryParse(_stockController.text.trim()) ?? 0,
      'brand': _brandController.text.trim(),
      'thumbnail': _thumbnailController.text.trim(),
    };

    setState(() => _isLoading = true);
    final provider = context.read<ProductProvider>();
    final success = await provider.addProduct(data);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk berhasil ditambahkan')),
      );
      context.go('/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambah produk: ${provider.error ?? '-'}'),
        ),
      );
    }
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Tidak boleh kosong' : null;

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ProductProvider>().categoryList;

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Produk')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul Produk *'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Harga * (Contoh: 9.99)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tidak boleh kosong';
                  }
                  final price = _parsePrice(value);
                  if (price == null || price < 0) {
                    return 'Masukkan angka yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (categories.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Kategori *'),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value),
                  validator: (value) =>
                      value == null ? 'Pilih salah satu kategori' : null,
                )
              else
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Kategori * (Contoh: beauty)',
                  ),
                  validator: _required,
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stok'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  return int.tryParse(value.trim()) == null
                      ? 'Masukkan bilangan bulat'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: 'Merek'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _thumbnailController,
                decoration: const InputDecoration(
                  labelText: 'URL Gambar (opsional)',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Simpan Produk'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
