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

  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  Customer? _editingCustomer;

  static const _avatarColors = [
    AppColors.primaryLight,
    AppColors.info,
    AppColors.warning,
    Color(0xFFA78BFA),
    Color(0xFFF472B6),
    Color(0xFF2DD4BF),
  ];

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

  // ───────────────────────── helpers ─────────────────────────

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? LucideIcons.x : LucideIcons.check, size: 18, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError ? AppColors.danger : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Color _colorFor(String name) {
    final sum = name.codeUnits.fold<int>(0, (a, b) => a + b);
    return _avatarColors[sum % _avatarColors.length];
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  InputDecoration _fieldDecoration(String label, {IconData? icon, String? hint}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: AppColors.darkSubtext, fontSize: 13),
      hintStyle: TextStyle(color: AppColors.darkSubtext.withValues(alpha: 0.6), fontSize: 13),
      prefixIcon: icon == null ? null : Icon(icon, size: 16, color: AppColors.darkSubtext),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(AppColors.darkCardBorder),
      enabledBorder: border(AppColors.darkCardBorder),
      focusedBorder: border(AppColors.primary, 1.5),
    );
  }

  Widget _avatar(String name, {double size = 46}) {
    final color = _colorFor(name);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        _initials(name),
        style: TextStyle(color: color, fontSize: size * 0.34, fontWeight: FontWeight.w800),
      ),
    );
  }

  void _confirmArchive(Customer c, CustomerProvider custProv) {
    showDialog(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Archive Customer',
        message: 'Archive "${c.name}"? They will be hidden from the active directory.',
        onConfirm: () => custProv.softDeleteCustomer(c.id),
      ),
    );
  }

  void _confirmRestore(Customer c, CustomerProvider custProv) {
    showDialog(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Restore Customer',
        message: 'Restore "${c.name}" back to the active directory?',
        variant: ConfirmVariant.info,
        onConfirm: () => custProv.restoreCustomer(c.id),
      ),
    );
  }

  // ───────────────────────── form ─────────────────────────

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

  Widget _sheetShell({required Widget child}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _grabHandle() => Container(
        margin: const EdgeInsets.only(top: 10),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.darkSubtext.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  void _showFormModal(BuildContext context, {required bool isEdit}) {
    String? formError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final bottomInset = MediaQuery.of(sheetCtx).viewInsets.bottom;
          final accent = isEdit ? AppColors.info : AppColors.primary;

          void submit() {
            final name = _nameController.text.trim();
            final phone = _phoneController.text.trim();
            final email = _emailController.text.trim();
            final address = _addressController.text.trim();
            final notes = _notesController.text.trim();

            if (name.isEmpty || phone.isEmpty) {
              setSheetState(() => formError = 'Name and phone are required.');
              return;
            }

            final custProv = context.read<CustomerProvider>();
            Map<String, dynamic> res;
            if (isEdit && _editingCustomer != null) {
              res = custProv.updateCustomer(_editingCustomer!.id, {
                'name': name,
                'phone': phone,
                'email': email,
                'address': address,
                'notes': notes,
              });
            } else {
              res = custProv.addCustomer(
                name: name,
                phone: phone,
                email: email,
                address: address,
                notes: notes,
              );
            }

            if (res['success'] == true) {
              Navigator.of(sheetCtx).pop();
              _showSnackBar(isEdit ? 'Customer updated' : 'Customer added');
            } else {
              setSheetState(() => formError = (res['error'] ?? 'Something went wrong').toString());
            }
          }

          return _sheetShell(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _grabHandle(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isEdit ? LucideIcons.userCog : LucideIcons.userPlus,
                            size: 18,
                            color: isEdit ? AppColors.info : AppColors.primaryLight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit ? 'Edit customer' : 'New customer',
                                style: const TextStyle(color: AppColors.darkText, fontSize: 17, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                isEdit ? 'Update profile details' : 'Add someone to your directory',
                                style: const TextStyle(color: AppColors.darkSubtext, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 18, color: AppColors.darkSubtext),
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Column(
                        children: [
                          if (formError != null)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                formError!,
                                style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          TextField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            style: const TextStyle(color: AppColors.darkText, fontSize: 14),
                            decoration: _fieldDecoration('Full name *', icon: LucideIcons.user),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: AppColors.darkText, fontSize: 14, fontFamily: 'monospace'),
                            decoration: _fieldDecoration('Phone number *', icon: LucideIcons.phone),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: AppColors.darkText, fontSize: 14),
                            decoration: _fieldDecoration('Email', icon: LucideIcons.mail),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _addressController,
                            maxLines: 2,
                            style: const TextStyle(color: AppColors.darkText, fontSize: 14),
                            decoration: _fieldDecoration('Address', icon: LucideIcons.mapPin),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesController,
                            maxLines: 2,
                            style: const TextStyle(color: AppColors.darkText, fontSize: 14),
                            decoration: _fieldDecoration('Internal notes', icon: LucideIcons.fileText),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.darkCardBorder)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: AppColors.darkCardBorder),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => Navigator.of(sheetCtx).pop(),
                            child: const Text('Cancel', style: TextStyle(color: AppColors.darkText)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: Icon(isEdit ? LucideIcons.check : LucideIcons.userPlus, size: 18),
                            label: Text(
                              isEdit ? 'Save changes' : 'Add customer',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            onPressed: submit,
                          ),
                        ),
                      ],
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

  // ───────────────────────── profile ─────────────────────────

  void _showCustomerProfileModal(BuildContext context, Customer c) {
    final orderProv = context.read<OrderProvider>();
    final settings = context.read<SettingsProvider>().settings;

    final custOrders = orderProv.orders.where((o) => o.customerId == c.id && !o.isDeleted).toList();
    final double totalSpent = custOrders.fold(0.0, (sum, o) => sum + o.grandTotal);
    final isArchived = c.isDeleted;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _sheetShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _grabHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
              child: Row(
                children: [
                  _avatar(c.name, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.darkText, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.phone,
                          style: const TextStyle(color: AppColors.darkSubtext, fontSize: 12.5, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 18, color: AppColors.darkSubtext),
                    onPressed: () => Navigator.of(sheetCtx).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _profileStat(
                            icon: LucideIcons.shoppingBag,
                            label: 'Orders',
                            value: '${custOrders.length}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _profileStat(
                            icon: LucideIcons.dollarSign,
                            label: 'Lifetime spend',
                            value: Formatters.formatCurrency(totalSpent, settings.currencySymbol),
                            highlight: true,
                          ),
                        ),
                      ],
                    ),
                    if ((c.email ?? '').isNotEmpty || (c.address ?? '').isNotEmpty || (c.notes ?? '').isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.darkCardBorder),
                        ),
                        child: Column(
                          children: [
                            if ((c.email ?? '').isNotEmpty) _infoRow(LucideIcons.mail, c.email!),
                            if ((c.address ?? '').isNotEmpty) _infoRow(LucideIcons.mapPin, c.address!),
                            if ((c.notes ?? '').isNotEmpty) _infoRow(LucideIcons.fileText, c.notes!, italic: true),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const Text(
                      'Purchase history',
                      style: TextStyle(color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    if (custOrders.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.darkCardBorder),
                        ),
                        child: const Column(
                          children: [
                            Icon(LucideIcons.shoppingBag, size: 24, color: AppColors.darkSubtext),
                            SizedBox(height: 8),
                            Text('No orders yet', style: TextStyle(color: AppColors.darkSubtext, fontSize: 12)),
                          ],
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.darkCardBorder),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < custOrders.length; i++) ...[
                              if (i > 0) const Divider(height: 1, color: AppColors.darkCardBorder),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            custOrders[i].orderNumber,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: AppColors.darkText,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            Formatters.formatDateTime(custOrders[i].createdAt),
                                            style: const TextStyle(color: AppColors.darkSubtext, fontSize: 10.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      Formatters.formatCurrency(custOrders[i].grandTotal, settings.currencySymbol),
                                      style: const TextStyle(color: AppColors.primaryLight, fontSize: 13, fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            if (!isArchived)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.darkCardBorder)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(LucideIcons.edit2, size: 16),
                    label: const Text('Edit customer', style: TextStyle(fontWeight: FontWeight.w800)),
                    onPressed: () {
                      Navigator.of(sheetCtx).pop();
                      _openEditCustomerModal(context, c);
                    },
                  ),
                ),
              )
            else
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _profileStat({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primary.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: highlight ? AppColors.primary.withValues(alpha: 0.4) : AppColors.darkCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: highlight ? AppColors.primaryLight : AppColors.darkSubtext),
              const SizedBox(width: 5),
              Text(label, style: const TextStyle(color: AppColors.darkSubtext, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: highlight ? AppColors.primaryLight : AppColors.darkText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {bool italic = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.darkSubtext),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.darkText,
                fontSize: 12.5,
                height: 1.35,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── list widgets ─────────────────────────

  Widget _statTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkCardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(color: AppColors.darkText, fontSize: 17, fontWeight: FontWeight.w800, height: 1.1),
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.darkSubtext, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String id, String label, int count) {
    final selected = _activeTab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.darkSubtext,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.darkSubtext,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
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
    final orderProv = context.watch<OrderProvider>();
    final settings = context.watch<SettingsProvider>().settings;

    final allCustomers = custProv.customers;
    final activeCount = allCustomers.where((c) => !c.isDeleted).length;
    final archivedCount = allCustomers.length - activeCount;

    // Per-customer order count and spend
    final Map<dynamic, int> orderCounts = {};
    final Map<dynamic, double> spend = {};
    double totalRevenue = 0;
    for (final o in orderProv.orders) {
      if (o.isDeleted || o.customerId == null) continue;
      orderCounts[o.customerId] = (orderCounts[o.customerId] ?? 0) + 1;
      spend[o.customerId] = (spend[o.customerId] ?? 0) + o.grandTotal;
      totalRevenue += o.grandTotal;
    }
    final repeatCount = orderCounts.values.where((n) => n > 1).length;

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
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final searching = _searchQuery.trim().isNotEmpty;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customers',
                style: TextStyle(color: AppColors.darkText, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 2),
              const Text('Your regulars and what they buy', style: TextStyle(color: AppColors.darkSubtext, fontSize: 12)),
              const SizedBox(height: 16),

              // Stats
              Row(
                children: [
                  _statTile(
                    label: 'Customers',
                    value: '$activeCount',
                    icon: LucideIcons.users,
                    color: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 10),
                  _statTile(
                    label: 'Repeat buyers',
                    value: '$repeatCount',
                    icon: LucideIcons.rotateCcw,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 10),
                  _statTile(
                    label: 'Revenue',
                    value: Formatters.formatCurrency(totalRevenue, settings.currencySymbol),
                    icon: LucideIcons.dollarSign,
                    color: AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkCardBorder),
                ),
                child: Row(
                  children: [
                    _tabButton('active', 'Active', activeCount),
                    const SizedBox(width: 4),
                    _tabButton('archived', 'Archived', archivedCount),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Search
              TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.darkText, fontSize: 13),
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: _fieldDecoration('Search', hint: 'Name, phone or email', icon: LucideIcons.search).copyWith(
                  labelText: null,
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(LucideIcons.x, size: 16, color: AppColors.darkSubtext),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // List
              Expanded(
                child: filtered.isEmpty
                    ? _emptyState(searching)
                    : GridView.builder(
                        padding: const EdgeInsets.only(bottom: 96),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 540,
                          mainAxisExtent: 96,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final c = filtered[i];
                          return _customerCardWithMenu(
                            c,
                            custProv,
                            orderCounts[c.id] ?? 0,
                            spend[c.id] ?? 0,
                            settings.currencySymbol,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        if (_activeTab == 'active')
  Positioned(
    right: 20,
    bottom: 20,
    child: FloatingActionButton.extended(
      heroTag: 'customers_add_customer',
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      onPressed: () => _openAddCustomerModal(context),
      icon: const Icon(
        LucideIcons.userPlus,
        size: 18,
      ),
      label: const Text(
        'Add customer',
        style: TextStyle(
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  ),
      ],
    );
  }

  /// Card + trailing three-dot menu (view / edit / archive / restore)
  Widget _customerCardWithMenu(
    Customer c,
    CustomerProvider custProv,
    int orderCount,
    double spent,
    String currency,
  ) {
    final isArchived = _activeTab == 'archived';

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(right: 0),
            child: _customerCardBody(c, orderCount, spent, currency, rightInset: 36),
          ),
        ),
Positioned(
  right: 0,
  top: 0,
  bottom: 0,
  child: PopupMenuButton<String>(
    padding: EdgeInsets.zero,
    color: AppColors.darkCard,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(
        color: AppColors.darkCardBorder,
      ),
    ),
    onSelected: (v) {
      switch (v) {
        case 'view':
          _showCustomerProfileModal(context, c);
          break;

        case 'edit':
          _openEditCustomerModal(context, c);
          break;

        case 'archive':
          _confirmArchive(c, custProv);
          break;

        case 'restore':
          _confirmRestore(c, custProv);
          break;
      }
    },
    itemBuilder: (_) => [
      _menuItem(
        'view',
        LucideIcons.eye,
        'View profile',
        AppColors.primaryLight,
      ),

      if (!isArchived) ...[
        _menuItem(
          'edit',
          LucideIcons.edit2,
          'Edit',
          AppColors.info,
        ),
        _menuItem(
          'archive',
          LucideIcons.archive,
          'Archive',
          AppColors.warning,
        ),
      ] else
        _menuItem(
          'restore',
          LucideIcons.rotateCcw,
          'Restore',
          AppColors.primaryLight,
        ),
    ],

    // Custom three-dot button
    child: const SizedBox(
      width: 36,
      height: 36,
      child: Center(
        child: _Dots(),
      ),
    ),
  ),
),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppColors.darkText, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _customerCardBody(Customer c, int orderCount, double spent, String currency, {double rightInset = 0}) {
    final isArchived = _activeTab == 'archived';
    final hasEmail = (c.email ?? '').isNotEmpty;

    return Material(
      color: AppColors.darkCard,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showCustomerProfileModal(context, c),
        child: Container(
          padding: EdgeInsets.fromLTRB(14, 12, rightInset + 4, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.darkCardBorder),
          ),
          child: Opacity(
            opacity: isArchived ? 0.8 : 1,
            child: Row(
              children: [
                _avatar(c.name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.darkText, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(LucideIcons.phone, size: 11, color: AppColors.darkSubtext),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              c.phone,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.darkSubtext, fontSize: 11.5, fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                      if (hasEmail) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(LucideIcons.mail, size: 11, color: AppColors.darkSubtext),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                c.email!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.darkSubtext, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.formatCurrency(spent, currency),
                      style: TextStyle(
                        color: spent > 0 ? AppColors.primaryLight : AppColors.darkSubtext,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        orderCount == 1 ? '1 order' : '$orderCount orders',
                        style: const TextStyle(color: AppColors.darkSubtext, fontSize: 10.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(bool searching) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                searching ? LucideIcons.search : LucideIcons.users,
                size: 32,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              searching ? 'No matching customers' : (_activeTab == 'active' ? 'No customers yet' : 'Nothing archived'),
              style: const TextStyle(color: AppColors.darkText, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              searching
                  ? 'Check the spelling or try a phone number.'
                  : (_activeTab == 'active' ? 'Add a customer to track their orders.' : 'Archived customers will show up here.'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.darkSubtext, fontSize: 12),
            ),
            if (!searching && _activeTab == 'active') ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _openAddCustomerModal(context),
                icon: const Icon(LucideIcons.userPlus, size: 16),
                label: const Text('Add customer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Three vertical dots drawn with plain widgets (no icon-name dependency).
class _Dots extends StatelessWidget {
  const _Dots();

  @override
  Widget build(BuildContext context) {
    Widget dot() => Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 1.5),
          decoration: const BoxDecoration(color: AppColors.darkSubtext, shape: BoxShape.circle),
        );
    return Column(mainAxisSize: MainAxisSize.min, children: [dot(), dot(), dot()]);
  }
}