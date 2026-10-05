import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/business_settings.dart';
import '../models/cart_item.dart';
import '../models/customer.dart';
import '../models/order.dart';
import '../models/pending_order.dart';
import '../providers/cart_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/receipt_modal.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  // Mobile / Tablet Tab view: 'catalog' | 'cart' | 'pending'
  String _activeMobileTab = 'catalog';

  // Search & Filters
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  // Price Edit Modal
  final _customPriceController = TextEditingController();

  // Customer search & modal
  final _customerSearchController = TextEditingController();
  String _customerSearch = '';

  // Quick Customer Creation
  final _custNameController = TextEditingController();
  final _custPhoneController = TextEditingController();
  final _custEmailController = TextEditingController();
  final _custAddressController = TextEditingController();

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customPriceController.dispose();
    _customerSearchController.dispose();
    _custNameController.dispose();
    _custPhoneController.dispose();
    _custEmailController.dispose();
    _custAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProv = context.watch<ProductProvider>();
    final cartProv = context.watch<CartProvider>();
    final customerProv = context.watch<CustomerProvider>();
    final orderProv = context.watch<OrderProvider>();
    final settings = context.watch<SettingsProvider>().settings;

    final activeProducts = productProv.getActiveProducts();
    final activeCustomers = customerProv.getActiveCustomers();

    // Unique Categories
    final categories = ['All', ...activeProducts.map((p) => p.category).toSet()];

    // Filter Products
    final filteredProducts = activeProducts.where((product) {
      if (_selectedCategory != 'All' && product.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchesName = product.name.toLowerCase().contains(q);
        final matchesSku = product.sku.toLowerCase().contains(q);
        final matchesBarcode = product.barcode?.toLowerCase().contains(q) ?? false;
        return matchesName || matchesSku || matchesBarcode;
      }
      return true;
    }).toList();

    final totals = cartProv.getTotals();
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Column(
        children: [
          // Mobile Segmented Bar (< 900px wide)
          if (!isDesktop)
            Container(
              color: AppColors.darkCard,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _buildTabButton('catalog', 'Catalog', LucideIcons.package),
                  const SizedBox(width: 8),
                  _buildTabButton('cart', 'Cart (${cartProv.items.length})', LucideIcons.shoppingCart),
                  const SizedBox(width: 8),
                  _buildTabButton('pending', 'Held Bills (${cartProv.pendingOrders.length})', LucideIcons.clock),
                ],
              ),
            ),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Catalog Section (Shown on Desktop or when mobile tab == 'catalog')
                if (isDesktop || _activeMobileTab == 'catalog')
                  Expanded(
                    flex: 6,
                    child: Column(
                      children: [
                        // Search & Category Bar
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: AppColors.darkCard,
                          child: Column(
                            children: [
                              // Search Input
                              TextField(
                                controller: _searchController,
                                style: const TextStyle(color: AppColors.darkText, fontSize: 13),
                                onChanged: (val) => setState(() => _searchQuery = val),
                                decoration: InputDecoration(
                                  hintText: 'Search product by name, SKU, barcode...',
                                  prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.darkSubtext),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(LucideIcons.x, size: 16, color: AppColors.darkSubtext),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Categories horizontal scroll
                              SizedBox(
                                height: 36,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: categories.length,
                                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                                  itemBuilder: (context, idx) {
                                    final cat = categories[idx];
                                    final isSelected = _selectedCategory == cat;

                                    return ChoiceChip(
                                      label: Text(cat),
                                      selected: isSelected,
                                      selectedColor: AppColors.primary,
                                      backgroundColor: AppColors.darkInputBg,
                                      labelStyle: TextStyle(
                                        color: isSelected ? Colors.white : AppColors.darkText,
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                      onSelected: (val) {
                                        setState(() => _selectedCategory = cat);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Products Grid
                        Expanded(
                          child: filteredProducts.isEmpty
                              ? const Center(
                                  child: Text('No products found.', style: TextStyle(color: AppColors.darkSubtext, fontSize: 12)),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.all(12),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isDesktop ? 4 : 2,
                                    childAspectRatio: 0.9,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                                  itemCount: filteredProducts.length,
                                   itemBuilder: (context, idx) {
                                    final product = filteredProducts[idx];
                                    final isOut = product.stockQuantity <= 0;
                                    // Check if this product is already in the cart
                                    final cartItem = cartProv.items
                                        .where((i) => i.productId == product.id)
                                        .firstOrNull;
                                    final inCart = cartItem != null;
                                    final cartQty = cartItem?.quantity ?? 0;

                                    return InkWell(
                                      onTap: isOut
                                          ? () => _showSnackBar('"${product.name}" is out of stock.', isError: true)
                                          : () {
                                              final res = cartProv.addItem(product, 1);
                                              if (res['success'] != true && res['message'] != null) {
                                                _showSnackBar(res['message'], isError: true);
                                              }
                                              // DO NOT auto-navigate to cart tab;
                                              // user stays on catalog to keep adding items.
                                            },
                                      borderRadius: BorderRadius.circular(14),
                                      child: Stack(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: inCart
                                                  ? AppColors.primary.withValues(alpha: 0.08)
                                                  : AppColors.darkCard,
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                color: inCart
                                                    ? AppColors.primaryLight
                                                    : AppColors.darkCardBorder,
                                                width: inCart ? 1.5 : 1.0,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      product.name,
                                                      style: TextStyle(
                                                        color: inCart ? AppColors.primaryLight : AppColors.darkText,
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'SKU: ${product.sku}',
                                                      style: const TextStyle(color: AppColors.darkSubtext, fontSize: 10, fontFamily: 'monospace'),
                                                    ),
                                                  ],
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      Formatters.formatCurrency(product.sellingPrice, settings.currencySymbol),
                                                      style: const TextStyle(color: AppColors.primaryLight, fontSize: 14, fontWeight: FontWeight.bold),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: isOut ? AppColors.danger.withValues(alpha: 0.2) : AppColors.darkInputBg,
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        isOut ? 'Out of stock' : '${product.stockQuantity} ${product.unit}',
                                                        style: TextStyle(
                                                          color: isOut ? Colors.redAccent : AppColors.darkSubtext,
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Quantity badge shown when item is in cart
                                          if (inCart)
                                            Positioned(
                                              top: 6,
                                              right: 6,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius: BorderRadius.circular(10),
                                                  boxShadow: const [
                                                    BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                                                  ],
                                                ),
                                                child: Text(
                                                  '$cartQty',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),

                // Cart Panel (Shown on Desktop or when mobile tab == 'cart')
                if (isDesktop || _activeMobileTab == 'cart')
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.darkCard,
                        border: Border(left: BorderSide(color: AppColors.darkCardBorder)),
                      ),
                      child: Column(
                        children: [
                          // Customer Selection Header
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppColors.darkCardBorder)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _openCustomerPickerModal(context, activeCustomers),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.darkInputBg,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.darkCardBorder),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(LucideIcons.user, size: 16, color: AppColors.primaryLight),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              cartProv.isWalkIn || cartProv.selectedCustomer == null
                                                  ? 'Walk-in Customer'
                                                  : cartProv.selectedCustomer!.name,
                                              style: const TextStyle(color: AppColors.darkText, fontSize: 12, fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const Icon(LucideIcons.chevronDown, size: 14, color: AppColors.darkSubtext),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (cartProv.items.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.danger),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => ConfirmDialog(
                                          title: 'Clear Current Cart',
                                          message: 'Are you sure you want to remove all items from this order?',
                                          confirmLabel: 'Clear Cart',
                                          onConfirm: () => cartProv.clearCart(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Cart Items List
                          Expanded(
                            child: cartProv.items.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(LucideIcons.shoppingCart, color: AppColors.darkSubtext, size: 36),
                                        SizedBox(height: 8),
                                        Text('Current cart is empty.', style: TextStyle(color: AppColors.darkSubtext, fontSize: 12)),
                                        Text('Tap items in catalog to add.', style: TextStyle(color: AppColors.darkSubtext, fontSize: 10)),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(10),
                                    itemCount: cartProv.items.length,
                                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                                    itemBuilder: (context, idx) {
                                      final item = cartProv.items[idx];

                                      return Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.darkInputBg,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item.name,
                                                    style: const TextStyle(color: AppColors.darkText, fontSize: 12, fontWeight: FontWeight.bold),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                IconButton(
                                                  constraints: const BoxConstraints(),
                                                  padding: EdgeInsets.zero,
                                                  icon: const Icon(LucideIcons.x, size: 14, color: AppColors.darkSubtext),
                                                  onPressed: () => cartProv.removeItem(item.productId),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),

                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                // Price & Custom Price Modal Trigger
                                                InkWell(
                                                  onTap: () => _openPriceEditModal(context, item, cartProv, settings),
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        Formatters.formatCurrency(item.unitPrice, settings.currencySymbol),
                                                        style: TextStyle(
                                                          color: item.isCustomPrice ? AppColors.primaryLight : AppColors.darkText,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      if (item.isCustomPrice) ...[
                                                        const SizedBox(width: 4),
                                                        const Text('(Spl Price)', style: TextStyle(color: AppColors.primaryLight, fontSize: 9)),
                                                      ],
                                                      const SizedBox(width: 4),
                                                      const Icon(LucideIcons.edit3, size: 12, color: AppColors.darkSubtext),
                                                    ],
                                                  ),
                                                ),

                                                // Quantity Increment/Decrement
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      constraints: const BoxConstraints(),
                                                      padding: const EdgeInsets.all(4),
                                                      icon: const Icon(LucideIcons.minusCircle, size: 18, color: AppColors.darkSubtext),
                                                      onPressed: () => cartProv.updateQuantity(item.productId, item.quantity - 1),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                                      child: Text('${item.quantity}', style: const TextStyle(color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.bold)),
                                                    ),
                                                    IconButton(
                                                      constraints: const BoxConstraints(),
                                                      padding: const EdgeInsets.all(4),
                                                      icon: const Icon(LucideIcons.plusCircle, size: 18, color: AppColors.primaryLight),
                                                      onPressed: () => cartProv.updateQuantity(item.productId, item.quantity + 1),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),

                          // Checkout & Discount Controls
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: AppColors.darkInputBg,
                              border: Border(top: BorderSide(color: AppColors.darkCardBorder)),
                            ),
                            child: Column(
                              children: [
                                // Discount & Payment row
                                Row(
                                  children: [
                                    // Payment Method dropdown
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        initialValue: cartProv.paymentMethod,
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        ),
                                        items: const [
                                          DropdownMenuItem(value: 'cash', child: Text('Cash', style: TextStyle(fontSize: 11))),
                                          DropdownMenuItem(value: 'upi', child: Text('UPI / QR', style: TextStyle(fontSize: 11))),
                                          DropdownMenuItem(value: 'card', child: Text('Card', style: TextStyle(fontSize: 11))),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) cartProv.setPaymentMethod(val);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Discount value
                                    SizedBox(
                                      width: 100,
                                      child: TextField(
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(fontSize: 11, color: AppColors.darkText),
                                        decoration: const InputDecoration(
                                          hintText: 'Disc',
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        ),
                                        onChanged: (val) {
                                          final d = double.tryParse(val) ?? 0.0;
                                          cartProv.setDiscount(cartProv.discountType, d);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Grand Total Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('GRAND TOTAL:', style: TextStyle(color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.bold)),
                                    Text(
                                      Formatters.formatCurrency(totals.grandTotal, settings.currencySymbol),
                                      style: const TextStyle(color: AppColors.primaryLight, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Buttons: Hold Bill & Checkout
                                Row(
                                  children: [
                                    // Hold Bill button
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.warning,
                                          side: const BorderSide(color: AppColors.warning),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: cartProv.items.isEmpty
                                            ? null
                                            : () {
                                                final res = cartProv.parkCurrentBill();
                                                if (res['success'] == true) {
                                                  _showSnackBar('${(res['pendingOrder'] as PendingOrder).label} parked in cart queue!');
                                                }
                                              },
                                        icon: const Icon(LucideIcons.clock, size: 14),
                                        label: const Text('Hold Bill', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Complete Checkout
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: cartProv.items.isEmpty
                                            ? null
                                            : () => _handleDirectCheckout(context, cartProv, productProv, orderProv, settings),
                                        icon: const Icon(LucideIcons.checkCircle, size: 16),
                                        label: const Text('Complete Sale', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Held Bills Queue Tab (Shown when mobile tab == 'pending')
                if (!isDesktop && _activeMobileTab == 'pending')
                  Expanded(
                    child: _buildHeldBillsQueueWidget(context, cartProv, productProv, orderProv, settings),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabId, String label, IconData icon) {
    final isSelected = _activeMobileTab == tabId;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeMobileTab = tabId),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.darkInputBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.darkSubtext),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.darkSubtext,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Held Bills / Pending Orders list view
  Widget _buildHeldBillsQueueWidget(
    BuildContext context,
    CartProvider cartProv,
    ProductProvider productProv,
    OrderProvider orderProv,
    BusinessSettings settings,
  ) {
    if (cartProv.pendingOrders.isEmpty) {
      return const Center(
        child: Text('No held bills in queue.', style: TextStyle(color: AppColors.darkSubtext, fontSize: 12)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: cartProv.pendingOrders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final pending = cartProv.pendingOrders[idx];

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkCardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(pending.label, style: const TextStyle(color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(
                    Formatters.formatCurrency(pending.grandTotal, settings.currencySymbol),
                    style: const TextStyle(color: AppColors.primaryLight, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Cust: ${pending.customerName} • ${pending.itemCount} items', style: const TextStyle(color: AppColors.darkSubtext, fontSize: 11)),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    onPressed: () => cartProv.removePendingOrder(pending.id),
                    child: const Text('Discard', style: TextStyle(fontSize: 10)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => ReceiptModal(
                          order: pending,
                          onSavePendingOrder: (p) => _savePendingToOrders(context, p, productProv, orderProv, cartProv),
                          onMarkPrinted: (id) => cartProv.markPendingOrderPrinted(id),
                        ),
                      );
                    },
                    child: const Text('Print / Save', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _openPriceEditModal(
    BuildContext context,
    CartItem item,
    CartProvider cartProv,
    BusinessSettings settings,
  ) {
    _customPriceController.text = item.unitPrice.toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: Text('Edit Unit Price: ${item.name}', style: const TextStyle(color: AppColors.darkText, fontSize: 14, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Original Catalog Price: ${Formatters.formatCurrency(item.originalPrice, settings.currencySymbol)}', style: const TextStyle(color: AppColors.darkSubtext, fontSize: 11)),
            const SizedBox(height: 10),
            TextField(
              controller: _customPriceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.darkText, fontSize: 13),
              decoration: const InputDecoration(labelText: 'Custom Unit Price'),
            ),
          ],
        ),
        actions: [
          if (item.isCustomPrice)
            TextButton(
              onPressed: () {
                cartProv.resetItemPrice(item.productId);
                Navigator.of(context).pop();
              },
              child: const Text('Reset to Catalog Price', style: TextStyle(color: AppColors.warning, fontSize: 11)),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final newP = double.tryParse(_customPriceController.text) ?? item.unitPrice;
              cartProv.updateItemPrice(item.productId, newP);
              Navigator.of(context).pop();
            },
            child: const Text('Save Price', style: TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _openCustomerPickerModal(BuildContext context, List<Customer> activeCustomers) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulWidgetBuilder(
        builder: (context, setModalState) {
          final q = _customerSearch.toLowerCase();
          final filtered = activeCustomers.where((c) => c.name.toLowerCase().contains(q) || c.phone.contains(q)).toList();
          final cartProv = context.watch<CartProvider>();

          return Dialog(
            backgroundColor: AppColors.darkCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Select Customer', style: TextStyle(color: AppColors.darkText, fontSize: 14, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(LucideIcons.x, size: 16, color: AppColors.darkSubtext), onPressed: () => Navigator.of(context).pop()),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ListTile(
                    dense: true,
                    leading: const Icon(LucideIcons.user, color: AppColors.primaryLight),
                    title: const Text('Walk-in Customer', style: TextStyle(color: AppColors.darkText, fontSize: 12, fontWeight: FontWeight.bold)),
                    onTap: () {
                      cartProv.setWalkIn(true);
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(color: AppColors.darkCardBorder),

                  TextField(
                    style: const TextStyle(color: AppColors.darkText, fontSize: 12),
                    decoration: const InputDecoration(hintText: 'Search customer by name or phone...'),
                    onChanged: (val) => setModalState(() => _customerSearch = val),
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final c = filtered[idx];
                        return ListTile(
                          dense: true,
                          title: Text(c.name, style: const TextStyle(color: AppColors.darkText, fontSize: 12, fontWeight: FontWeight.bold)),
                          subtitle: Text(c.phone, style: const TextStyle(color: AppColors.darkSubtext, fontSize: 10)),
                          onTap: () {
                            cartProv.setSelectedCustomer(c);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleDirectCheckout(
    BuildContext context,
    CartProvider cartProv,
    ProductProvider productProv,
    OrderProvider orderProv,
    BusinessSettings settings,
  ) {
    // Validate stock
    for (var item in cartProv.items) {
      final matchingProduct = productProv.getActiveProducts().where((p) => p.id == item.productId).firstOrNull;
      if (matchingProduct != null && item.quantity > matchingProduct.stockQuantity) {
        _showSnackBar('Insufficient stock for "${item.name}". Only ${matchingProduct.stockQuantity} available.', isError: true);
        return;
      }
    }

    final orderNo = orderProv.generateNextOrderNumber();
    final orderItems = cartProv.items
        .map((i) => OrderItem(
              productId: i.productId,
              productName: i.name,
              sku: i.sku,
              unitPrice: i.unitPrice,
              originalPrice: i.originalPrice,
              isCustomPrice: i.isCustomPrice,
              quantity: i.quantity,
              unit: i.unit,
              lineTotal: i.lineTotal,
            ))
        .toList();

    final totals = cartProv.getTotals();
    final newOrder = Order(
      id: 'ord-${DateTime.now().millisecondsSinceEpoch}',
      orderNumber: orderNo,
      createdAt: DateTime.now().toIso8601String(),
      customerId: cartProv.selectedCustomer?.id,
      customerName: cartProv.isWalkIn || cartProv.selectedCustomer == null ? 'Walk-in Customer' : cartProv.selectedCustomer!.name,
      customerPhone: cartProv.selectedCustomer?.phone,
      customerSnapshot: cartProv.selectedCustomer,
      items: orderItems,
      itemCount: totals.itemCount,
      totalQuantity: totals.totalQuantity,
      subtotal: totals.subtotal,
      discountType: cartProv.discountType,
      discountValue: cartProv.discountValue,
      discountAmount: totals.discountAmount,
      grandTotal: totals.grandTotal,
      paymentMethod: cartProv.paymentMethod,
      paymentStatus: 'paid',
      orderStatus: 'completed',
      isDeleted: false,
    );

    // Deduct stock
    productProv.reduceStock(cartProv.items.map((i) => {'productId': i.productId, 'quantity': i.quantity}).toList());
    orderProv.addOrder(newOrder);
    cartProv.clearCart();

    // Show Receipt Modal
    showDialog(
      context: context,
      builder: (_) => ReceiptModal(order: newOrder),
    );
  }

  void _savePendingToOrders(
    BuildContext context,
    PendingOrder pending,
    ProductProvider productProv,
    OrderProvider orderProv,
    CartProvider cartProv,
  ) {
    final orderNo = orderProv.generateNextOrderNumber();
    final orderItems = pending.items
        .map((i) => OrderItem(
              productId: i.productId,
              productName: i.name,
              sku: i.sku,
              unitPrice: i.unitPrice,
              originalPrice: i.originalPrice,
              isCustomPrice: i.isCustomPrice,
              quantity: i.quantity,
              unit: i.unit,
              lineTotal: i.lineTotal,
            ))
        .toList();

    final finalOrder = Order(
      id: 'ord-${DateTime.now().millisecondsSinceEpoch}',
      orderNumber: orderNo,
      createdAt: DateTime.now().toIso8601String(),
      customerId: pending.customerId,
      customerName: pending.customerName,
      customerPhone: pending.customerPhone,
      customerSnapshot: pending.customerSnapshot,
      items: orderItems,
      itemCount: pending.itemCount,
      totalQuantity: pending.totalQuantity,
      subtotal: pending.subtotal,
      discountType: pending.discountType,
      discountValue: pending.discountValue,
      discountAmount: pending.discountAmount,
      grandTotal: pending.grandTotal,
      paymentMethod: pending.paymentMethod,
      paymentStatus: 'paid',
      orderStatus: 'completed',
      isDeleted: false,
    );

    productProv.reduceStock(pending.items.map((i) => {'productId': i.productId, 'quantity': i.quantity}).toList());
    orderProv.addOrder(finalOrder);
    cartProv.removePendingOrder(pending.id);
    _showSnackBar('Order $orderNo saved to permanent orders!');
  }
}

class StatefulWidgetBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, StateSetter setState) builder;
  const StatefulWidgetBuilder({super.key, required this.builder});

  @override
  State<StatefulWidgetBuilder> createState() => _StatefulWidgetBuilderState();
}

class _StatefulWidgetBuilderState extends State<StatefulWidgetBuilder> {
  @override
  Widget build(BuildContext context) {
    return widget.builder(context, setState);
  }
}
