import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/confirm_dialog.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _activeTab = 'active'; // 'active' | 'archived'
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _categoryFilter = 'All';
  String _stockFilter = 'all'; // 'all' | 'in_stock' | 'low_stock' | 'out_of_stock'

  // Form Controllers
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _categoryController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedUnit = 'piece';

  Product? _editingProduct;

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _categoryController.dispose();
    _sellingPriceController.dispose();
    _costPriceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openAddProductModal(BuildContext context) {
    _editingProduct = null;
    _nameController.clear();
    _skuController.text = 'SKU-${1000 + (DateTime.now().millisecondsSinceEpoch % 9000)}';
    _barcodeController.clear();
    _categoryController.text = 'Cigarettes';
    _sellingPriceController.clear();
    _costPriceController.clear();
    _stockController.text = '10';
    _descriptionController.clear();
    _selectedUnit = 'piece';

    _showFormModal(context, isEdit: false);
  }

  void _openEditProductModal(BuildContext context, Product p) {
    _editingProduct = p;
    _nameController.text = p.name;
    _skuController.text = p.sku;
    _barcodeController.text = p.barcode ?? '';
    _categoryController.text = p.category;
    _sellingPriceController.text = p.sellingPrice.toString();
    _costPriceController.text = p.costPrice != null ? p.costPrice.toString() : '';
    _stockController.text = p.stockQuantity.toString();
    _descriptionController.text = p.description ?? '';
    _selectedUnit = p.unit;

    _showFormModal(context, isEdit: true);
  }

  void _showFormModal(BuildContext context, {required bool isEdit}) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            backgroundColor: AppColors.darkCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isEdit ? 'Edit Product' : 'Add New Product', style: const TextStyle(color: AppColors.darkText, fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(LucideIcons.x, size: 18, color: AppColors.darkSubtext), onPressed: () => Navigator.of(context).pop()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: AppColors.darkText, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Product Name *'),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _skuController,
                            style: const TextStyle(color: AppColors.darkText, fontSize: 13, fontFamily: 'monospace'),
                            decoration: const InputDecoration(labelText: 'SKU / Code *'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _barcodeController,
                            style: const TextStyle(color: AppColors.darkText, fontSize: 13, fontFamily: 'monospace'),
                            decoration: const InputDecoration(labelText: 'Barcode (Optional)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _categoryController,
                            style: const TextStyle(color: AppColors.darkText, fontSize: 13),
                            decoration: const InputDecoration(labelText: 'Category *'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedUnit,
                            decoration: const InputDecoration(labelText: 'Unit *'),
                            items: const [
                              DropdownMenuItem(value: 'piece', child: Text('piece')),
                              DropdownMenuItem(value: 'packet', child: Text('packet')),
                              DropdownMenuItem(value: 'box', child: Text('box')),
                              DropdownMenuItem(value: 'kg', child: Text('kg')),
                              DropdownMenuItem(value: 'litre', child: Text('litre')),
                              DropdownMenuItem(value: 'meter', child: Text('meter')),
                              DropdownMenuItem(value: 'dozen', child: Text('dozen')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => _selectedUnit = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _sellingPriceController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(labelText: 'Selling Price *'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _costPriceController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.darkText, fontSize: 13),
                            decoration: const InputDecoration(labelText: 'Cost Price'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(labelText: 'Current Stock Quantity *'),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _descriptionController,
                      maxLines: 2,
                      style: const TextStyle(color: AppColors.darkText, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Description (Optional)'),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          onPressed: () {
                            final name = _nameController.text;
                            final sku = _skuController.text;
                            final barcode = _barcodeController.text;
                            final category = _categoryController.text;
                            final sellP = double.tryParse(_sellingPriceController.text) ?? -1;
                            final costP = double.tryParse(_costPriceController.text);
                            final stock = int.tryParse(_stockController.text) ?? -1;
                            final desc = _descriptionController.text;

                            final productProv = context.read<ProductProvider>();

                            if (isEdit && _editingProduct != null) {
                              final res = productProv.updateProduct(_editingProduct!.id, {
                                'name': name,
                                'sku': sku,
                                'barcode': barcode,
                                'category': category,
                                'sellingPrice': sellP,
                                'costPrice': costP,
                                'stockQuantity': stock,
                                'unit': _selectedUnit,
                                'description': desc,
                              });

                              if (res['success'] == true) {
                                _showSnackBar('Product updated!');
                                Navigator.of(context).pop();
                              } else {
                                _showSnackBar(res['error'] ?? 'Error updating product', isError: true);
                              }
                            } else {
                              final res = productProv.addProduct(
                                name: name,
                                sku: sku,
                                barcode: barcode,
                                category: category,
                                sellingPrice: sellP,
                                costPrice: costP,
                                stockQuantity: stock,
                                unit: _selectedUnit,
                                description: desc,
                              );

                              if (res['success'] == true) {
                                _showSnackBar('Product added!');
                                Navigator.of(context).pop();
                              } else {
                                _showSnackBar(res['error'] ?? 'Error adding product', isError: true);
                              }
                            }
                          },
                          child: Text(isEdit ? 'Save Changes' : 'Create Product', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProv = context.watch<ProductProvider>();
    final settings = context.watch<SettingsProvider>().settings;

    final allProducts = productProv.products;
    final categories = ['All', ...allProducts.map((p) => p.category).toSet()];

    final filtered = allProducts.where((p) {
      if (_activeTab == 'active' && p.isDeleted) return false;
      if (_activeTab == 'archived' && !p.isDeleted) return false;

      if (_categoryFilter != 'All' && p.category != _categoryFilter) return false;

      if (_stockFilter == 'in_stock' && p.stockQuantity <= 0) return false;
      if (_stockFilter == 'low_stock' && (p.stockQuantity > settings.lowStockThreshold || p.stockQuantity <= 0)) return false;
      if (_stockFilter == 'out_of_stock' && p.stockQuantity > 0) return false;

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchesName = p.name.toLowerCase().contains(q);
        final matchesSku = p.sku.toLowerCase().contains(q);
        final matchesBarcode = p.barcode?.toLowerCase().contains(q) ?? false;
        return matchesName || matchesSku || matchesBarcode;
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header & Tab switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('Active (${allProducts.where((p) => !p.isDeleted).length})'),
                      selected: _activeTab == 'active',
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.transparent,
                      onSelected: (_) => setState(() => _activeTab = 'active'),
                    ),
                    const SizedBox(width: 4),
                    ChoiceChip(
                      label: Text('Archived (${allProducts.where((p) => p.isDeleted).length})'),
                      selected: _activeTab == 'archived',
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.transparent,
                      onSelected: (_) => setState(() => _activeTab = 'archived'),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: () => _openAddProductModal(context),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filters Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.darkText, fontSize: 13),
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: const InputDecoration(
                    hintText: 'Search product name, SKU, or barcode...',
                    prefixIcon: Icon(LucideIcons.search, size: 16, color: AppColors.darkSubtext),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              DropdownButton<String>(
                value: _categoryFilter,
                dropdownColor: AppColors.darkCard,
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c == 'All' ? 'All Categories' : c, style: const TextStyle(fontSize: 12, color: AppColors.darkText)))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _categoryFilter = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: filtered.isEmpty
                  ? const Center(child: Text('No products found.', style: TextStyle(color: AppColors.darkSubtext, fontSize: 12)))
                  : SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 16,
                        columns: const [
                          DataColumn(label: Text('Product Name', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('SKU', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Category', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Price', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Stock', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Actions', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11, fontWeight: FontWeight.bold))),
                        ],
                        rows: filtered.map((p) {
                          final isOut = p.stockQuantity <= 0;
                          final isLow = p.stockQuantity > 0 && p.stockQuantity <= settings.lowStockThreshold;

                          return DataRow(
                            cells: [
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name, style: const TextStyle(color: AppColors.darkText, fontSize: 12, fontWeight: FontWeight.bold)),
                                    if (p.barcode != null && p.barcode!.isNotEmpty)
                                      Text('BC: ${p.barcode}', style: const TextStyle(color: AppColors.darkSubtext, fontSize: 9, fontFamily: 'monospace')),
                                  ],
                                ),
                              ),
                              DataCell(Text(p.sku, style: const TextStyle(color: AppColors.darkSubtext, fontSize: 11, fontFamily: 'monospace'))),
                              DataCell(Text(p.category, style: const TextStyle(color: AppColors.darkText, fontSize: 11))),
                              DataCell(Text(Formatters.formatCurrency(p.sellingPrice, settings.currencySymbol), style: const TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.bold))),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isOut ? AppColors.danger.withValues(alpha: 0.2) : isLow ? AppColors.warning.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${p.stockQuantity} ${p.unit}',
                                    style: TextStyle(
                                      color: isOut ? Colors.redAccent : isLow ? AppColors.warning : AppColors.primaryLight,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    if (_activeTab == 'active') ...[
                                      IconButton(
                                        icon: const Icon(LucideIcons.edit2, size: 16, color: AppColors.info),
                                        onPressed: () => _openEditProductModal(context, p),
                                      ),
                                      IconButton(
                                        icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.danger),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => ConfirmDialog(
                                              title: 'Archive Product',
                                              message: 'Are you sure you want to archive "${p.name}"? It will be hidden from the active POS counter.',
                                              onConfirm: () => productProv.softDeleteProduct(p.id),
                                            ),
                                          );
                                        },
                                      ),
                                    ] else ...[
                                      IconButton(
                                        icon: const Icon(LucideIcons.rotateCcw, size: 16, color: AppColors.primaryLight),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => ConfirmDialog(
                                              title: 'Restore Product',
                                              message: 'Restore "${p.name}" back to active catalog?',
                                              variant: ConfirmVariant.info,
                                              onConfirm: () => productProv.restoreProduct(p.id),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
