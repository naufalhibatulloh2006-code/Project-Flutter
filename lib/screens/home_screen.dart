import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/product_providers.dart';

// ==================== HALAMAN DETAIL PRODUK ====================
class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;
  late Product _product = widget.product;
  bool _busy = false;

  List<String> get _imageList {
    List<String> list = [];
    if (_product.images != null) {
      list = List<String>.from(_product.images!);
    }
    if (list.isEmpty && (_product.thumbnail ?? '').isNotEmpty) {
      list.add(_product.thumbnail!);
    }
    if (list.isEmpty) {
      list.add('');
    }
    return list;
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ---------- EDIT ----------
  Future<void> _edit() async {
    final provider = context.read<ProductProvider>();
    if (provider.categoryList.isEmpty) {
      await provider.fetchCategories();
    }
    if (!mounted) return;

    final updated = await showDialog<Product>(
      context: context,
      builder: (_) => _EditProductDialog(
        product: _product,
        categories: provider.categoryList,
      ),
    );
    if (updated == null || !mounted) return;

    setState(() => _busy = true);
    final success = await provider.updateProduct(_product.id!, updated);
    if (!mounted) return;
    setState(() => _busy = false);

    if (success) {
      final fresh = provider.product.where((p) => p.id == _product.id);
      setState(() {
        _product = fresh.isNotEmpty ? fresh.first : updated;
        _currentImageIndex = 0;
      });
      _showMessage('Produk berhasil diperbarui');
    } else {
      _showMessage('Gagal memperbarui produk: ${provider.error ?? '-'}');
    }
  }

  // ---------- HAPUS ----------
  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin ingin menghapus "${_product.title ?? ''}"?'),
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
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final success = await provider.deleteProduct(_product.id!);
    if (!mounted) return;
    setState(() => _busy = false);

    if (success) {
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Produk berhasil dihapus')),
      );
    } else {
      _showMessage('Gagal menghapus produk: ${provider.error ?? '-'}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = _imageList;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          _product.title ?? 'Detail Produk',
          style: const TextStyle(fontSize: 16, color: Color(0xFF2C3E50)),
        ),
        backgroundColor: const Color(0xFFD6E2EC),
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== IMAGE SLIDER ====================
            Container(
              height: 280,
              width: double.infinity,
              color: const Color(0xFFE9EEF4),
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        images[index],
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                      );
                    },
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: images.asMap().entries.map((entry) {
                          return Container(
                            width: _currentImageIndex == entry.key ? 20 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _currentImageIndex == entry.key
                                  ? const Color(0xFF5C7AEA)
                                  : const Color(0xFFBAC8E0),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _product.title ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${_product.price ?? 0}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5C7AEA),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kategori: ${_product.category ?? '-'}  •  Stok: ${_product.stock ?? 0}  •  Merek: ${(_product.brand ?? '').isEmpty ? '-' : _product.brand}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5A6B7C),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFD0DCE5)),
                  const SizedBox(height: 16),
                  const Text(
                    'Deskripsi Produk',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (_product.description ?? '').isEmpty
                        ? 'Tidak ada deskripsi untuk produk ini.'
                        : _product.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5A6B7C),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ==================== EDIT & HAPUS ====================
                  if (_busy)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5C7AEA),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _edit,
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit Produk'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2C3E50),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _delete,
                            icon: const Icon(Icons.delete, size: 18),
                            label: const Text('Hapus Produk'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== DIALOG EDIT PRODUK ====================
/// Mengembalikan Product yang sudah diubah, atau null jika dibatalkan.
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

// ==================== HALAMAN UTAMA (HOME SCREEN) ====================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSort = 'Default';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      productProvider.fetchProduct();
      productProvider.fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    List<String> categories = ['ALL', ...productProvider.categoryList];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFD6E2EC),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF5C7AEA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shopping_bag,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Store App',
                  style: TextStyle(
                    color: Color(0xFF2C3E50),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Koleksi Produk Pilihan',
                  style: TextStyle(color: Color(0xFF5A6B7C), fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.shopping_bag_outlined,
              color: Color(0xFF2C3E50),
              size: 20,
            ),
            onPressed: () {},
          ),
        ],
      ),

      // ==================== TOMBOL TAMBAH PRODUK ====================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add'),
        backgroundColor: const Color(0xFF5C7AEA),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            color: const Color(0xFFD6E2EC),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cari produk, merek, atau kategori...',
                  hintStyle: TextStyle(
                    color: const Color(0xFF2C3E50).withOpacity(0.5),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: const Color(0xFF2C3E50).withOpacity(0.7),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Color(0xFF2C3E50),
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                            productProvider.searchProducts('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
                onChanged: (query) {
                  setState(() {});
                  productProvider.searchProducts(query);
                },
              ),
            ),
          ),

          // Header Kategori & Sort Dropdown
          Container(
            color: const Color(0xFFE5ECF2),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kategori',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBAC8E0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSort,
                      icon: const Icon(
                        Icons.swap_vert_rounded,
                        size: 14,
                        color: Color(0xFF5C7AEA),
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                      onChanged: (String? newValue) {
                        if (newValue == null) return;
                        setState(() {
                          _selectedSort = newValue;
                        });
                        if (newValue == 'Termurah') {
                          productProvider.sortProducts('price', 'asc');
                        } else if (newValue == 'Termahal') {
                          productProvider.sortProducts('price', 'desc');
                        } else {
                          productProvider.fetchProduct();
                        }
                      },
                      items: <String>['Default', 'Termurah', 'Termahal']
                          .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text('Harga: $value'),
                            );
                          })
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Category List
          Container(
            color: const Color(0xFFE5ECF2),
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected =
                    (productProvider.selectedCategory == category) ||
                    (category == 'ALL' &&
                        productProvider.selectedCategory.isEmpty);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 4.0,
                  ),
                  child: ChoiceChip(
                    label: Text(category.toUpperCase()),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF2C3E50),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF5C7AEA),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : const Color(0xFFBAC8E0),
                      ),
                    ),
                    onSelected: (bool selected) {
                      setState(() => _selectedSort = 'Default');
                      if (category == 'ALL') {
                        productProvider.fetchProduct();
                      } else if (selected) {
                        productProvider.filterByCategory(category);
                      }
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Section Header "Daftar Produk"
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Produk',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  '${productProvider.product.length} item',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5C7AEA),
                  ),
                ),
              ],
            ),
          ),

          // Grid View Produk
          Expanded(
            child: productProvider.loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF5C7AEA)),
                  )
                : productProvider.product.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            productProvider.error != null
                                ? 'Gagal memuat data'
                                : 'Produk tidak ditemukan',
                            style: const TextStyle(
                              color: Color(0xFF7F8C8D),
                              fontSize: 15,
                            ),
                          ),
                          if (productProvider.error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              productProvider.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                productProvider.fetchProduct();
                                productProvider.fetchCategories();
                              },
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: productProvider.product.length,
                    itemBuilder: (context, index) {
                      final product = productProvider.product[index];

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD6E2EC)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      child: Container(
                                        color: const Color(0xFFF0F4F8),
                                        width: double.infinity,
                                        height: double.infinity,
                                        child: Image.network(
                                          product.thumbnail ?? '',
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Center(
                                                    child: Icon(
                                                      Icons.image_outlined,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2C3E50)
                                              .withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 10,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${product.rating ?? 4.0}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (product.category ?? '')
                                                .toString()
                                                .toUpperCase(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF5C7AEA),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            product.title ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                              color: Color(0xFF2C3E50),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '\$${product.price ?? 0}',
                                            style: const TextStyle(
                                              color: Color(0xFF5C7AEA),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '${product.title} ditambahkan ke keranjang!',
                                                  ),
                                                  duration: const Duration(
                                                    seconds: 1,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF5C7AEA),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.add,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
