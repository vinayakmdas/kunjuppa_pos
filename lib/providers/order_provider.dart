import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/storage_service.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoaded = false;

  List<Order> get orders => _orders;
  bool get isLoaded => _isLoaded;

  OrderProvider() {
    loadOrders();
  }

  void loadOrders() {
    _orders = StorageService.getOrders();
    _isLoaded = true;
    notifyListeners();
  }

  List<Order> getActiveOrders() {
    return _orders.where((o) => !o.isDeleted).toList();
  }

  List<Order> getArchivedOrders() {
    return _orders.where((o) => o.isDeleted).toList();
  }

  String generateNextOrderNumber() {
    final currentYear = DateTime.now().year;
    final yearPrefix = 'ORD-$currentYear-';
    final yearOrders = _orders.where((o) => o.orderNumber.startsWith(yearPrefix)).toList();

    int maxSeq = 0;
    for (var o in yearOrders) {
      final parts = o.orderNumber.split('-');
      if (parts.length >= 3) {
        final seq = int.tryParse(parts[2]);
        if (seq != null && seq > maxSeq) {
          maxSeq = seq;
        }
      }
    }
    final nextSeq = (maxSeq + 1).toString().padLeft(4, '0');
    return 'ORD-$currentYear-$nextSeq';
  }

  void addOrder(Order order) {
    _orders = [order, ..._orders];
    StorageService.saveOrders(_orders);
    notifyListeners();
  }

  Map<String, dynamic> softDeleteOrder(String id) {
    final index = _orders.indexWhere((o) => o.id == id);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        isDeleted: true,
        deletedAt: DateTime.now().toIso8601String(),
      );
      StorageService.saveOrders(_orders);
      notifyListeners();
    }
    return {'success': true};
  }

  Map<String, dynamic> restoreOrder(String id) {
    final index = _orders.indexWhere((o) => o.id == id);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        isDeleted: false,
        deletedAt: null,
      );
      StorageService.saveOrders(_orders);
      notifyListeners();
    }
    return {'success': true};
  }

  Map<String, dynamic> bulkSoftDeleteOrders(List<String> ids) {
    final targetSet = ids.toSet();
    int count = 0;
    for (int i = 0; i < _orders.length; i++) {
      if (targetSet.contains(_orders[i].id) && !_orders[i].isDeleted) {
        count++;
        _orders[i] = _orders[i].copyWith(
          isDeleted: true,
          deletedAt: DateTime.now().toIso8601String(),
        );
      }
    }
    StorageService.saveOrders(_orders);
    notifyListeners();
    return {'success': true, 'count': count};
  }

  Map<String, dynamic> bulkRestoreOrders(List<String> ids) {
    final targetSet = ids.toSet();
    int count = 0;
    for (int i = 0; i < _orders.length; i++) {
      if (targetSet.contains(_orders[i].id) && _orders[i].isDeleted) {
        count++;
        _orders[i] = _orders[i].copyWith(
          isDeleted: false,
          deletedAt: null,
        );
      }
    }
    StorageService.saveOrders(_orders);
    notifyListeners();
    return {'success': true, 'count': count};
  }
}
