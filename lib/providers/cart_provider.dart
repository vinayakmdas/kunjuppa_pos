import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/customer.dart';
import '../models/pending_order.dart';
import '../models/product.dart';
import '../services/storage_service.dart';

class CartTotals {
  final int itemCount;
  final int totalQuantity;
  final double subtotal;
  final double discountAmount;
  final double grandTotal;

  CartTotals({
    required this.itemCount,
    required this.totalQuantity,
    required this.subtotal,
    required this.discountAmount,
    required this.grandTotal,
  });
}

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  Customer? _selectedCustomer;
  bool _isWalkIn = true;
  String _discountType = 'fixed'; // 'percentage' | 'fixed'
  double _discountValue = 0.0;
  String _paymentMethod = 'cash'; // 'cash' | 'upi' | 'card'
  List<PendingOrder> _pendingOrders = [];

  List<CartItem> get items => _items;
  Customer? get selectedCustomer => _selectedCustomer;
  bool get isWalkIn => _isWalkIn;
  String get discountType => _discountType;
  double get discountValue => _discountValue;
  String get paymentMethod => _paymentMethod;
  List<PendingOrder> get pendingOrders => _pendingOrders;

  CartProvider() {
    loadPendingOrders();
  }

  void loadPendingOrders() {
    _pendingOrders = StorageService.getPendingOrders();
    notifyListeners();
  }

  Map<String, dynamic> addItem(Product product, [int quantity = 1]) {
    if (product.isDeleted) {
      return {'success': false, 'message': 'Cannot add an archived product.'};
    }
    if (product.stockQuantity <= 0) {
      return {'success': false, 'message': '"${product.name}" is currently out of stock.'};
    }

    final existingIndex = _items.indexWhere((i) => i.productId == product.id);

    if (existingIndex > -1) {
      final currentItem = _items[existingIndex];
      final newQty = currentItem.quantity + quantity;
      if (newQty > product.stockQuantity) {
        return {
          'success': false,
          'message': 'Only ${product.stockQuantity} ${product.unit}(s) available in stock.',
        };
      }
      _items[existingIndex] = currentItem.copyWith(
        quantity: newQty,
        lineTotal: double.parse((newQty * currentItem.unitPrice).toStringAsFixed(2)),
      );
    } else {
      if (quantity > product.stockQuantity) {
        return {
          'success': false,
          'message': 'Only ${product.stockQuantity} ${product.unit}(s) available in stock.',
        };
      }
      final newItem = CartItem(
        productId: product.id,
        name: product.name,
        sku: product.sku,
        barcode: product.barcode,
        originalPrice: product.sellingPrice,
        unitPrice: product.sellingPrice,
        isCustomPrice: false,
        quantity: quantity,
        maxStock: product.stockQuantity,
        unit: product.unit,
        lineTotal: double.parse((quantity * product.sellingPrice).toStringAsFixed(2)),
      );
      _items.add(newItem);
    }

    notifyListeners();
    return {'success': true};
  }

  Map<String, dynamic> updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((i) => i.productId == productId);
    if (index == -1) return {'success': false, 'message': 'Item not in cart.'};

    final item = _items[index];
    if (quantity <= 0) {
      _items.removeAt(index);
      notifyListeners();
      return {'success': true};
    }

    if (quantity > item.maxStock) {
      return {
        'success': false,
        'message': 'Maximum available stock is ${item.maxStock} ${item.unit}(s).',
      };
    }

    _items[index] = item.copyWith(
      quantity: quantity,
      lineTotal: double.parse((quantity * item.unitPrice).toStringAsFixed(2)),
    );
    notifyListeners();
    return {'success': true};
  }

  Map<String, dynamic> updateItemPrice(String productId, double newPrice) {
    final index = _items.indexWhere((i) => i.productId == productId);
    if (index == -1) return {'success': false, 'message': 'Item not found in cart.'};

    final sanitizedPrice = max(0.0, newPrice);
    final item = _items[index];
    final isCustom = sanitizedPrice != item.originalPrice;

    _items[index] = item.copyWith(
      unitPrice: sanitizedPrice,
      isCustomPrice: isCustom,
      lineTotal: double.parse((item.quantity * sanitizedPrice).toStringAsFixed(2)),
    );

    notifyListeners();
    return {'success': true};
  }

  void resetItemPrice(String productId) {
    final index = _items.indexWhere((i) => i.productId == productId);
    if (index == -1) return;

    final item = _items[index];
    _items[index] = item.copyWith(
      unitPrice: item.originalPrice,
      isCustomPrice: false,
      lineTotal: double.parse((item.quantity * item.originalPrice).toStringAsFixed(2)),
    );

    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((i) => i.productId == productId);
    notifyListeners();
  }

  void clearCart() {
    _items = [];
    _discountValue = 0.0;
    _selectedCustomer = null;
    _isWalkIn = true;
    _paymentMethod = 'cash';
    notifyListeners();
  }

  void setSelectedCustomer(Customer? customer) {
    _selectedCustomer = customer;
    _isWalkIn = customer == null;
    notifyListeners();
  }

  void setWalkIn(bool walkIn) {
    _isWalkIn = walkIn;
    if (walkIn) _selectedCustomer = null;
    notifyListeners();
  }

  void setDiscount(String type, double value) {
    _discountType = type;
    _discountValue = max(0.0, value);
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  CartTotals getTotals() {
    final itemCount = _items.length;
    final totalQuantity = _items.fold<int>(0, (sum, item) => sum + item.quantity);
    final subtotal = double.parse(
        _items.fold<double>(0.0, (sum, item) => sum + item.lineTotal).toStringAsFixed(2));

    double discountAmount = 0.0;
    if (_discountType == 'percentage') {
      discountAmount = double.parse(
          ((subtotal * min(100.0, _discountValue)) / 100.0).toStringAsFixed(2));
    } else {
      discountAmount = min(subtotal, _discountValue);
    }

    final grandTotal = max(0.0, double.parse((subtotal - discountAmount).toStringAsFixed(2)));

    return CartTotals(
      itemCount: itemCount,
      totalQuantity: totalQuantity,
      subtotal: subtotal,
      discountAmount: discountAmount,
      grandTotal: grandTotal,
    );
  }

  // Hold / Park bill into cart queue
  Map<String, dynamic> parkCurrentBill([String? customLabel]) {
    if (_items.isEmpty) {
      return {'success': false, 'message': 'Cannot save an empty bill.'};
    }

    final totals = getTotals();
    final nextQueueNum = _pendingOrders.length + 1;
    final custName = _isWalkIn || _selectedCustomer == null ? 'Walk-in Customer' : _selectedCustomer!.name;
    final defaultLabel = 'Bill #$nextQueueNum ($custName)';

    final pendingOrder = PendingOrder(
      id: 'pending-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1000)}',
      queueNumber: nextQueueNum,
      label: customLabel?.trim().isNotEmpty ?? false ? customLabel!.trim() : defaultLabel,
      createdAt: DateTime.now().toIso8601String(),
      customerId: _selectedCustomer?.id,
      customerName: custName,
      customerPhone: _selectedCustomer?.phone,
      customerSnapshot: _selectedCustomer,
      items: List.from(_items),
      itemCount: totals.itemCount,
      totalQuantity: totals.totalQuantity,
      subtotal: totals.subtotal,
      discountType: _discountType,
      discountValue: _discountValue,
      discountAmount: totals.discountAmount,
      grandTotal: totals.grandTotal,
      paymentMethod: _paymentMethod,
      isPrinted: false,
    );

    _pendingOrders = [pendingOrder, ..._pendingOrders];
    StorageService.savePendingOrders(_pendingOrders);

    clearCart();
    return {'success': true, 'pendingOrder': pendingOrder};
  }

  void removePendingOrder(String id) {
    _pendingOrders.removeWhere((p) => p.id == id);
    StorageService.savePendingOrders(_pendingOrders);
    notifyListeners();
  }

  void markPendingOrderPrinted(String id) {
    final index = _pendingOrders.indexWhere((p) => p.id == id);
    if (index != -1) {
      _pendingOrders[index] = _pendingOrders[index].copyWith(
        isPrinted: true,
        printedAt: DateTime.now().toIso8601String(),
      );
      StorageService.savePendingOrders(_pendingOrders);
      notifyListeners();
    }
  }

  void loadPendingOrderIntoCart(String id) {
    final index = _pendingOrders.indexWhere((p) => p.id == id);
    if (index == -1) return;

    final found = _pendingOrders[index];

    _items = List.from(found.items);
    _selectedCustomer = found.customerSnapshot;
    _isWalkIn = found.customerId == null;
    _discountType = found.discountType;
    _discountValue = found.discountValue;
    _paymentMethod = found.paymentMethod;

    _pendingOrders.removeAt(index);
    StorageService.savePendingOrders(_pendingOrders);
    notifyListeners();
  }

  void clearAllPendingOrders() {
    _pendingOrders = [];
    StorageService.savePendingOrders([]);
    notifyListeners();
  }
}
