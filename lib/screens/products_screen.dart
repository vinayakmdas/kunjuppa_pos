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

  // Form controllers
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

  static const _units = ['piece', 'packet', 'box', 'dozen'];

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

  // ───────────────────────── helpers ─────────────────────────

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? LucideIcons.circleAlert : LucideIcons.circleCheck, size: 18, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError ? AppColors.danger : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, {IconData? icon, String? hint}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: AppColors.darkSubtext, fontSize: 13),
      hintStyle: TextStyle(color: AppColors.darkSubtext.withValues(alpha: 0.6), fontSize: 13),
      prefixIcon: icon == null ? null : Icon(icon, size: 16, color: AppColors.darkSubtext),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(AppColors.darkCardBorder),
      enabledBorder: border(AppColors.darkCardBorder),
      focusedBorder: border(AppColors.primary, 1.5),
    );
  }

  _StockStatus _statusOf(Product p, int lowThreshold) {
    if (p.stockQuantity <= 0) return _StockStatus.out;
    if (p.stockQuantity <= lowThreshold) return _StockStatus.low;
    return _StockStatus.ok;
  }

  Color _statusColor(_StockStatus s) {
    switch (s) {
      case _StockStatus.out:
        return AppColors.danger;
      case _StockStatus.low:
        return AppColors.warning;
      case _StockStatus.ok:
        return AppColors.primaryLight;
    }
  }

  String _statusLabel(_StockStatus s) {
    switch (s) {
      case _StockStatus.out:
        return 'Out of stock';
      case _StockStatus.low:
        return 'Low stock';
      case _StockStatus.ok:
        return 'In stock';
    }
  }

  // ───────────────────────── form ─────────────────────────

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
    _selectedUnit = _units.contains(p.unit) ? p.unit : _units.first;

    _showFormModal(context, isEdit: true);
  }

  Widget _formSection(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.primaryLight),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  void _showFormModal(BuildContext context, {required bool isEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // grab handle
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.darkSubtext.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(isEdit ? LucideIcons.pencil : LucideIcons.packagePlus, size: 18, color: AppColors.primaryLight),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEdit ? 'Edit product' : 'New product',
                                  style: const TextStyle(color: AppColors.darkText, fontSize: 17, fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  isEdit ? 'Update details and stock' : 'Add an item to your catalog',
                                  style: const TextStyle(color: AppColors.darkSubtext, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.x, size: 18, color: AppColors.darkSubtext),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: Column(
                          children: [
                            _formSection('Basics', LucideIcons.tag, [
                              TextField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                style: const TextStyle(color: AppColors.darkText, fontSize: 14),
                                decoration: _fieldDecoration('Product name *'),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _skuController,
                                      style: const TextStyle(color: AppColors.darkText, fontSize: 13, fontFamily: 'monospace'),
                                      decoration: _fieldDecoration('SKU *'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _barcodeController,
                                      style: const TextStyle(color: AppColors.darkText, fontSize: 13, fontFamily: 'monospace'),
                                      decoration: _fieldDecoration('Barcode', icon: LucideIcons.scanBarcode),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _categoryController,
                                style: const TextStyle(color: AppColors.darkText, fontSize: 14),
                                decoration: _fieldDecoration('Category *'),
                              ),
                              const SizedBox(height: 14),
                              const Text('Unit', style: TextStyle(color: AppColors.darkSubtext, fontSize: 12)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _units.map((u) {
                                  final selected = _selectedUnit == u;
                                  return ChoiceChip(
                                    label: Text(u),
                                    selected: selected,
                                    showCheckmark: false,
                                    selectedColor: AppColors.primary,
                                    backgroundColor: Colors.white.withValues(alpha: 0.04),
                                    side: BorderSide(color: selected ? AppColors.primary : AppColors.darkCardBorder),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: selected ? Colors.white : AppColors.darkText,
                                    ),
                                    onSelected: (_) => setModalState(() => _selectedUnit = u),
                                  );
                                }).toList(),
                              ),
                            ]),
                            _formSection('Pricing & stock', LucideIcons.wallet, [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _sellingPriceController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(color: AppColors.darkText, fontSize: 14, fontWeight: FontWeight.w700),
                                      decoration: _fieldDecoration('Selling price *'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _costPriceController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(color: AppColors.darkText, fontSize: 14),
                                      decoration: _fieldDecoration('Cost price'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _stockController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: AppColors.darkText, fontSize: 14, fontWeight: FontWeight.w700),
                                decoration: _fieldDecoration('Stock quantity *', icon: LucideIcons.boxes),
                              ),
                            ]),
                            _formSection('Notes', LucideIcons.textAlignStart, [
                              TextField(
                                controller: _descriptionController,
                                maxLines: 2,
                                style: const TextStyle(color: AppColors.darkText, fontSize: 13),
                                decoration: _fieldDecoration('Description', hint: 'Optional'),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppColors.darkCardBorder)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: AppColors.darkCardBorder),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel', style: TextStyle(color: AppColors.darkText)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: Icon(isEdit ? LucideIcons.check : LucideIcons.plus, size: 18),
                              label: Text(
                                isEdit ? 'Save changes' : 'Create product',
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              onPressed: () => _submitForm(context, isEdit),
                            ),
                          ),
                        ],
                      ),
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

  void _submitForm(BuildContext context, bool isEdit) {
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
        Navigator.of(context).pop();
        _showSnackBar('Product updated');
      } else {
        _showSnackBar(res['error'] ?? 'Could not update product', isError: true);
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
        Navigator.of(context).pop();
        _showSnackBar('Product added');
      } else {
        _showSnackBar(res['error'] ?? 'Could not add product', isError: true);
      }
    }
  }

  // ───────────────────────── widgets ─────────────────────────

  Widget _statTile({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.14) : AppColors.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? color.withValues(alpha: 0.7) : AppColors.darkCardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value',
                      style: const TextStyle(color: AppColors.darkText, fontSize: 18, fontWeight: FontWeight.w800, height: 1.1),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.darkSubtext, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String id, String label, int count) {
    final selected = _activeTab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.darkSubtext,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.darkSubtext,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _productCard(Product p, SettingsProvider settingsProv, ProductProvider productProv) {
    final settings = settingsProv.settings;
    final status = _statusOf(p, settings.lowStockThreshold);
    final color = _statusColor(status);
    final isArchived = _activeTab == 'archived';
    final initial = p.name.trim().isEmpty ? '?' : p.name.trim()[0].toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkCardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Opacity(
        opacity: isArchived ? 0.8 : 1,
        child: Row(
          children: [
            // status rail
            Container(width: 4, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        initial,
                        style: TextStyle(color: color, fontSize: 19, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.darkText, fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            p.barcode != null && p.barcode!.isNotEmpty ? '${p.sku}  •  ${p.barcode}' : p.sku,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.darkSubtext, fontSize: 10.5, fontFamily: 'monospace'),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    p.category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: AppColors.darkSubtext, fontSize: 10.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.formatCurrency(p.sellingPrice, settings.currencySymbol),
                          style: const TextStyle(color: AppColors.primaryLight, fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                              const SizedBox(width: 5),
                              Text(
                                '${p.stockQuantity} ${p.unit}',
                                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    _cardMenu(p, productProv, isArchived),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardMenu(Product p, ProductProvider productProv, bool isArchived) {
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.ellipsisVertical, size: 18, color: AppColors.darkSubtext),
      color: AppColors.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.darkCardBorder),
      ),
      onSelected: (v) {
        if (v == 'edit') {
          _openEditProductModal(context, p);
        } else if (v == 'archive') {
          showDialog(
            context: context,
            builder: (_) => ConfirmDialog(
              title: 'Archive Product',
              message: 'Are you sure you want to archive "${p.name}"? It will be hidden from the active POS counter.',
              onConfirm: () => productProv.softDeleteProduct(p.id),
            ),
          );
        } else if (v == 'restore') {
          showDialog(
            context: context,
            builder: (_) => ConfirmDialog(
              title: 'Restore Product',
              message: 'Restore "${p.name}" back to active catalog?',
              variant: ConfirmVariant.info,
              onConfirm: () => productProv.restoreProduct(p.id),
            ),
          );
        }
      },
      itemBuilder: (_) => [
        if (!isArchived) ...[
          _menuItem('edit', LucideIcons.pencil, 'Edit', AppColors.info),
          _menuItem('archive', LucideIcons.archive, 'Archive', AppColors.danger),
        ] else
          _menuItem('restore', LucideIcons.rotateCcw, 'Restore', AppColors.primaryLight),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppColors.darkText, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _emptyState(bool hasFilters) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters ? LucideIcons.searchX : LucideIcons.package,
                size: 32,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'No matching products' : (_activeTab == 'active' ? 'No products yet' : 'Nothing archived'),
              style: const TextStyle(color: AppColors.darkText, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters
                  ? 'Try a different search or clear the filters.'
                  : (_activeTab == 'active' ? 'Add your first product to start selling.' : 'Archived products will show up here.'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.darkSubtext, fontSize: 12),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.darkCardBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _categoryFilter = 'All';
                  _stockFilter = 'all';
                }),
                icon: const Icon(LucideIcons.x, size: 14, color: AppColors.darkText),
                label: const Text('Clear filters', style: TextStyle(color: AppColors.darkText)),
              ),
            ] else if (_activeTab == 'active') ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _openAddProductModal(context),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Add product'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ───────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final productProv = context.watch<ProductProvider>();
    final settingsProv = context.watch<SettingsProvider>();
    final settings = settingsProv.settings;

    final allProducts = productProv.products;
    final categories = ['All', ...allProducts.map((p) => p.category).toSet()];

    // Safety: reset category if it no longer exists
    if (!categories.contains(_categoryFilter)) {
      _categoryFilter = 'All';
    }

    final activeList = allProducts.where((p) => !p.isDeleted).toList();
    final archivedCount = allProducts.length - activeList.length;
    final lowCount = activeList.where((p) => p.stockQuantity > 0 && p.stockQuantity <= settings.lowStockThreshold).length;
    final outCount = activeList.where((p) => p.stockQuantity <= 0).length;

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

    final hasFilters = _searchQuery.trim().isNotEmpty || _categoryFilter != 'All' || _stockFilter != 'all';

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: CustomScrollView(
            slivers: [
              // Everything above the list now scrolls with the list
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Products',
                                style: TextStyle(color: AppColors.darkText, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                              ),
                              SizedBox(height: 2),
                              Text('Manage your catalog and stock', style: TextStyle(color: AppColors.darkSubtext, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stats (tap to filter)
                    Row(
                      children: [
                        _statTile(
                          label: 'Active items',
                          value: activeList.length,
                          icon: LucideIcons.package,
                          color: AppColors.primaryLight,
                          selected: _stockFilter == 'all',
                          onTap: () => setState(() => _stockFilter = 'all'),
                        ),
                        const SizedBox(width: 10),
                        _statTile(
                          label: 'Low stock',
                          value: lowCount,
                          icon: LucideIcons.triangleAlert,
                          color: AppColors.warning,
                          selected: _stockFilter == 'low_stock',
                          onTap: () => setState(() {
                            _activeTab = 'active';
                            _stockFilter = _stockFilter == 'low_stock' ? 'all' : 'low_stock';
                          }),
                        ),
                        const SizedBox(width: 10),
                        _statTile(
                          label: 'Out of stock',
                          value: outCount,
                          icon: LucideIcons.packageX,
                          color: AppColors.danger,
                          selected: _stockFilter == 'out_of_stock',
                          onTap: () => setState(() {
                            _activeTab = 'active';
                            _stockFilter = _stockFilter == 'out_of_stock' ? 'all' : 'out_of_stock';
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tabs
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.darkCardBorder),
                      ),
                      child: Row(
                        children: [
                          _tabButton('active', 'Active', activeList.length),
                          const SizedBox(width: 4),
                          _tabButton('archived', 'Archived', archivedCount),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Search + category
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: AppColors.darkText, fontSize: 13),
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: _fieldDecoration('Search', hint: 'Name, SKU or barcode', icon: LucideIcons.search).copyWith(
                              labelText: null,
                              suffixIcon: _searchQuery.isEmpty
                                  ? null
                                  : IconButton(
                                      icon: const Icon(LucideIcons.x, size: 16, color: AppColors.darkSubtext),
                                      onPressed: () => setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      }),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 170),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.darkCardBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _categoryFilter,
                                dropdownColor: AppColors.darkCard,
                                borderRadius: BorderRadius.circular(14),
                                icon: const Icon(LucideIcons.chevronDown, size: 16, color: AppColors.darkSubtext),
                                items: categories
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          c == 'All' ? 'All categories' : c,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12.5, color: AppColors.darkText),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _categoryFilter = val);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // Result list
              if (filtered.isEmpty)
                SliverToBoxAdapter(child: _emptyState(hasFilters))
              else
                SliverPadding(
                  padding: const EdgeInsets.only(top: 4, bottom: 96),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 540,
                      mainAxisExtent: 98,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 10,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _productCard(filtered[i], settingsProv, productProv),
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Floating add button
        if (_activeTab == 'active')
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              onPressed: () => _openAddProductModal(context),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Add product', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
      ],
    );
  }
}

enum _StockStatus { ok, low, out }