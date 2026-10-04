import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../services/storage_service.dart';

class CustomerProvider extends ChangeNotifier {
  List<Customer> _customers = [];
  bool _isLoaded = false;

  List<Customer> get customers => _customers;
  bool get isLoaded => _isLoaded;

  CustomerProvider() {
    loadCustomers();
  }

  void loadCustomers() {
    _customers = StorageService.getCustomers();
    _isLoaded = true;
    notifyListeners();
  }

  List<Customer> getActiveCustomers() {
    return _customers.where((c) => !c.isDeleted).toList();
  }

  List<Customer> getArchivedCustomers() {
    return _customers.where((c) => c.isDeleted).toList();
  }

  Map<String, dynamic> addCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
    String? notes,
  }) {
    final cleanName = name.trim();
    final cleanPhone = phone.trim();

    if (cleanName.isEmpty) {
      return {'success': false, 'error': 'Customer name is required.'};
    }
    if (cleanPhone.isEmpty) {
      return {'success': false, 'error': 'Phone number is required.'};
    }

    final phoneExists = _customers.any((c) => !c.isDeleted && c.phone.trim() == cleanPhone);
    if (phoneExists) {
      return {'success': false, 'error': 'A customer with phone number $cleanPhone already exists.'};
    }

    final nowStr = DateTime.now().toIso8601String();
    final newCustomer = Customer(
      id: 'cust-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1000)}',
      name: cleanName,
      phone: cleanPhone,
      email: email?.trim().isEmpty ?? true ? null : email?.trim(),
      address: address?.trim().isEmpty ?? true ? null : address?.trim(),
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
      createdAt: nowStr,
      updatedAt: nowStr,
      isDeleted: false,
    );

    _customers = [newCustomer, ..._customers];
    StorageService.saveCustomers(_customers);
    notifyListeners();
    return {'success': true, 'customer': newCustomer};
  }

  Map<String, dynamic> updateCustomer(String id, Map<String, dynamic> updates) {
    final index = _customers.indexWhere((c) => c.id == id);
    if (index == -1) {
      return {'success': false, 'error': 'Customer not found.'};
    }

    if (updates.containsKey('phone') && updates['phone'] != null) {
      final newPhone = (updates['phone'] as String).trim();
      final phoneConflict = _customers.any((c) => c.id != id && !c.isDeleted && c.phone.trim() == newPhone);
      if (phoneConflict) {
        return {'success': false, 'error': 'Phone number $newPhone is already registered.'};
      }
    }

    final current = _customers[index];
    final updatedCustomer = current.copyWith(
      name: updates['name'] as String?,
      phone: updates['phone'] as String?,
      email: updates['email'] as String?,
      address: updates['address'] as String?,
      notes: updates['notes'] as String?,
      updatedAt: DateTime.now().toIso8601String(),
    );

    _customers[index] = updatedCustomer;
    StorageService.saveCustomers(_customers);
    notifyListeners();
    return {'success': true};
  }

  Map<String, dynamic> softDeleteCustomer(String id) {
    final index = _customers.indexWhere((c) => c.id == id);
    if (index != -1) {
      _customers[index] = _customers[index].copyWith(
        isDeleted: true,
        deletedAt: DateTime.now().toIso8601String(),
      );
      StorageService.saveCustomers(_customers);
      notifyListeners();
    }
    return {'success': true};
  }

  Map<String, dynamic> restoreCustomer(String id) {
    final index = _customers.indexWhere((c) => c.id == id);
    if (index != -1) {
      _customers[index] = _customers[index].copyWith(
        isDeleted: false,
        deletedAt: null,
        updatedAt: DateTime.now().toIso8601String(),
      );
      StorageService.saveCustomers(_customers);
      notifyListeners();
    }
    return {'success': true};
  }
}
