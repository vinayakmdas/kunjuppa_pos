import 'package:flutter_test/flutter_test.dart';
import 'package:kunjuppa_pos/models/customer.dart';
import 'package:kunjuppa_pos/models/product.dart';
import 'package:kunjuppa_pos/models/pending_order.dart';
import 'package:kunjuppa_pos/providers/cart_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Customer-First POS Workflow Tests', () {
    final testCustomer = Customer(
      id: 'cust-1',
      name: 'Customer A',
      phone: '9876543210',
      email: 'customera@test.com',
      isDeleted: false,
      createdAt: '2026-01-01T00:00:00.000Z',
      updatedAt: '2026-01-01T00:00:00.000Z',
    );

    final testProduct = Product(
      id: 'prod-1',
      name: 'Product A',
      sku: 'SKU-001',
      sellingPrice: 100.0,
      costPrice: 80.0,
      stockQuantity: 10,
      category: 'General',
      unit: 'pcs',
      isDeleted: false,
      createdAt: '2026-01-01T00:00:00.000Z',
      updatedAt: '2026-01-01T00:00:00.000Z',
    );

    test('New Sale requires customer selection before adding products', () {
      final cart = CartProvider();

      expect(cart.hasCustomerSelected, isFalse);

      final resultBeforeCustomer = cart.addItem(testProduct);
      expect(resultBeforeCustomer['success'], isFalse);
      expect(resultBeforeCustomer['message'], equals('Please select a customer first.'));
      expect(cart.items, isEmpty);

      cart.setSelectedCustomer(testCustomer);
      expect(cart.hasCustomerSelected, isTrue);
      expect(cart.selectedCustomer?.name, equals('Customer A'));

      final resultAfterCustomer = cart.addItem(testProduct);
      expect(resultAfterCustomer['success'], isTrue);
      expect(cart.items.length, equals(1));
    });

    test('Walk-in customer selection enables product selection', () {
      final cart = CartProvider();

      expect(cart.hasCustomerSelected, isFalse);

      cart.setWalkIn(true);
      expect(cart.hasCustomerSelected, isTrue);
      expect(cart.isWalkIn, isTrue);

      final result = cart.addItem(testProduct);
      expect(result['success'], isTrue);
      expect(cart.items.length, equals(1));
    });

    test('Holding bill saves customer and products, then resets for next sale', () {
      final cart = CartProvider();

      cart.setSelectedCustomer(testCustomer);
      cart.addItem(testProduct);

      final parkRes = cart.parkCurrentBill();
      expect(parkRes['success'], isTrue);

      final pendingOrder = parkRes['pendingOrder'] as PendingOrder;
      expect(pendingOrder.customerName, equals('Customer A'));
      expect(pendingOrder.items.length, equals(1));

      // After bill is held, cart resets for new sale
      expect(cart.hasCustomerSelected, isFalse);
      expect(cart.items, isEmpty);
    });

    test('Editing held bill preserves customer and products without blocking', () {
      final cart = CartProvider();

      cart.setSelectedCustomer(testCustomer);
      cart.addItem(testProduct);
      final parkRes = cart.parkCurrentBill();
      final pending = parkRes['pendingOrder'] as PendingOrder;

      // Start editing held bill
      cart.startEditingPendingOrder(pending);
      expect(cart.hasCustomerSelected, isTrue);
      expect(cart.selectedCustomer?.name, equals('Customer A'));
      expect(cart.items.length, equals(1));

      // Can update customer while editing
      final customerB = Customer(
        id: 'cust-2',
        name: 'Customer B',
        phone: '1234567890',
        email: 'customerb@test.com',
        isDeleted: false,
        createdAt: '2026-01-01T00:00:00.000Z',
        updatedAt: '2026-01-01T00:00:00.000Z',
      );
      cart.setSelectedCustomer(customerB);
      expect(cart.selectedCustomer?.name, equals('Customer B'));

      // Save updated held bill
      final saveRes = cart.saveUpdatedHeldBill();
      expect(saveRes['success'], isTrue);

      // Resets after saving
      expect(cart.hasCustomerSelected, isFalse);
    });
  });
}
