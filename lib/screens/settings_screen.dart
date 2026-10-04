import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../models/business_settings.dart';
import '../providers/auth_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../providers/settings_provider.dart';
import '../services/storage_service.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/printer_config_modal.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstinController = TextEditingController();
  final _currencySymbolController = TextEditingController();
  final _currencyCodeController = TextEditingController();
  final _receiptFooterController = TextEditingController();
  final _lowStockController = TextEditingController();
  String _receiptWidth = '80mm';

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsProvider>().settings;
    _businessNameController.text = s.businessName;
    _phoneController.text = s.phone;
    _addressController.text = s.address;
    _emailController.text = s.email;
    _gstinController.text = s.gstin ?? '';
    _currencySymbolController.text = s.currencySymbol;
    _currencyCodeController.text = s.currencyCode;
    _receiptFooterController.text = s.receiptFooter;
    _lowStockController.text = s.lowStockThreshold.toString();
    _receiptWidth = s.receiptWidth;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    _currencySymbolController.dispose();
    _currencyCodeController.dispose();
    _receiptFooterController.dispose();
    _lowStockController.dispose();
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

  void _handleSaveSettings() {
    final settingsProv = context.read<SettingsProvider>();
    final newSettings = BusinessSettings(
      businessName: _businessNameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      email: _emailController.text.trim(),
      gstin: _gstinController.text.trim().isEmpty ? null : _gstinController.text.trim(),
      currencySymbol: _currencySymbolController.text.trim(),
      currencyCode: _currencyCodeController.text.trim(),
      receiptWidth: _receiptWidth,
      receiptFooter: _receiptFooterController.text,
      lowStockThreshold: int.tryParse(_lowStockController.text) ?? 15,
      defaultPaymentMethod: settingsProv.settings.defaultPaymentMethod,
    );

    settingsProv.updateSettings(newSettings);
    _showSnackBar('Store settings saved successfully!');
  }

  void _handleResetData() async {
    await StorageService.resetAllData();
    if (!mounted) return;

    context.read<SettingsProvider>().loadSettings();
    context.read<ProductProvider>().loadProducts();
    context.read<CustomerProvider>().loadCustomers();
    context.read<OrderProvider>().loadOrders();

    final s = context.read<SettingsProvider>().settings;
    setState(() {
      _businessNameController.text = s.businessName;
      _phoneController.text = s.phone;
      _addressController.text = s.address;
      _emailController.text = s.email;
      _gstinController.text = s.gstin ?? '';
      _currencySymbolController.text = s.currencySymbol;
      _currencyCodeController.text = s.currencyCode;
      _receiptFooterController.text = s.receiptFooter;
      _lowStockController.text = s.lowStockThreshold.toString();
      _receiptWidth = s.receiptWidth;
    });

    _showSnackBar('Database reset to initial AED sample catalog.');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkCardBorder),
                ),
                child: Row(
                  children: const [
                    Icon(LucideIcons.settings, color: AppColors.primaryLight, size: 24),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('System & Hardware Configuration', style: TextStyle(color: AppColors.darkText, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Store profile, Bluetooth printer layout, and database backups', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Store Profile Form Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkCardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Retail Store Profile', style: TextStyle(color: AppColors.darkText, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _businessNameController,
                      style: const TextStyle(color: AppColors.darkText, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Business / Store Name *'),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: AppColors.darkText, fontSize: 13),
                            decoration: const InputDecoration(labelText: 'Contact Phone *'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: AppColors.darkText, fontSize: 13),
                            decoration: const InputDecoration(labelText: 'Store Email'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _addressController,
                      style: const TextStyle(color: AppColors.darkText, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Store Address *'),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _gstinController,
                            style: const TextStyle(color: AppColors.darkText, fontSize: 13, fontFamily: 'monospace'),
                            decoration: const InputDecoration(labelText: 'GSTIN / Tax ID'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _lowStockController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(labelText: 'Low Stock Limit *'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Receipt & Hardware Config
              Container(
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
                        const Text('Receipt & Hardware Configuration', style: TextStyle(color: AppColors.darkText, fontSize: 14, fontWeight: FontWeight.bold)),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => const PrinterConfigModal(),
                            );
                          },
                          icon: const Icon(LucideIcons.bluetooth, size: 14),
                          label: const Text('Pair Printer Modal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _currencySymbolController,
                            style: const TextStyle(color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(labelText: 'Currency Symbol *'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _receiptWidth,
                            decoration: const InputDecoration(labelText: 'Receipt Roll Width *'),
                            items: const [
                              DropdownMenuItem(value: '58mm', child: Text('58 mm (2-inch pocket)')),
                              DropdownMenuItem(value: '80mm', child: Text('80 mm (3-inch counter)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _receiptWidth = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _receiptFooterController,
                      maxLines: 2,
                      style: const TextStyle(color: AppColors.darkText, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Receipt Footer Message'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Save Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _handleSaveSettings,
                  child: const Text('Save Store Settings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),

              // Database & Account Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkCardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Data Reset & Account', style: TextStyle(color: AppColors.darkText, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('Reset local database back to the initial sample AED tobacco catalog or sign out.', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11)),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => ConfirmDialog(
                                title: 'Reset All Data',
                                message: 'Reset all products, orders, and customers to default seed catalog?',
                                onConfirm: _handleResetData,
                              ),
                            );
                          },
                          icon: const Icon(LucideIcons.rotateCcw, size: 14),
                          label: const Text('Reset Sample Data'),
                        ),
                        const SizedBox(width: 12),

                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            auth.logout();
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          icon: const Icon(LucideIcons.logOut, size: 14),
                          label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
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
    );
  }
}
