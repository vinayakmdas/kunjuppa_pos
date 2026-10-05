import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/receipt_modal.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _activeTab = 'active'; // 'active' | 'archived'
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _dateFilter = 'all'; // 'all' | 'today' | '7days' | '30days'
  String _paymentFilter = 'all'; // 'all' | 'cash' | 'upi' | 'card'

  final List<String> _selectedIds = [];

  @override
  void dispose() {
    _searchController.dispose();
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

  DataColumn _col(String label) => DataColumn(
        label: Text(
          label,
          style: const TextStyle(color: AppColors.darkSubtext, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );

  Widget _actionButton(IconData icon, Color color, VoidCallback onPressed) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      icon: Icon(icon, size: 16, color: color),
      onPressed: onPressed,
    );
  }

  void _toggleSelected(String id, bool selected) {
    setState(() {
      if (selected) {
        if (!_selectedIds.contains(id)) _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  void _showOrderDetailsModal(BuildContext context, Order order) {
    final settings = context.read<SettingsProvider>().settings;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Details: ${order.orderNumber}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.darkText, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                            ),
                            Text(
                              'Placed on ${Formatters.formatDateTime(order.createdAt)}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.darkSubtext, fontSize: 11),
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
                  const SizedBox(height: 16),

                  // Customer & Payment Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.darkInputBg, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CUSTOMER', style: TextStyle(color: AppColors.darkSubtext, fontSize: 9, fontWeight: FontWeight.bold)),
                              Text(
                                order.customerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              if (order.customerPhone != null)
                                Text(
                                  order.customerPhone!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppColors.darkSubtext, fontSize: 10, fontFamily: 'monospace'),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('PAYMENT', style: TextStyle(color: AppColors.darkSubtext, fontSize: 9, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                order.paymentMethod.toUpperCase(),
                                style: const TextStyle(color: AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Items list
                  Text('Items (${order.itemCount})', style: const TextStyle(color: AppColors.darkText, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),

                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      itemCount: order.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.darkCardBorder),
                      itemBuilder: (context, idx) {
                        final item = order.items[idx];
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          title: Text(
                            item.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.darkText, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${item.quantity} ${item.unit} @ ${Formatters.formatCurrency(item.unitPrice, settings.currencySymbol)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.darkSubtext, fontSize: 10),
                          ),
                          trailing: Text(
                            Formatters.formatCurrency(item.lineTotal, settings.currencySymbol),
                            style: const TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Financial Totals
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.darkInputBg, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11)),
                            Text(Formatters.formatCurrency(order.subtotal, settings.currencySymbol), style: const TextStyle(color: AppColors.darkText, fontSize: 11)),
                          ],
                        ),
                        if (order.discountAmount > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Discount (${order.discountType == "percentage" ? "${order.discountValue}%" : "Flat"}):',
                                style: const TextStyle(color: AppColors.darkSubtext, fontSize: 11),
                              ),
                              Text(
                                '-${Formatters.formatCurrency(order.discountAmount, settings.currencySymbol)}',
                                style: const TextStyle(color: AppColors.primaryLight, fontSize: 11),
                              ),
                            ],
                          ),
                        const Divider(color: AppColors.darkCardBorder),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('GRAND TOTAL:', style: TextStyle(color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.bold)),
                            Text(
                              Formatters.formatCurrency(order.grandTotal, settings.currencySymbol),
                              style: const TextStyle(color: AppColors.primaryLight, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                        onPressed: () {
                          Navigator.of(context).pop();
                          showDialog(
                            context: context,
                            builder: (_) => ReceiptModal(order: order),
                          );
                        },
                        icon: const Icon(LucideIcons.printer, size: 16),
                        label: const Text('Print Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = context.watch<OrderProvider>();
    final settings = context.watch<SettingsProvider>().settings;

    final allOrders = orderProv.orders;

    final filtered = allOrders.where((o) {
      if (_activeTab == 'active' && o.isDeleted) return false;
      if (_activeTab == 'archived' && !o.isDeleted) return false;

      if (_paymentFilter != 'all' && o.paymentMethod != _paymentFilter) return false;

      if (_dateFilter != 'all') {
        try {
          final dt = DateTime.parse(o.createdAt).toLocal();
          final now = DateTime.now();
          if (_dateFilter == 'today') {
            final todayStart = DateTime(now.year, now.month, now.day);
            if (dt.isBefore(todayStart)) return false;
          } else if (_dateFilter == '7days') {
            if (now.difference(dt).inDays > 7) return false;
          } else if (_dateFilter == '30days') {
            if (now.difference(dt).inDays > 30) return false;
          }
        } catch (_) {}
      }

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchesNo = o.orderNumber.toLowerCase().contains(q);
        final matchesCust = o.customerName.toLowerCase().contains(q);
        final matchesPhone = o.customerPhone?.contains(q) ?? false;
        return matchesNo || matchesCust || matchesPhone;
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Tab Switcher
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ChoiceChip(
                      label: Text('Active Orders (${allOrders.where((o) => !o.isDeleted).length})'),
                      selected: _activeTab == 'active',
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.transparent,
                      onSelected: (_) {
                        setState(() {
                          _activeTab = 'active';
                          _selectedIds.clear();
                        });
                      },
                    ),
                    const SizedBox(width: 4),
                    ChoiceChip(
                      label: Text('Archived (${allOrders.where((o) => o.isDeleted).length})'),
                      selected: _activeTab == 'archived',
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.transparent,
                      onSelected: (_) {
                        setState(() {
                          _activeTab = 'archived';
                          _selectedIds.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),

              if (_selectedIds.isNotEmpty)
                if (_activeTab == 'active')
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => ConfirmDialog(
                          title: 'Archive Selected Orders',
                          message: 'Move ${_selectedIds.length} selected orders to archive?',
                          onConfirm: () {
                            final res = orderProv.bulkSoftDeleteOrders(List<String>.from(_selectedIds));
                            setState(() => _selectedIds.clear());
                            _showSnackBar('Archived ${res['count']} orders.');
                          },
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.trash2, size: 16),
                    label: Text('Archive Selected (${_selectedIds.length})'),
                  )
                else
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => ConfirmDialog(
                          title: 'Restore Selected Orders',
                          message: 'Restore ${_selectedIds.length} selected orders to active list?',
                          variant: ConfirmVariant.info,
                          onConfirm: () {
                            final res = orderProv.bulkRestoreOrders(List<String>.from(_selectedIds));
                            setState(() => _selectedIds.clear());
                            _showSnackBar('Restored ${res['count']} orders.');
                          },
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.rotateCcw, size: 16),
                    label: Text('Restore Selected (${_selectedIds.length})'),
                  ),
            ],
          ),
          const SizedBox(height: 16),

          // Filters Bar
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.darkText, fontSize: 13),
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: const InputDecoration(
                    hintText: 'Search by Order # or Customer...',
                    prefixIcon: Icon(LucideIcons.search, size: 16, color: AppColors.darkSubtext),
                  ),
                ),
              ),
              DropdownButton<String>(
                value: _dateFilter,
                dropdownColor: AppColors.darkCard,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Dates', style: TextStyle(fontSize: 12, color: AppColors.darkText))),
                  DropdownMenuItem(value: 'today', child: Text('Today Only', style: TextStyle(fontSize: 12, color: AppColors.darkText))),
                  DropdownMenuItem(value: '7days', child: Text('Last 7 Days', style: TextStyle(fontSize: 12, color: AppColors.darkText))),
                  DropdownMenuItem(value: '30days', child: Text('Last 30 Days', style: TextStyle(fontSize: 12, color: AppColors.darkText))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _dateFilter = val);
                },
              ),
              DropdownButton<String>(
                value: _paymentFilter,
                dropdownColor: AppColors.darkCard,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Payments', style: TextStyle(fontSize: 12, color: AppColors.darkText))),
                  DropdownMenuItem(value: 'cash', child: Text('Cash', style: TextStyle(fontSize: 12, color: AppColors.darkText))),
                  DropdownMenuItem(value: 'upi', child: Text('UPI / QR', style: TextStyle(fontSize: 12, color: AppColors.darkText))),
                  DropdownMenuItem(value: 'card', child: Text('Card', style: TextStyle(fontSize: 12, color: AppColors.darkText))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _paymentFilter = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Orders Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('No orders found.', style: TextStyle(color: AppColors.darkSubtext, fontSize: 12)),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: DataTable(
                                  // We draw our own checkbox column, so turn off
                                  // the built-in one (it caused a duplicate checkbox
                                  // and misaligned header).
                                  showCheckboxColumn: false,
                                  columnSpacing: 16,
                                  dataRowMinHeight: 52,
                                  dataRowMaxHeight: 60,
                                  dividerThickness: 0.5,
                                  columns: [
                                    DataColumn(
                                      label: Checkbox(
                                        value: filtered.isNotEmpty && filtered.every((o) => _selectedIds.contains(o.id)),
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              for (final o in filtered) {
                                                if (!_selectedIds.contains(o.id)) _selectedIds.add(o.id);
                                              }
                                            } else {
                                              _selectedIds.clear();
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    _col('Order #'),
                                    _col('Date & Time'),
                                    _col('Customer'),
                                    _col('Items'),
                                    _col('Total'),
                                    _col('Payment'),
                                    _col('Actions'),
                                  ],
                                  rows: filtered.map((o) {
                                    final isSelected = _selectedIds.contains(o.id);

                                    return DataRow(
                                      selected: isSelected,
                                      onSelectChanged: (val) => _toggleSelected(o.id, val == true),
                                      cells: [
                                        DataCell(
                                          Checkbox(
                                            value: isSelected,
                                            onChanged: (val) => _toggleSelected(o.id, val == true),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            o.orderNumber,
                                            style: const TextStyle(color: AppColors.darkText, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            Formatters.formatDateTime(o.createdAt),
                                            style: const TextStyle(color: AppColors.darkSubtext, fontSize: 11),
                                          ),
                                        ),
                                        DataCell(
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 160),
                                            child: Text(
                                              o.customerName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: AppColors.darkText, fontSize: 12),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '${o.itemCount} items (${o.totalQuantity} qty)',
                                            style: const TextStyle(color: AppColors.darkSubtext, fontSize: 11),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            Formatters.formatCurrency(o.grandTotal, settings.currencySymbol),
                                            style: const TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              o.paymentMethod.toUpperCase(),
                                              style: const TextStyle(color: AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _actionButton(
                                                LucideIcons.eye,
                                                AppColors.primaryLight,
                                                () => _showOrderDetailsModal(context, o),
                                              ),
                                              _actionButton(
                                                LucideIcons.printer,
                                                AppColors.primaryLight,
                                                () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (_) => ReceiptModal(order: o),
                                                  );
                                                },
                                              ),
                                              if (_activeTab == 'active')
                                                _actionButton(
                                                  LucideIcons.trash2,
                                                  AppColors.danger,
                                                  () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (_) => ConfirmDialog(
                                                        title: 'Archive Order',
                                                        message: 'Archive order ${o.orderNumber}?',
                                                        onConfirm: () => orderProv.softDeleteOrder(o.id),
                                                      ),
                                                    );
                                                  },
                                                )
                                              else
                                                _actionButton(
                                                  LucideIcons.rotateCcw,
                                                  AppColors.primaryLight,
                                                  () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (_) => ConfirmDialog(
                                                        title: 'Restore Order',
                                                        message: 'Restore order ${o.orderNumber} back to active list?',
                                                        variant: ConfirmVariant.info,
                                                        onConfirm: () => orderProv.restoreOrder(o.id),
                                                      ),
                                                    );
                                                  },
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}