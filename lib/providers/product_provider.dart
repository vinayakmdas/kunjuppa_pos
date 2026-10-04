import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/storage_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoaded = false;

  List<Product> get products => _products;
  bool get isLoaded => _isLoaded;

  ProductProvider() {
    loadProducts();
  }

  void loadProducts() {
    _products = StorageService.getProducts();
    _isLoaded = true;
    notifyListeners();
  }

  List<Product> getActiveProducts() {
    return _products.where((p) => !p.isDeleted).toList();
  }

  List<Product> getArchivedProducts() {
    return _products.where((p) => p.isDeleted).toList();
  }

  Map<String, dynamic> addProduct({
    required String name,
    required String sku,
    String? barcode,
    required String category,
    required double sellingPrice,
    double? costPrice,
    required int stockQuantity,
    required String unit,
    String? description,
  }) {
    final cleanName = name.trim();
    final cleanSku = sku.trim().toUpperCase();

    if (cleanName.isEmpty) {
      return {'success': false, 'error': 'Product name is required.'};
    }
    if (cleanSku.isEmpty) {
      return {'success': false, 'error': 'SKU is required.'};
    }
    if (sellingPrice < 0) {
      return {'success': false, 'error': 'Selling price cannot be negative.'};
    }
    if (stockQuantity < 0) {
      return {'success': false, 'error': 'Stock quantity cannot be negative.'};
    }

    final skuExists = _products.any((p) => !p.isDeleted && p.sku.toLowerCase() == cleanSku.toLowerCase());
    if (skuExists) {
      return {'success': false, 'error': "SKU '$cleanSku' already exists."};
    }

    final nowStr = DateTime.now().toIso8601String();
    final newProduct = Product(
      id: 'prod-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1000)}',
      name: cleanName,
      sku: cleanSku,
      barcode: barcode?.trim().isEmpty ?? true ? null : barcode?.trim(),
      category: category.trim(),
      sellingPrice: sellingPrice,
      costPrice: costPrice,
      stockQuantity: stockQuantity,
      unit: unit,
      description: description?.trim().isEmpty ?? true ? null : description?.trim(),
      createdAt: nowStr,
      updatedAt: nowStr,
      isDeleted: false,
    );

    _products = [newProduct, ..._products];
    StorageService.saveProducts(_products);
    notifyListeners();
    return {'success': true, 'product': newProduct};
  }

  Map<String, dynamic> updateProduct(String id, Map<String, dynamic> updates) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index == -1) {
      return {'success': false, 'error': 'Product not found.'};
    }

    final current = _products[index];

    if (updates.containsKey('sellingPrice') && updates['sellingPrice'] != null) {
      if ((updates['sellingPrice'] as num) < 0) {
        return {'success': false, 'error': 'Selling price cannot be negative.'};
      }
    }
    if (updates.containsKey('stockQuantity') && updates['stockQuantity'] != null) {
      if ((updates['stockQuantity'] as num) < 0) {
        return {'success': false, 'error': 'Stock quantity cannot be negative.'};
      }
    }

    if (updates.containsKey('sku') && updates['sku'] != null) {
      final newSku = (updates['sku'] as String).trim().toUpperCase();
      final skuConflict = _products.any((p) => p.id != id && !p.isDeleted && p.sku.toLowerCase() == newSku.toLowerCase());
      if (skuConflict) {
        return {'success': false, 'error': "SKU '$newSku' is already in use by another product."};
      }
    }

    final updatedProduct = current.copyWith(
      name: updates['name'] as String?,
      sku: updates['sku'] != null ? (updates['sku'] as String).trim().toUpperCase() : null,
      barcode: updates['barcode'] as String?,
      category: updates['category'] as String?,
      sellingPrice: updates['sellingPrice'] != null ? (updates['sellingPrice'] as num).toDouble() : null,
      costPrice: updates['costPrice'] != null ? (updates['costPrice'] as num).toDouble() : null,
      stockQuantity: updates['stockQuantity'] as int?,
      unit: updates['unit'] as String?,
      description: updates['description'] as String?,
      updatedAt: DateTime.now().toIso8601String(),
    );

    _products[index] = updatedProduct;
    StorageService.saveProducts(_products);
    notifyListeners();
    return {'success': true};
  }

  Map<String, dynamic> softDeleteProduct(String id) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      _products[index] = _products[index].copyWith(
        isDeleted: true,
        deletedAt: DateTime.now().toIso8601String(),
      );
      StorageService.saveProducts(_products);
      notifyListeners();
    }
    return {'success': true};
  }

  Map<String, dynamic> restoreProduct(String id) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      _products[index] = _products[index].copyWith(
        isDeleted: false,
        deletedAt: null,
        updatedAt: DateTime.now().toIso8601String(),
      );
      StorageService.saveProducts(_products);
      notifyListeners();
    }
    return {'success': true};
  }

  bool reduceStock(List<Map<String, dynamic>> items) {
    bool updatedAny = false;
    for (int i = 0; i < _products.length; i++) {
      final p = _products[i];
      final matched = items.firstWhere(
        (item) => item['productId'] == p.id,
        orElse: () => {},
      );
      if (matched.isNotEmpty) {
        final int qty = matched['quantity'] as int;
        final newQty = max(0, p.stockQuantity - qty);
        _products[i] = p.copyWith(
          stockQuantity: newQty,
          updatedAt: DateTime.now().toIso8601String(),
        );
        updatedAny = true;
      }
    }

    if (updatedAny) {
      StorageService.saveProducts(_products);
      notifyListeners();
    }
    return true;
  }
}
