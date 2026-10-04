import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/order.dart';
import '../providers/customer_provider.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/receipt_modal.dart';
import 'main_shell_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProv = context.watch<OrderProvider>();
    final productProv = context.watch<ProductProvider>();
    final customerProv = context.watch<CustomerProvider>();
    final settings = context.watch<SettingsProvider>().settings;

    final activeOrders = orderProv.getActiveOrders();
    final activeProducts = productProv.getActiveProducts();
    final activeCustomers = customerProv.getActiveCustomers();

    // Today calculations
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final todayOrders = activeOrders.where((o) {
      try {
        final dt = DateTime.parse(o.createdAt);
        return dt.isAfter(todayStart) || dt.isAtSameMomentAs(todayStart);
      } catch (_) {
        return false;
      }
    }).toList();

    final double totalSalesToday = todayOrders.fold(0.0, (sum, o) => sum + o.grandTotal);
    final double totalAllTimeSales = activeOrders.fold(0.0, (sum, o) => sum + o.grandTotal);

    // Low stock products
    final lowStockProducts = activeProducts.where((p) => p.stockQuantity <= settings.lowStockThreshold).toList();

    // Recent 5 orders
    final recentOrders = List<Order>.from(activeOrders)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final displayRecent = recentOrders.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Welcome & Shortcuts Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkCardBorder),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Store Overview',
                      style: TextStyle(color: AppColors.darkText, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Today's sales figures, inventory metrics, and stock alerts",
                      style: TextStyle(color: AppColors.darkSubtext, fontSize: 11),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        final shellState = context.findAncestorStateOfType<MainShellScreenState>();
                        if (shellState != null) {
                          shellState.navigateToIndex(1); // POS screen index
                        }
                      },
                      icon: const Icon(LucideIcons.shoppingCart, size: 16),
                      label: const Text('New Sale (POS)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Metric Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = constraints.maxWidth > 800
                  ? (constraints.maxWidth - 48) / 4
                  : (constraints.maxWidth > 500 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth);

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  // Today's Sales
                  _buildMetricCard(
                    width: cardWidth,
                    title: "TODAY'S SALES",
                    value: Formatters.formatCurrency(totalSalesToday, settings.currencySymbol),
                    subtitle: 'All-time: ${Formatters.formatCurrency(totalAllTimeSales, settings.currencySymbol)}',
                    icon: LucideIcons.banknote,
                    color: AppColors.primaryLight,
                  ),
                  // Orders Today
                  _buildMetricCard(
                    width: cardWidth,
                    title: 'ORDERS TODAY',
                    value: todayOrders.length.toString(),
                    subtitle: 'Total active: ${activeOrders.length}',
                    icon: LucideIcons.shoppingBag,
                    color: AppColors.info,
                  ),
                  // Active Products
                  _buildMetricCard(
                    width: cardWidth,
                    title: 'ACTIVE PRODUCTS',
                    value: activeProducts.length.toString(),
                    subtitle: '${lowStockProducts.length} items low in stock',
                    icon: LucideIcons.package,
                    color: Colors.purpleAccent,
                  ),
                  // Registered Customers
                  _buildMetricCard(
                    width: cardWidth,
                    title: 'CUSTOMERS',
                    value: activeCustomers.length.toString(),
                    subtitle: 'Regular store patrons',
                    icon: LucideIcons.users,
                    color: AppColors.warning,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Two-Column Section: Recent Orders & Stock Alerts
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 900;

              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recent Orders Table
                  Expanded(
                    flex: isWide ? 6 : 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.darkCardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Recent Sales', style: TextStyle(color: AppColors.darkText, fontSize: 14, fontWeight: FontWeight.bold)),
                              Text('Latest completed transactions', style: TextStyle(color: AppColors.darkSubtext, fontSize: 10)),
                            ],
                          ),
                          const SizedBox(height: 12),

                          displayRecent.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(
                                    child: Text('No completed orders yet.', style: TextStyle(color: AppColors.darkSubtext, fontSize: 12)),
                                  ),
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columnSpacing: 16,
                                    headingRowHeight: 36,
                                    dataRowHeight: 44,
                                    columns: const [
                                      DataColumn(label: Text('Order #', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Customer', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Date', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Total', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Payment', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Receipt', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11, fontWeight: FontWeight.bold))),
                                    ],
                                    rows: displayRecent.map((order) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(order.orderNumber, style: const TextStyle(color: AppColors.darkText, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'))),
                                          DataCell(Text(order.customerName, style: const TextStyle(color: AppColors.darkText, fontSize: 12))),
                                          DataCell(Text(Formatters.formatDateTime(order.createdAt), style: const TextStyle(color: AppColors.darkSubtext, fontSize: 11))),
                                          DataCell(Text(Formatters.formatCurrency(order.grandTotal, settings.currencySymbol), style: const TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.bold))),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(order.paymentMethod.toUpperCase(), style: const TextStyle(color: AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                          DataCell(
                                            IconButton(
                                              icon: const Icon(LucideIcons.receipt, size: 16, color: AppColors.primaryLight),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (_) => ReceiptModal(order: order),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),

                  if (isWide) const SizedBox(width: 16) else const SizedBox(height: 16),

                  // Stock Alerts Column
                  Expanded(
                    flex: isWide ? 4 : 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.darkCardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.alertTriangle, color: AppColors.warning, size: 18),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Stock Level Alerts', style: TextStyle(color: AppColors.darkText, fontSize: 14, fontWeight: FontWeight.bold)),
                                  Text('Below limit of ${settings.lowStockThreshold} units', style: const TextStyle(color: AppColors.darkSubtext, fontSize: 10)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          lowStockProducts.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Center(
                                    child: Text('All products have healthy inventory levels!', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11)),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: lowStockProducts.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, idx) {
                                    final p = lowStockProducts[idx];
                                    final bool isOut = p.stockQuantity <= 0;

                                    return Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.darkInputBg,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(p.name, style: const TextStyle(color: AppColors.darkText, fontSize: 12, fontWeight: FontWeight.bold)),
                                              Text('SKU: ${p.sku} • ${p.category}', style: const TextStyle(color: AppColors.darkSubtext, fontSize: 10)),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isOut ? AppColors.danger.withValues(alpha: 0.2) : AppColors.warning.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${p.stockQuantity} ${p.unit}',
                                              style: TextStyle(
                                                color: isOut ? Colors.redAccent : AppColors.warning,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppColors.darkSubtext, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: AppColors.darkText, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.darkSubtext, fontSize: 10)),
        ],
      ),
    );
  }
}
