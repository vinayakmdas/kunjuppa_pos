import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../providers/order_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/confirm_dialog.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _activeTab = 'active'; // 'active' | 'archived'
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Form Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  Customer? _editingCustomer;

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
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

  void _openAddCustomerModal(BuildContext context) {
    _editingCustomer = null;
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _addressController.clear();
    _notesController.clear();

    _showFormModal(context, isEdit: false);
  }

  void _openEditCustomerModal(BuildContext context, Customer c) {
    _editingCustomer = c;
    _nameController.text = c.name;
    _phoneController.text = c.phone;
    _emailController.text = c.email ?? '';
    _addressController.text = c.address ?? '';
    _notesController.text = c.notes ?? '';

    _showFormModal(context, isEdit: true);
  }

  void _showFormModal(BuildContext context, {required bool isEdit}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isEdit ? 'Edit Customer Details' : 'Add New Customer', style: const TextStyle(color: AppColors.darkText, fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(LucideIcons.x, size: 18, color: AppColors.darkSubtext), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.darkText, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Full Name *'),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppColors.darkText, fontSize: 13, fontFamily: 'monospace'),
                decoration: const InputDecoration(labelText: 'Phone Number *'),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.darkText, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Email Address (Optional)'),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _addressController,
                maxLines: 2,
                style: const TextStyle(color: AppColors.darkText, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Address (Optional)'),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _notesController,
                style: const TextStyle(color: AppColors.darkText, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Notes (Optional)'),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: () {
                      final name = _nameController.text;
                      final phone = _phoneController.text;
                      final email = _emailController.text;
                      final address = _addressController.text;
                      final notes = _notesController.text;

                      final custProv = context.read<CustomerProvider>();

                      if (isEdit && _editingCustomer != null) {
                        final res = custProv.updateCustomer(_editingCustomer!.id, {
                          'name': name,
                          'phone': phone,
                          'email': email,
                          'address': address,
                          'notes': notes,
                        });

                        if (res['success'] == true) {
                          _showSnackBar('Customer profile updated!');
                          Navigator.of(context).pop();
                        } else {
                          _showSnackBar(res['error'] ?? 'Error updating customer', isError: true);
                        }
                      } else {
                        final res = custProv.addCustomer(
                          name: name,
                          phone: phone,
                          email: email,
                          address: address,
                          notes: notes,
                        );

                        if (res['success'] == true) {
                          _showSnackBar('Customer registered!');
                          Navigator.of(context).pop();
                        } else {
                          _showSnackBar(res['error'] ?? 'Error adding customer', isError: true);
                        }
                      }
                    },
                    child: Text(isEdit ? 'Save Changes' : 'Save Customer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomerProfileModal(BuildContext context, Customer c) {
    final orderProv = context.read<OrderProvider>();
    final settings = context.read<SettingsProvider>().settings;

    final custOrders = orderProv.orders.where((o) => o.customerId == c.id && !o.isDeleted).toList();
    final double totalSpent = custOrders.fold(0.0, (sum, o) => sum + o.grandTotal);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(c.name, style: const TextStyle(color: AppColors.darkText, fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(LucideIcons.x, size: 18, color: AppColors.darkSubtext), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.darkInputBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Lifetime Spend', style: TextStyle(color: AppColors.darkSubtext, fontSize: 10)),
                          Text(Formatters.formatCurrency(totalSpent, settings.currencySymbol), style: const TextStyle(color: AppColors.primaryLight, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Orders', style: TextStyle(color: AppColors.darkSubtext, fontSize: 10)),
                          Text('${custOrders.length}', style: const TextStyle(color: AppColors.darkText, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Text('Phone: ${c.phone}', style: const TextStyle(color: AppColors.darkText, fontSize: 12, fontFamily: 'monospace')),
              if (c.email != null) Text('Email: ${c.email}', style: const TextStyle(color: AppColors.darkSubtext, fontSize: 11)),
              if (c.address != null) Text('Address: ${c.address}', style: const TextStyle(color: AppColors.darkSubtext, fontSize: 11)),
              if (c.notes != null) Text('Notes: "${c.notes}"', style: const TextStyle(color: AppColors.darkSubtext, fontSize: 11, fontStyle: FontStyle.italic)),
              const SizedBox(height: 16),

              const Text('Purchase History', style: TextStyle(color: AppColors.darkText, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),

              SizedBox(
                height: 150,
                child: custOrders.isEmpty
                    ? const Center(child: Text('No orders recorded yet.', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11)))
                    : ListView.separated(
                        itemCount: custOrders.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.darkCardBorder),
                        itemBuilder: (context, idx) {
                          final o = custOrders[idx];
                          return ListTile(
                            dense: true,
                            title: Text(o.orderNumber, style: const TextStyle(color: AppColors.darkText, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                            subtitle: Text(Formatters.formatDateTime(o.createdAt), style: const TextStyle(color: AppColors.darkSubtext, fontSize: 10)),
                            trailing: Text(Formatters.formatCurrency(o.grandTotal, settings.currencySymbol), style: const TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.bold)),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final custProv = context.watch<CustomerProvider>();

    final allCustomers = custProv.customers;

    final filtered = allCustomers.where((c) {
      if (_activeTab == 'active' && c.isDeleted) return false;
      if (_activeTab == 'archived' && !c.isDeleted) return false;

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchesName = c.name.toLowerCase().contains(q);
        final matchesPhone = c.phone.contains(q);
        final matchesEmail = c.email?.toLowerCase().contains(q) ?? false;
        return matchesName || matchesPhone || matchesEmail;
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('Active (${allCustomers.where((c) => !c.isDeleted).length})'),
                      selected: _activeTab == 'active',
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.transparent,
                      onSelected: (_) => setState(() => _activeTab = 'active'),
                    ),
                    const SizedBox(width: 4),
                    ChoiceChip(
                      label: Text('Archived (${allCustomers.where((c) => c.isDeleted).length})'),
                      selected: _activeTab == 'archived',
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.transparent,
                      onSelected: (_) => setState(() => _activeTab = 'archived'),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: () => _openAddCustomerModal(context),
                icon: const Icon(LucideIcons.userPlus, size: 16),
                label: const Text('Add Customer', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search
          TextField(
            controller: _searchController,
            style: const TextStyle(color: AppColors.darkText, fontSize: 13),
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: const InputDecoration(
              hintText: 'Search customer by name, phone, email...',
              prefixIcon: Icon(LucideIcons.search, size: 16, color: AppColors.darkSubtext),
            ),
          ),
          const SizedBox(height: 16),

          // Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: filtered.isEmpty
                  ? const Center(child: Text('No customers found.', style: TextStyle(color: AppColors.darkSubtext, fontSize: 12)))
                  : SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 16,
                        columns: const [
                          DataColumn(label: Text('Customer Name', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Phone', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Email', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Address', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Actions', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11, fontWeight: FontWeight.bold))),
                        ],
                        rows: filtered.map((c) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.name, style: const TextStyle(color: AppColors.darkText, fontSize: 12, fontWeight: FontWeight.bold)),
                                    if (c.notes != null && c.notes!.isNotEmpty)
                                      Text(c.notes!, style: const TextStyle(color: AppColors.darkSubtext, fontSize: 9, fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ),
                              DataCell(Text(c.phone, style: const TextStyle(color: AppColors.darkText, fontSize: 12, fontFamily: 'monospace'))),
                              DataCell(Text(c.email ?? '-', style: const TextStyle(color: AppColors.darkSubtext, fontSize: 11))),
                              DataCell(Text(c.address ?? '-', style: const TextStyle(color: AppColors.darkSubtext, fontSize: 11))),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(LucideIcons.eye, size: 16, color: AppColors.primaryLight),
                                      onPressed: () => _showCustomerProfileModal(context, c),
                                    ),
                                    if (_activeTab == 'active') ...[
                                      IconButton(
                                        icon: const Icon(LucideIcons.edit2, size: 16, color: AppColors.info),
                                        onPressed: () => _openEditCustomerModal(context, c),
                                      ),
                                      IconButton(
                                        icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.danger),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => ConfirmDialog(
                                              title: 'Archive Customer',
                                              message: 'Archive customer "${c.name}"? They will be hidden from the active directory.',
                                              onConfirm: () => custProv.softDeleteCustomer(c.id),
                                            ),
                                          );
                                        },
                                      ),
                                    ] else ...[
                                      IconButton(
                                        icon: const Icon(LucideIcons.rotateCcw, size: 16, color: AppColors.primaryLight),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => ConfirmDialog(
                                              title: 'Restore Customer',
                                              message: 'Restore "${c.name}" back to active patrons?',
                                              variant: ConfirmVariant.info,
                                              onConfirm: () => custProv.restoreCustomer(c.id),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
