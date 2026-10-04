import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/seed_data.dart';
import '../models/business_settings.dart';
import '../models/customer.dart';
import '../models/order.dart';
import '../models/pending_order.dart';
import '../models/product.dart';
import '../models/user.dart';

class StorageKeys {
  static const String authUser = 'pos_auth_user';
  static const String products = 'pos_products';
  static const String customers = 'pos_customers';
  static const String orders = 'pos_orders';
  static const String pendingOrders = 'pos_pending_orders';
  static const String settings = 'pos_settings';
  static const String seeded = 'pos_has_seeded_v1';
}

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _initializeSeedData();
  }

  static Future<void> _initializeSeedData() async {
    final prefs = _prefs!;
    final migrationKey = prefs.getString(StorageKeys.seeded);
    final currentSettings = prefs.getString(StorageKeys.settings);
    final hasAed = currentSettings != null && currentSettings.contains('AED');
    final existingProducts = prefs.getString(StorageKeys.products);
    final hasMarlboro = existingProducts != null && existingProducts.contains('Marlboro Red');

    if (migrationKey != 'true_aed_v5' || !hasAed || !hasMarlboro) {
      await saveProducts(INITIAL_PRODUCTS);
      await saveCustomers(INITIAL_CUSTOMERS);
      await saveOrders(INITIAL_ORDERS);
      await saveSettings(DEFAULT_SETTINGS);
      if (!prefs.containsKey(StorageKeys.pendingOrders)) {
        await savePendingOrders([]);
      }
      await prefs.setString(StorageKeys.seeded, 'true_aed_v5');
    }
  }

  // Auth User
  static User? getAuthUser() {
    final jsonStr = _prefs?.getString(StorageKeys.authUser);
    if (jsonStr == null) return null;
    try {
      return User.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  static Future<void> setAuthUser(User? user) async {
    if (user == null) {
      await _prefs?.remove(StorageKeys.authUser);
    } else {
      await _prefs?.setString(StorageKeys.authUser, jsonEncode(user.toJson()));
    }
  }

  // Products
  static List<Product> getProducts() {
    final jsonStr = _prefs?.getString(StorageKeys.products);
    if (jsonStr == null) return INITIAL_PRODUCTS;
    try {
      final List raw = jsonDecode(jsonStr);
      return raw.map((item) => Product.fromJson(item)).toList();
    } catch (_) {
      return INITIAL_PRODUCTS;
    }
  }

  static Future<void> saveProducts(List<Product> products) async {
    final jsonStr = jsonEncode(products.map((p) => p.toJson()).toList());
    await _prefs?.setString(StorageKeys.products, jsonStr);
  }

  // Customers
  static List<Customer> getCustomers() {
    final jsonStr = _prefs?.getString(StorageKeys.customers);
    if (jsonStr == null) return INITIAL_CUSTOMERS;
    try {
      final List raw = jsonDecode(jsonStr);
      return raw.map((item) => Customer.fromJson(item)).toList();
    } catch (_) {
      return INITIAL_CUSTOMERS;
    }
  }

  static Future<void> saveCustomers(List<Customer> customers) async {
    final jsonStr = jsonEncode(customers.map((c) => c.toJson()).toList());
    await _prefs?.setString(StorageKeys.customers, jsonStr);
  }

  // Orders
  static List<Order> getOrders() {
    final jsonStr = _prefs?.getString(StorageKeys.orders);
    if (jsonStr == null) return INITIAL_ORDERS;
    try {
      final List raw = jsonDecode(jsonStr);
      return raw.map((item) => Order.fromJson(item)).toList();
    } catch (_) {
      return INITIAL_ORDERS;
    }
  }

  static Future<void> saveOrders(List<Order> orders) async {
    final jsonStr = jsonEncode(orders.map((o) => o.toJson()).toList());
    await _prefs?.setString(StorageKeys.orders, jsonStr);
  }

  // Pending Orders
  static List<PendingOrder> getPendingOrders() {
    final jsonStr = _prefs?.getString(StorageKeys.pendingOrders);
    if (jsonStr == null) return [];
    try {
      final List raw = jsonDecode(jsonStr);
      return raw.map((item) => PendingOrder.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePendingOrders(List<PendingOrder> pendingOrders) async {
    final jsonStr = jsonEncode(pendingOrders.map((p) => p.toJson()).toList());
    await _prefs?.setString(StorageKeys.pendingOrders, jsonStr);
  }

  // Settings
  static BusinessSettings getSettings() {
    final jsonStr = _prefs?.getString(StorageKeys.settings);
    if (jsonStr == null) return DEFAULT_SETTINGS;
    try {
      return BusinessSettings.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return DEFAULT_SETTINGS;
    }
  }

  static Future<void> saveSettings(BusinessSettings settings) async {
    final jsonStr = jsonEncode(settings.toJson());
    await _prefs?.setString(StorageKeys.settings, jsonStr);
  }

  // Reset All Data
  static Future<void> resetAllData() async {
    await saveProducts(INITIAL_PRODUCTS);
    await saveCustomers(INITIAL_CUSTOMERS);
    await saveOrders(INITIAL_ORDERS);
    await savePendingOrders([]);
    await saveSettings(DEFAULT_SETTINGS);
    await _prefs?.setString(StorageKeys.seeded, 'true_aed_v5');
  }

  // Export JSON string
  static String exportDataJson() {
    return jsonEncode({
      'products': getProducts().map((p) => p.toJson()).toList(),
      'customers': getCustomers().map((c) => c.toJson()).toList(),
      'orders': getOrders().map((o) => o.toJson()).toList(),
      'pendingOrders': getPendingOrders().map((p) => p.toJson()).toList(),
      'settings': getSettings().toJson(),
      'exportedAt': DateTime.now().toIso8601String(),
    });
  }

  // Import JSON string
  static Future<bool> importDataJson(String jsonString) async {
    try {
      final parsed = jsonDecode(jsonString);
      if (parsed['products'] != null && parsed['products'] is List) {
        final List prods = parsed['products'];
        await saveProducts(prods.map((e) => Product.fromJson(e)).toList());
      }
      if (parsed['customers'] != null && parsed['customers'] is List) {
        final List custs = parsed['customers'];
        await saveCustomers(custs.map((e) => Customer.fromJson(e)).toList());
      }
      if (parsed['orders'] != null && parsed['orders'] is List) {
        final List ords = parsed['orders'];
        await saveOrders(ords.map((e) => Order.fromJson(e)).toList());
      }
      if (parsed['pendingOrders'] != null && parsed['pendingOrders'] is List) {
        final List pOrds = parsed['pendingOrders'];
        await savePendingOrders(pOrds.map((e) => PendingOrder.fromJson(e)).toList());
      }
      if (parsed['settings'] != null && parsed['settings'] is Map) {
        await saveSettings(BusinessSettings.fromJson(parsed['settings']));
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
